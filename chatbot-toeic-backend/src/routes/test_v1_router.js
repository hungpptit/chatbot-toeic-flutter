import express from 'express';
import { 
    getTests,
    getTestQuestions,
    startTestAttempt,
    submitTestAttempt,
    submitPracticeAttempt,
    cancelTestAttempt,
    checkLatestAttempt,
    getAttemptResult,
    getTestHistory,
    updateQuestionV1,
    createQuestionV1,
    updateTestV1
} from '../controllers/test_v1_controller.js';
import { authMiddleware, adminMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/tests:
 *   get:
 *     summary: Lấy danh sách bài thi (Có phân trang)
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Số trang hiện tại
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Số lượng đề mỗi trang
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
 *                       type: object
 *                       properties:
 *                         tests:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/Test'
 *                         pagination:
 *                           type: object
 *                           properties:
 *                             totalItems:
 *                               type: integer
 *                             totalPages:
 *                               type: integer
 *                             currentPage:
 *                               type: integer
 *                             limit:
 *                               type: integer
 */
router.get('/tests', authMiddleware, getTests);

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
router.get('/tests/:testId/questions', authMiddleware, getTestQuestions);

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
router.post('/tests/:testId/questions', authMiddleware, adminMiddleware, createQuestionV1);

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
router.post('/tests/:testId/attempts', authMiddleware, startTestAttempt);

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts/{attemptId}:
 *   patch:
 *     summary: Cập nhật lượt làm bài (Nộp bài hoặc Hủy bài)
 *     description: Sử dụng API này để nộp bài (status=completed) hoặc hủy bài (status=cancelled)
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
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [cancelled, completed]
 *               answers:
 *                 type: object
 *                 description: Map of questionId to answer letter (A/B/C/D)
 *               timeSpent:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Thành công
 */
router.patch('/tests/:testId/attempts/:attemptId', authMiddleware, (req, res, next) => {
    const { status } = req.body;
    if (status === 'cancelled') {
        return cancelTestAttempt(req, res, next);
    } else if (status === 'completed') {
        return submitTestAttempt(req, res, next);
    }
    return res.status(400).json({ message: "Invalid status. Use 'cancelled' or 'completed'." });
});

/**
 * @swagger
 * /api/v1/tests/{testId}/attempts/latest:
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
router.get('/tests/:testId/attempts/latest', authMiddleware, checkLatestAttempt);

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
router.get('/tests/:testId/attempts/history', authMiddleware, getTestHistory);

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
 * /api/v1/practice-attempts:
 *   post:
 *     summary: Nộp bài luyện tập (Tạo lượt luyện tập)
 *     tags: [Test (v1)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [questionId, selectedAnswer]
 *             properties:
 *               questionId:
 *                 type: integer
 *               selectedAnswer:
 *                 type: string
 *                 enum: [A, B, C, D]
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/practice-attempts', authMiddleware, submitPracticeAttempt);

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
router.patch('/questions/:id', authMiddleware, adminMiddleware, updateQuestionV1);

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
router.patch('/tests/:id', authMiddleware, adminMiddleware, updateTestV1);

export default router;
