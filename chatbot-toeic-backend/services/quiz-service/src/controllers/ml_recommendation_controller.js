// ========================================
// FILE: src/controllers/ml_recommendation_controller.js
// MỤC ĐÍCH: API endpoint để gọi ML prediction với database caching
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
 * Get weak skills and question recommendations for a user
 * @route GET /api/ml/recommend/:userId
 * 
 * ✅ NEW STRATEGY: Database-first caching
 * 1. Check MLPredictions table first (instant)
 * 2. If missing/old → Run Python (async if possible)
 * 3. Save to MLPredictions for next time
 */
export const getRecommendations = async (req, res) => {
    try {
        const { userId } = req.params;

        if (!userId) {
            return res.status(400).json({
                code: 400,
                message: "userId is required"
            });
        }

        // ✅ 1. Check database first (instant read)
        let prediction = await db.MLPrediction.findOne({
            where: { userId }
        });

        let isStale = false;
        if (prediction) {
            // Check if prediction is empty
            const isEmpty = !prediction.weakSkills || prediction.weakSkills.length === 0 || !prediction.questionIds || prediction.questionIds.length === 0;
            
            // Check if cache is older than 24 hours
            const isTooOld = new Date() - new Date(prediction.updatedAt) > 24 * 60 * 60 * 1000;
            
            // Check if there are new attempts
            let hasNewAttempts = false;
            const latestAttempt = await db.UserTest.findOne({
                where: { userId },
                order: [['id', 'DESC']]
            });
            if (latestAttempt && new Date(latestAttempt.startedAt || latestAttempt.completedAt) > new Date(prediction.updatedAt)) {
                hasNewAttempts = true;
            }

            isStale = isEmpty || isTooOld || hasNewAttempts;
        }

        if (prediction && !isStale) {
            console.log(`✅ Returning cached ML result for user ${userId} (from database)`);
            return res.status(200).json({
                code: 200,
                message: "Recommendations retrieved successfully (from cache)",
                data: {
                    userId: prediction.userId,
                    weakSkills: prediction.weakSkills,
                    questionIds: prediction.questionIds,
                    confidence: prediction.confidence,
                    updatedAt: prediction.updatedAt
                }
            });
        }

        console.log(`🔄 No cached prediction or cache is stale for user ${userId}, trying Python HTTP microservice...`);

        const mlPort = process.env.ML_PORT || 5000;
        const mlUrl = `http://localhost:${mlPort}/predict/${userId}`;
        
        try {
            console.log(`📡 Sending request to ML service: ${mlUrl}`);
            const response = await axios.get(mlUrl, { timeout: 10000 }); // 10s timeout
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

            console.log(`✅ Saved ML prediction from HTTP microservice to database for user ${userId}`);

            return res.status(200).json({
                code: 200,
                message: "Recommendations retrieved successfully (from HTTP microservice)",
                data: {
                    userId: userId,
                    weakSkills: result.weak_skills || [],
                    questionIds: questionIds,
                    updatedAt: new Date()
                }
            });
        } catch (httpError) {
            console.warn(`⚠️ ML HTTP service failed or unavailable (${httpError.message}). Falling back to CLI spawn...`);

            const mlScriptPath = path.join(__dirname, '../../ml/predict_hybrid_unified.py');
            const pythonArgs = [mlScriptPath, userId.toString(), '--quiet', '--stdout'];

            const pythonProcess = spawn('python', pythonArgs, {
                stdio: ['ignore', 'pipe', 'pipe']
            });

            let stdoutString = '';
            let stderrString = '';
            pythonProcess.stdout.on('data', (data) => {
                stdoutString += data.toString();
            });
            pythonProcess.stderr.on('data', (data) => {
                stderrString += data.toString();
            });

            pythonProcess.on('close', async (code) => {
                if (code !== 0) {
                    console.error('Python script error:', stderrString);
                    return res.status(500).json({
                        code: 500,
                        message: "Failed to get recommendations",
                        error: stderrString
                    });
                }

                try {
                    const result = JSON.parse(stdoutString || '{}');

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

                    console.log(`✅ Saved ML prediction to database for user ${userId}`);

                    return res.status(200).json({
                        code: 200,
                        message: "Recommendations retrieved successfully",
                        data: {
                            userId: userId,
                            weakSkills: result.weak_skills || [],
                            questionIds: questionIds,
                            updatedAt: new Date()
                        }
                    });
                } catch (parseError) {
                    console.error('Failed to parse Python stdout:', parseError, stderrString);
                    return res.status(500).json({
                        code: 500,
                        message: "Failed to parse ML output",
                        error: parseError.message,
                        stderr: stderrString
                    });
                }
            });
        }

    } catch (error) {
        console.error('Error in getRecommendations:', error);
        return res.status(500).json({
            code: 500,
            message: "Server error",
            error: error.message
        });
    }
};

/**
 * Trigger model retraining
 * @route POST /api/ml/retrain
 */
export const retrainModels = async (req, res) => {
    try {
        if (process.env.SKIP_ML_SPAWN === 'true') {
            const axios = (await import('axios')).default;
            const mlServiceUrl = process.env.ML_SERVICE_URL || 'http://localhost:5000';
            console.log(`🌐 [Microservice Mode] Triggering remote model retraining at: ${mlServiceUrl}/retrain`);
            const response = await axios.post(`${mlServiceUrl}/retrain`);
            return res.status(200).json({
                code: 200,
                message: "Models retrained successfully",
                data: response.data
            });
        }

        const mlDir = path.join(__dirname, '../../ml');

        // Train global model
        const trainGlobal = spawn('python', [
            path.join(mlDir, 'train_model.py')
        ]);

        trainGlobal.on('close', (code1) => {
            if (code1 !== 0) {
                return res.status(500).json({
                    code: 500,
                    message: "Failed to train global model"
                });
            }

            // Train unified model
            const trainUnified = spawn('python', [
                path.join(mlDir, 'train_unified_model.py')
            ]);

            trainUnified.on('close', (code2) => {
                if (code2 !== 0) {
                    return res.status(500).json({
                        code: 500,
                        message: "Failed to train unified model"
                    });
                }

                return res.status(200).json({
                    code: 200,
                    message: "Models retrained successfully"
                });
            });
        });

    } catch (error) {
        console.error('Error in retrainModels:', error);
        return res.status(500).json({
            code: 500,
            message: "Server error",
            error: error.message
        });
    }
};
