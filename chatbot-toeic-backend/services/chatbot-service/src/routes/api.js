import express from 'express';
import chatbotV1Router from './chatbot_v1_router.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1', chatbotV1Router); // Handles /v1/users/me/conversations and /v1/conversations

export default router;