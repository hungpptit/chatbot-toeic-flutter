import express from 'express';
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
 *     summary: Thêm tin nhắn vào hội thoại
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
 *             required: [role, content]
 *             properties:
 *               role:
 *                 type: string
 *                 enum: [user, model]
 *               content:
 *                 type: string
 *     responses:
 *       201:
 *         description: Thành công
 */
router.post('/conversations/:conversationId/messages', authMiddleware, createMessageV1);

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
router.post('/conversations/:conversationId/ask', authMiddleware, askChatbot);

export default router;
