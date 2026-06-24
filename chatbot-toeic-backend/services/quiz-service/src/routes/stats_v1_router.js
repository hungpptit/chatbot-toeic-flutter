import express from 'express';
import {
    getUserStats,
    getPartStats,
    getAccuracyStats,
    getHistoryStats
} from '../controllers/stats_v1_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/statistics/user-tests:
 *   get:
 *     summary: Thống kê tổng quan bài thi của user
 *     tags: [Statistics (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/user-tests', authMiddleware, getUserStats);

/**
 * @swagger
 * /api/v1/statistics/parts:
 *   get:
 *     summary: Thống kê theo từng Part TOEIC
 *     tags: [Statistics (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/parts', authMiddleware, getPartStats);

/**
 * @swagger
 * /api/v1/statistics/accuracy-over-time:
 *   get:
 *     summary: Thống kê độ chính xác theo thời gian
 *     tags: [Statistics (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/accuracy-over-time', authMiddleware, getAccuracyStats);

/**
 * @swagger
 * /api/v1/statistics/user-test-history:
 *   get:
 *     summary: Lịch sử làm bài thi chi tiết
 *     tags: [Statistics (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/user-test-history', authMiddleware, getHistoryStats);

export default router;
