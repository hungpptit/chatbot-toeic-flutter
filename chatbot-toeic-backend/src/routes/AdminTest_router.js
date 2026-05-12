import express from 'express';
import {
  getTestList,
  getQuestionTypes,
  getParts,
  createPartController,
  deletePartController,
  createQuestionTypeController,
  deleteQuestionTypeController,
  createNewTestController,
  updatePartNameController,
  updateQuestionTypeController,
  deleteTestByIdController,
  generateMissingEmbeddingsController,
  getSkillsController,
  getSkillByIdController,
  createSkillController,
  updateSkillController,
  deleteSkillController,
} from '../controllers/AdminTest_controller.js';

import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

// Lấy tất cả bài test kèm thông tin khóa học
router.get('/', authMiddleware, getTestList);

// Lấy danh sách question types và parts
router.get('/question-types', authMiddleware, getQuestionTypes);
router.get('/parts', authMiddleware, getParts);
// Cập nhật tên Part và Question Type
router.put('/parts/update', authMiddleware, updatePartNameController);
router.put('/question-types/update', authMiddleware, updateQuestionTypeController);

// Tạo / Xóa Part
router.post('/parts', authMiddleware, createPartController);
router.delete('/parts/:id', authMiddleware, deletePartController);

// Tạo / Xóa QuestionType
router.post('/question-types', authMiddleware, createQuestionTypeController);
router.delete('/question-types/:id', authMiddleware, deleteQuestionTypeController);
/**
 * @swagger
 * /api/adminTest/createTestNew:
 *   post:
 *     summary: Tạo bài thi mới (Hỗ trợ định dạng Flat và Mixed)
 *     description: |
 *       API hợp nhất cho phép tạo bài thi theo 2 cách:
 *       1. **Flat:** Gửi một mảng `questions` duy nhất.
 *       2. **Mixed:** Gửi 2 mảng `listeningQuestions` và `readingQuestions` riêng biệt.
 *       
 *       **Tính năng tự động:**
 *       - Nếu gửi `imagePath` hoặc `audioPath` (local path trên server), server sẽ tự động upload lên Cloudinary.
 *       - Nếu gửi định dạng Mixed, server tự động gán `skillId` (1 cho Listening, 2 cho Reading).
 *       - Tự động tạo AI Embeddings cho tất cả câu hỏi.
 *     tags: [Admin Test]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - courseId
 *             properties:
 *               title:
 *                 type: string
 *                 example: "TOEIC Practice Test #10"
 *               courseId:
 *                 type: integer
 *                 example: 1
 *               duration:
 *                 type: string
 *                 example: "120 minutes"
 *               questions:
 *                 type: array
 *                 description: Mảng câu hỏi (định dạng phẳng)
 *                 items:
 *                   $ref: '#/components/schemas/AdminQuestionInput'
 *               listeningQuestions:
 *                 type: array
 *                 description: Mảng câu hỏi phần Nghe (định dạng Mixed)
 *                 items:
 *                   $ref: '#/components/schemas/AdminQuestionInput'
 *               readingQuestions:
 *                 type: array
 *                 description: Mảng câu hỏi phần Đọc (định dạng Mixed)
 *                 items:
 *                   $ref: '#/components/schemas/AdminQuestionInput'
 *     responses:
 *       201:
 *         description: Bài thi đã được tạo và lưu thành công
 *       400:
 *         description: Dữ liệu không hợp lệ
 */
router.post('/createTestNew', authMiddleware, createNewTestController);
// Xóa bài test theo ID
router.delete('/deleteTest/:testId', authMiddleware, deleteTestByIdController);


router.post('/tests/generate-missing-embeddings', generateMissingEmbeddingsController);
// Skill routes
router.get('/skills', authMiddleware, getSkillsController);// Lấy tất cả skill
router.get('/skills/:id', authMiddleware, getSkillByIdController);// Lấy skill theo ID
router.post('/skills', authMiddleware, createSkillController);// Tạo skill mới
router.put('/skills/:id', authMiddleware, updateSkillController);// Cập nhật skill
router.delete('/skills/:id', authMiddleware, deleteSkillController);// Xóa skill
export default router;
