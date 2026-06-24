// ========================================
// FILE: src/services/mlPredictionService.js
// MỤC ĐÍCH: Auto-trigger ML prediction sau khi user submit test/practice (Chỉ gọi HTTP REST)
// ========================================

import axios from 'axios';
import db from '../models/index.js';

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
 * Gọi API HTTP tới Python ML service và lưu kết quả vào database
 * 
 * @param {number} userId - User ID
 * @returns {Promise<object>} Prediction result
 */
async function runPythonPrediction(userId) {
  // Đọc cấu hình URL dịch vụ ML từ env (dùng cho Docker hoặc local dev)
  const mlServiceUrl = process.env.ML_SERVICE_URL || `http://localhost:${process.env.ML_PORT || 5000}`;
  const mlUrl = `${mlServiceUrl}/predict/${userId}`;
  
  console.log(`🤖 [HTTP Request] Calling ML service for user ${userId} via ${mlUrl}`);
  
  const response = await axios.get(mlUrl, { timeout: 15000 });
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

  console.log(`✅ [HTTP Success] Saved ML prediction to database for user ${userId}`);
  return {
    userId,
    weakSkills: result.weak_skills || [],
    questionIds: questionIds,
    confidence: 0.8
  };
}
