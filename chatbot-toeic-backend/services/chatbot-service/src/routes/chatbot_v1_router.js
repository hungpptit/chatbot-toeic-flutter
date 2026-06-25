import express from 'express';
import db from '../models/index.js';
import {
    getMyConversations,
    startConversation,
    getConversation,
    updateConversation,
    removeConversation,
    getMessages,
    createMessageV1,
    askChatbot
} from '../controllers/chatbot_v1_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';
import { vipCheckMiddleware } from '../Middleware/vipCheckMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/users/me/conversations:
 *   get:
 *     summary: Lấy danh sách hội thoại của tôi
 *     tags: [Chatbot (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/users/me/conversations', authMiddleware, getMyConversations);

/**
 * @swagger
 * /api/v1/conversations:
 *   post:
 *     summary: Tạo hội thoại mới
 *     tags: [Chatbot (v1)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *     responses:
 *       201:
 *         description: Thành công
 */
router.post('/conversations', authMiddleware, startConversation);

/**
 * @swagger
 * /api/v1/conversations/{id}:
 *   get:
 *     summary: Lấy chi tiết hội thoại
 *     tags: [Chatbot (v1)]
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
router.get('/conversations/:id', authMiddleware, getConversation);
router.patch('/conversations/:id', authMiddleware, updateConversation);
router.delete('/conversations/:id', authMiddleware, removeConversation);

/**
 * @swagger
 * /api/v1/conversations/{conversationId}/messages:
 *   get:
 *     summary: Lấy danh sách tin nhắn trong hội thoại
 *     tags: [Chatbot (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         required: true
 *         schema:
 *           type: integer
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [gemini]
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/conversations/:conversationId/messages', authMiddleware, getMessages);

/**
 * @swagger
 * /api/v1/conversations/{conversationId}/messages:
 *   post:
 *     summary: Gửi tin nhắn vào cuộc hội thoại (Hỗ trợ cả tin nhắn thường và Hỏi AI)
 *     description: |
 *       API này hỗ trợ 2 chế độ dựa trên dữ liệu gửi lên:
 *       1. **Hỏi AI (Chatbot):** Gửi `rawText` để chatbot phân tích và trả về câu trả lời.
 *       2. **Lưu tin nhắn thủ công:** Gửi `role` và `content`.
 *     tags: [Chatbot (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               rawText:
 *                 type: string
 *                 description: Nội dung câu hỏi gửi tới AI (Nếu gửi trường này, hệ thống sẽ kích hoạt chatbot)
 *               role:
 *                 type: string
 *                 enum: [user, model]
 *               content:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thành công
 *       201:
 *         description: Đã tạo tin nhắn mới thành công
 */
router.post('/conversations/:conversationId/messages', authMiddleware, (req, res, next) => {
    if (req.body.rawText) {
        return vipCheckMiddleware(req, res, () => askChatbot(req, res, next));
    }
    return createMessageV1(req, res, next);
});

/**
 * @swagger
 * /api/v1/conversations/{conversationId}/ask:
 *   post:
 *     summary: Hỏi chatbot AI
 *     tags: [Chatbot (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [rawText]
 *             properties:
 *               rawText:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/conversations/:conversationId/ask', authMiddleware, vipCheckMiddleware, askChatbot);

router.get('/internal/messages/count', async (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) {
            return res.status(400).json({ code: 400, message: "userId parameter is required" });
        }
        
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const todayEnd = new Date();
        todayEnd.setHours(23, 59, 59, 999);

        const messageCount = await db.Message.count({
            include: [{
                model: db.Conversation,
                as: 'conversation',
                where: { userId: parseInt(userId) }
            }],
            where: {
                role: 'user',
                createdAt: {
                    [db.Sequelize.Op.between]: [todayStart, todayEnd]
                }
            }
        });

        return res.status(200).json({
            code: 200,
            message: "Counted messages successfully",
            data: { count: messageCount }
        });
    } catch (error) {
        console.error("[CHATBOT INTERNAL] count error:", error);
        return res.status(500).json({ code: 500, message: "Internal server error", details: [error.message] });
    }
});

export default router;

