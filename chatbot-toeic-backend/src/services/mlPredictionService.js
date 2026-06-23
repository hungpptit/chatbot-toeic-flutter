// ========================================
// FILE: src/services/mlPredictionService.js
// MỤC ĐÍCH: Auto-trigger ML prediction sau khi user submit test/practice
// ========================================

import { spawn } from 'child_process';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import os from 'os';
import axios from 'axios';
import db from '../models/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Trigger ML prediction cho user sau khi submit test/practice
 * Chạy background (không blocking response)
 * 
 * @param {number} userId - User ID
 * @returns {Promise<void>}
 */
export async function triggerMLPredictionAsync(userId) {
  // Chạy background, không await
  setImmediate(async () => {
    try {
      console.log(`🤖 [Background] Triggering ML prediction for user ${userId}...`);
      
      await runPythonPrediction(userId);
      
      console.log(`✅ [Background] ML prediction completed for user ${userId}`);
    } catch (error) {
      console.error(`❌ [Background] ML prediction failed for user ${userId}:`, error.message);
      // Không throw error, chỉ log
    }
  });
}

/**
 * Chạy Python prediction script và lưu kết quả vào database
 * 
 * @param {number} userId - User ID
 * @returns {Promise<object>} Prediction result
 */
async function runPythonPrediction(userId) {
  const mlPort = process.env.ML_PORT || 5000;
  const mlUrl = `http://localhost:${mlPort}/predict/${userId}`;
  
  try {
    console.log(`🤖 [Background HTTP] Triggering ML prediction for user ${userId} via ${mlUrl}`);
    const response = await axios.get(mlUrl, { timeout: 10000 });
    const result = response.data;
    
    if (result.error) {
      throw new Error(result.error);
    }
    
    const questionIds = [];
    const recommendations = result.recommendations || {};
    Object.values(recommendations).forEach(questions => {
      questions.forEach(q => {
        if (q.id && !questionIds.includes(q.id)) {
          questionIds.push(q.id);
        }
      });
    });

    const existingPrediction = await db.MLPrediction.findOne({ where: { userId } });
    const payload = {
      userId: userId,
      weakSkills: result.weak_skills || [],
      questionIds: questionIds,
      confidence: 0.8,
      totalAttempts: 0,
      overallAccuracy: null,
      updatedAt: db.sequelize.literal('GETDATE()')
    };

    if (existingPrediction) {
      await existingPrediction.update(payload);
    } else {
      await db.MLPrediction.create({
        ...payload,
        createdAt: db.sequelize.literal('GETDATE()')
      });
    }

    await db.MLPredictionHistory.create({
      userId: userId,
      weakSkills: result.weak_skills || [],
      questionIds: questionIds,
      confidence: 0.8
    });

    console.log(`✅ [Background HTTP] Saved ML prediction to database for user ${userId}`);
    return {
      userId,
      weakSkills: result.weak_skills || [],
      questionIds: questionIds,
      confidence: 0.8
    };
  } catch (httpError) {
    console.warn(`⚠️ [Background HTTP] ML HTTP service failed or unavailable (${httpError.message}). Falling back to CLI spawn...`);
    
    const mlScriptPath = path.join(__dirname, '../../ml/predict_hybrid_unified.py');
    const outFileName = `result_user_${userId}_${Date.now()}.json`;
    const outPath = path.join(os.tmpdir(), outFileName);

    const pythonArgs = [mlScriptPath, userId.toString(), '--quiet', '--out', outPath];
    
    return new Promise((resolve, reject) => {
      const pythonProcess = spawn('python', pythonArgs, {
        stdio: ['ignore', 'ignore', 'pipe']
      });

      let errorString = '';
      pythonProcess.stderr.on('data', (data) => {
        errorString += data.toString();
      });

      pythonProcess.on('close', async (code) => {
        if (code !== 0) {
          console.error('Python prediction error:', errorString);
          return reject(new Error(`Python script exited with code ${code}`));
        }

        try {
          const raw = await fs.readFile(outPath, { encoding: 'utf-8' });
          const result = JSON.parse(raw);

          const questionIds = [];
          const recommendations = result.recommendations || {};
          Object.values(recommendations).forEach(questions => {
            questions.forEach(q => {
              if (q.id && !questionIds.includes(q.id)) {
                questionIds.push(q.id);
              }
            });
          });

          const existingPrediction = await db.MLPrediction.findOne({ where: { userId } });
          const payload = {
            userId: userId,
            weakSkills: result.weak_skills || [],
            questionIds: questionIds,
            confidence: 0.8,
            totalAttempts: 0,
            overallAccuracy: null,
            updatedAt: db.sequelize.literal('GETDATE()')
          };

          if (existingPrediction) {
            await existingPrediction.update(payload);
          } else {
            await db.MLPrediction.create({
              ...payload,
              createdAt: db.sequelize.literal('GETDATE()')
            });
          }

          await db.MLPredictionHistory.create({
            userId: userId,
            weakSkills: result.weak_skills || [],
            questionIds: questionIds,
            confidence: 0.8
          });

          console.log(`✅ Saved ML prediction to database for user ${userId}`);

          try { 
            await fs.unlink(outPath); 
          } catch (e) {}

          resolve({
            userId,
            weakSkills: result.weak_skills || [],
            questionIds: questionIds,
            confidence: 0.8
          });
        } catch (parseError) {
          console.error('Failed to read/parse Python output:', parseError);
          reject(parseError);
        }
      });

      pythonProcess.on('error', (error) => {
        console.error('Failed to spawn Python process:', error);
        reject(error);
      });
    });
  }
}
