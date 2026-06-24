// ========================================
// FILE: src/services/ml_service.js
// MỤC ĐÍCH: Trigger ML prediction update (real-time)
// ========================================

import { spawn } from 'child_process';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import os from 'os';
import db from '../models/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Trigger ML prediction update for a user (async, non-blocking)
 * Called after user submits a test/practice
 * 
 * @param {number} userId - User ID to update prediction for
 * @returns {Promise<void>} - Fire and forget
 */
export const triggerMLUpdate = async (userId) => {
    try {
        console.log(`🔄 Triggering ML update for user ${userId}...`);

        const mlScriptPath = path.join(__dirname, '../../ml/predict_hybrid_unified.py');
        const outFileName = `result_user_${userId}_${Date.now()}.json`;
        const outPath = path.join(os.tmpdir(), outFileName);

        const pythonArgs = [mlScriptPath, userId.toString(), '--quiet', '--out', outPath];
        
        const pythonProcess = spawn('python', pythonArgs, {
            stdio: ['ignore', 'ignore', 'pipe'],
            detached: false // Keep as child process
        });

        let errorString = '';
        pythonProcess.stderr.on('data', (data) => {
            errorString += data.toString();
        });

        pythonProcess.on('close', async (code) => {
            if (code !== 0) {
                console.error(`❌ ML update failed for user ${userId}:`, errorString);
                return;
            }

            try {
                const raw = await fs.readFile(outPath, { encoding: 'utf-8' });
                const result = JSON.parse(raw);

                // Extract question IDs
                const questionIds = [];
                const recommendations = result.recommendations || {};
                Object.values(recommendations).forEach(questions => {
                    questions.forEach(q => {
                        if (q.id && !questionIds.includes(q.id)) {
                            questionIds.push(q.id);
                        }
                    });
                });

                // Get user stats for metadata
                const userStats = await db.sequelize.query(`
                    SELECT 
                        COUNT(*) AS totalAttempts,
                        CAST(SUM(CASE WHEN isCorrect = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS overallAccuracy
                    FROM UserResults
                    WHERE userId = ${userId}
                `, { type: db.sequelize.QueryTypes.SELECT });

                const stats = userStats[0] || { totalAttempts: 0, overallAccuracy: 0 };

                // Upsert-like flow without Sequelize MSSQL upsert (avoids date conversion issues)
                const payload = {
                    userId: userId,
                    weakSkills: result.weak_skills || [],
                    questionIds: questionIds,
                    confidence: 0.8, // TODO: Calculate from model probabilities
                    totalAttempts: parseInt(stats.totalAttempts) || 0,
                    overallAccuracy: parseFloat(stats.overallAccuracy) || null,
                    updatedAt: db.sequelize.literal('GETDATE()')
                };

                const existingPrediction = await db.MLPrediction.findOne({
                    where: { userId }
                });

                if (existingPrediction) {
                    await existingPrediction.update(payload);
                } else {
                    await db.MLPrediction.create({
                        ...payload,
                        createdAt: db.sequelize.literal('GETDATE()')
                    });
                }

                console.log(`✅ ML prediction updated for user ${userId}`);

                // Clean up temp file
                try { await fs.unlink(outPath); } catch (e) { /* ignore */ }

            } catch (parseError) {
                console.error(`❌ Failed to parse ML output for user ${userId}:`, parseError);
            }
        });

    } catch (error) {
        console.error(`❌ Error triggering ML update for user ${userId}:`, error);
    }
};

/**
 * Check if user needs ML update
 * Returns true if:
 * - No prediction exists
 * - User has answered new questions since last prediction
 * 
 * @param {number} userId 
 * @returns {Promise<boolean>}
 */
export const needsMLUpdate = async (userId) => {
    try {
        const prediction = await db.MLPrediction.findOne({
            where: { userId },
            attributes: ['updatedAt', 'totalAttempts']
        });

        if (!prediction) {
            return true; // No prediction exists
        }

        // Prefer comparing counts (robust to timezone/precision issues):
        // If prediction.totalAttempts is available, compare current totalAttempts - previousTotal >= threshold
        const totalRow = await db.sequelize.query(`
            SELECT COUNT(*) AS totalAttempts FROM UserResults WHERE userId = ${userId}
        `, { type: db.sequelize.QueryTypes.SELECT });

        const currentTotal = parseInt(totalRow[0]?.totalAttempts || 0, 10);
        const prevTotal = parseInt(prediction.totalAttempts || 0, 10);

        const newAttempts = currentTotal - prevTotal;

        // If prevTotal is 0 (missing/stale), but currentTotal already exceeds threshold,
        // we should update (covers cases where prediction.totalAttempts wasn't populated).
        const threshold = 5;
        if (prevTotal === 0) {
            if (currentTotal >= threshold) {
                return true;
            }

            // If currentTotal is still small, fall back to timestamp-based check for safety
            try {
                const recentAttempts = await db.sequelize.query(`
                    SELECT COUNT(*) AS newAttempts
                    FROM UserResults
                    WHERE userId = ${userId}
                    AND answeredAt > '${prediction.updatedAt.toISOString()}'
                `, { type: db.sequelize.QueryTypes.SELECT });
                const recent = recentAttempts[0]?.newAttempts || 0;
                return recent >= threshold;
            } catch (e) {
                console.error('Fallback timestamp check failed:', e);
                return false;
            }
        }

        // Update if user answered at least `threshold` new questions since last recorded total
        return newAttempts >= threshold;

    } catch (error) {
        console.error('Error checking ML update need:', error);
        return false;
    }
};
