import os
import sys
# Configure UTF-8 encoding for standard input/output/error streams
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')

import pyodbc
import pandas as pd
import joblib
import json
from flask import Flask, jsonify, request
from sklearn.naive_bayes import GaussianNB
from dotenv import load_dotenv

app = Flask(__name__)

# Rule-based fallback: nếu accuracy skill thấp hơn ngưỡng này thì coi là weak
WEAK_SKILL_ACCURACY_THRESHOLD = 0.50

# Load .env từ parent directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(dotenv_path=os.path.join(BASE_DIR, ".env"))

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={DB_HOST},{DB_PORT};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USERNAME};"
    f"PWD={DB_PASS}"
)

# Load models at startup (exactly once)
model_dir = os.path.join(os.path.dirname(__file__), 'model')
global_model_path = os.path.join(model_dir, "weak_skill_model.pkl")
unified_model_path = os.path.join(model_dir, "unified_model.pkl")

global_model = None
unified_model = None

def load_models():
    global global_model, unified_model
    try:
        if os.path.exists(global_model_path):
            global_model = joblib.load(global_model_path)
            print("[INFO] Loaded global model successfully.")
        else:
            print("[WARN] Global model not found. Run train_model.py first.")

        if os.path.exists(unified_model_path):
            unified_model = joblib.load(unified_model_path)
            print("[INFO] Loaded unified model successfully.")
        else:
            print("[WARN] Unified model not found. It will be trained on demand or run train_unified_model.py.")
    except Exception as e:
        print(f"[ERROR] Error loading models: {e}")

# Call load_models at startup
load_models()

def prepare_unified_features(userId: int, skillId: int, attempts: int, correct: int, accuracy: float, conn):
    query = f"""
    WITH CompletedResults AS (
        SELECT ur.userTestId, ur.isCorrect, ur.answeredAt
        FROM UserResults ur
        INNER JOIN UserTests ut ON ur.userTestId = ut.id
        WHERE ur.userId = {userId}
          AND ut.status = 'completed'
    )
    SELECT 
        COUNT(DISTINCT userTestId) AS total_tests,
        COUNT(*) AS total_questions,
        CAST(SUM(CASE WHEN isCorrect = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS overall_accuracy,
        DATEDIFF(DAY, MIN(answeredAt), GETDATE()) AS days_active
    FROM CompletedResults
    """
    user_stats = pd.read_sql(query, conn).iloc[0]
    
    userId_hash = hash(userId) % 10000
    user_level = 0 if user_stats['overall_accuracy'] < 0.5 else (
        1 if user_stats['overall_accuracy'] < 0.7 else 2
    )
    
    X = pd.DataFrame([[
        userId_hash,
        user_level,
        int(user_stats['total_tests']),
        int(user_stats['total_questions']),
        float(user_stats['overall_accuracy']),
        int(user_stats['days_active']),
        attempts,
        correct,
        accuracy
    ]], columns=[
        'userId_hash', 'user_level', 'total_tests', 'total_questions',
        'overall_accuracy', 'days_active', 'attempts', 'correct', 'skill_accuracy'
    ])
    
    return X

def predict_user_skills(userId: int):
    global global_model, unified_model
    # Reload models dynamically if they were not loaded originally
    if global_model is None or unified_model is None:
        load_models()
        
    conn = pyodbc.connect(conn_str)
    
    query = f"""
    WITH CompletedResults AS (
        SELECT ur.userId, ur.questionId, ur.isCorrect
        FROM UserResults ur
        INNER JOIN UserTests ut ON ur.userTestId = ut.id
        WHERE ur.userId = {userId}
          AND ut.status = 'completed'
    )
    SELECT 
        qs.skillId,
        s.name AS skillName,
        COUNT(*) AS attempts,
        SUM(CASE WHEN cr.isCorrect = 1 THEN 1 ELSE 0 END) AS correct
    FROM CompletedResults cr
    JOIN QuestionSkills qs ON cr.questionId = qs.questionId
    JOIN Skills s ON qs.skillId = s.id
    GROUP BY qs.skillId, s.name
    """
    df = pd.read_sql(query, conn)

    if df.empty:
        conn.close()
        return {}

    results = {}
    for _, row in df.iterrows():
        skillName = row['skillName']
        skillId = row['skillId']
        attempts = row['attempts']
        correct = row['correct']
        accuracy = correct / attempts if attempts > 0 else 0
        rule_based_weak = accuracy < WEAK_SKILL_ACCURACY_THRESHOLD

        if attempts < 10:
            if global_model is not None:
                X_global = pd.DataFrame([[attempts, correct, accuracy]],
                                       columns=['attempts', 'correct', 'accuracy'])
                y_pred = global_model.predict(X_global)[0]
                final_is_weak = (y_pred == 1) or rule_based_weak
            else:
                final_is_weak = rule_based_weak
            results[skillName] = "Weak" if final_is_weak else "Strong"
        else:
            if unified_model is not None:
                X_unified = prepare_unified_features(userId, skillId, attempts, correct, accuracy, conn)
                y_pred = unified_model.predict(X_unified)[0]
                final_is_weak = (y_pred == 1) or rule_based_weak
            else:
                final_is_weak = rule_based_weak
            results[skillName] = "Weak" if final_is_weak else "Strong"
            
    conn.close()
    return results

@app.route('/predict/<int:user_id>', methods=['GET'])
def predict(user_id):
    try:
        # Step 1: Predict weak skills
        results = predict_user_skills(user_id)
        weak_skills = [skill for skill, status in results.items() if status == "Weak"]

        if not weak_skills:
            return jsonify({
                "weak_skills": [],
                "recommendations": {}
            })

        # Step 2: Recommend questions for each weak skill
        conn = pyodbc.connect(conn_str)
        recommendations = {}
        
        for skill in weak_skills:
            query = f"""
            SELECT TOP 50 q.id, q.question
            FROM Questions q
            JOIN QuestionSkills qs ON q.id = qs.questionId
            JOIN Skills s ON qs.skillId = s.id
            WHERE s.name = '{skill}'
            ORDER BY NEWID()
            """
            questions_df = pd.read_sql(query, conn)
            
            if questions_df.empty:
                continue
            
            all_suggestions = {}
            seen_content = set()
            for _, q in questions_df.iterrows():
                content_normalized = q['question'].strip() if q.get('question') else ''
                if content_normalized and content_normalized not in seen_content:
                    all_suggestions[q['id']] = {
                        "id": int(q['id']),
                        "question": q['question']
                    }
                    seen_content.add(content_normalized)
                if len(all_suggestions) >= 30:
                    break
            
            recommendations[skill] = list(all_suggestions.values())
        
        conn.close()
        
        return jsonify({
            "weak_skills": weak_skills,
            "recommendations": recommendations
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/reload-models', methods=['POST'])
def reload_models():
    load_models()
    return jsonify({"message": "Models reloaded successfully"})

if __name__ == '__main__':
    port = int(os.getenv("ML_PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
