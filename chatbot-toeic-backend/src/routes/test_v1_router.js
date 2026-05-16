import express from 'express';
import { 
    getTests,
    getTestQuestions,
    startTestAttempt,
    submitTestAttempt,
    submitPracticeAttempt,
    checkLatestAttempt,
    getAttemptResult,
    getTestHistory,
    updateQuestionV1,
    createQuestionV1,
    updateTestV1
} from '../controllers/test_v1_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/tests:
 *   get:
 *     summary: Lấy danh sách bài thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/responses/SuccessResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Test'
 */
router.get('/', authMiddleware, getTests);

/**
 * @swagger
 * /api/v1/tests/{testId}/questions:
 *   get:
 *     summary: Lấy danh sách câu hỏi của bài thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/:testId/questions', authMiddleware, getTestQuestions);

/**
 * @swagger
 * /api/v1/tests/{testId}/questions:
 *   post:
 *     summary: Thêm câu hỏi vào bài thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       201:
 *         description: Thành công
 */
router.post('/:testId/questions', authMiddleware, createQuestionV1);

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts:
 *   post:
 *     summary: Bắt đầu làm bài thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/:testId/attempts', authMiddleware, startTestAttempt);

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts/{attemptId}/submit:
 *   post:
 *     summary: Nộp bài thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *       - in: path
 *         name: attemptId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - answers
 *             properties:
 *               answers:
 *                 type: object
 *                 description: Map of questionId to answer letter (A/B/C/D)
 *                 example:
 *                   "123": "A"
 *                   "124": "B"
 *                   "125": "C"
 *               timeSpent:
 *                 type: integer
 *                 description: Time spent in seconds
 *                 example: 1200
 *     responses:
 *       200:
 *         description: Thành công
 *       400:
 *         description: Bad request - answers required
 *       401:
 *         description: Unauthorized
 */
router.post('/:testId/attempts/:attemptId/submit', authMiddleware, submitTestAttempt);

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts/latest/check:
 *   get:
 *     summary: Kiểm tra trạng thái làm bài gần nhất
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/:testId/attempts/latest/check', authMiddleware, checkLatestAttempt);

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts/history:
 *   get:
 *     summary: Lấy lịch sử làm bài của một test
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: testId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/:testId/attempts/history', authMiddleware, getTestHistory);

/**
 * @swagger
 * /api/v1/test-attempts/{attemptId}/result:
 *   get:
 *     summary: Lấy kết quả chi tiết của lần làm bài
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: attemptId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/test-attempts/:attemptId/result', authMiddleware, getAttemptResult);

/**
 * @swagger
 * /api/v1/practice-attempts/submit:
 *   post:
 *     summary: Nộp bài luyện tập
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/practice-attempts/submit', authMiddleware, submitPracticeAttempt);

/**
 * @swagger
 * /api/v1/questions/{id}:
 *   patch:
 *     summary: Cập nhật câu hỏi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.patch('/questions/:id', authMiddleware, updateQuestionV1);

/**
 * @swagger
 * /api/v1/tests/{id}:
 *   patch:
 *     summary: Cập nhật thông tin đề thi
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.patch('/:id', authMiddleware, updateTestV1);

export default router;
