import {
    createConversation,
    getConversationsByUser,
    getConversationById,
    deleteConversation,
    updateConversationTitle
} from '../services/conversation_service.js';
import {
    createMessage,
    getMessagesByConversation,
    getMessagesForGemini,
} from '../services/message_service.js';
import { getSmartItem } from '../services/question_service.js';
import { sendSuccess, sendError } from "../utils/response.js";

/**
 * GET /api/v1/users/me/conversations
 */
export const getMyConversations = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await getConversationsByUser(userId);
        return sendSuccess(res, result.data, "Fetched conversations successfully");
    } catch (error) {
        console.error("[CHATBOT V1] getMyConversations error:", error);
        return sendError(res, 500, "Error fetching conversations", [error.message]);
    }
};

/**
 * POST /api/v1/conversations
 */
export const startConversation = async (req, res) => {
    try {
        const userId = req.user.id;
        const { title } = req.body;
        const result = await createConversation({ userId, title });
        return sendSuccess(res, result.data, "Conversation created successfully", 201);
    } catch (error) {
        console.error("[CHATBOT V1] startConversation error:", error);
        return sendError(res, 500, "Error creating conversation", [error.message]);
    }
};

/**
 * GET /api/v1/conversations/:id
 */
export const getConversation = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const result = await getConversationById(id, userId);
        
        if (result.code !== 200) {
            return sendError(res, result.code, result.message);
        }
        
        return sendSuccess(res, result.data, "Fetched conversation successfully");
    } catch (error) {
        console.error("[CHATBOT V1] getConversation error:", error);
        return sendError(res, 500, "Error fetching conversation", [error.message]);
    }
};

/**
 * PATCH /api/v1/conversations/:id
 */
export const updateConversation = async (req, res) => {
    try {
        const { id } = req.params;
        const { title } = req.body;
        const userId = req.user.id;

        if (!title) return sendError(res, 400, "Title is required");

        const result = await updateConversationTitle(id, title, userId);
        return sendSuccess(res, result.data, "Conversation updated successfully");
    } catch (error) {
        console.error("[CHATBOT V1] updateConversation error:", error);
        return sendError(res, 500, "Error updating conversation", [error.message]);
    }
};

/**
 * DELETE /api/v1/conversations/:id
 */
export const removeConversation = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const result = await deleteConversation(id, userId);
        return sendSuccess(res, null, "Conversation deleted successfully");
    } catch (error) {
        console.error("[CHATBOT V1] removeConversation error:", error);
        return sendError(res, 500, "Error deleting conversation", [error.message]);
    }
};

/**
 * GET /api/v1/conversations/:conversationId/messages
 */
export const getMessages = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { format } = req.query;
        
        let result;
        if (format === 'gemini') {
            result = await getMessagesForGemini(conversationId);
        } else {
            result = await getMessagesByConversation(conversationId);
        }
        
        return sendSuccess(res, result.data, "Fetched messages successfully");
    } catch (error) {
        console.error("[CHATBOT V1] getMessages error:", error);
        return sendError(res, 500, "Error fetching messages", [error.message]);
    }
};

/**
 * POST /api/v1/conversations/:conversationId/messages
 */
export const createMessageV1 = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { role, content } = req.body;

        if (!role || !content) {
            return sendError(res, 400, "Role and content are required");
        }

        const result = await createMessage({ conversationId, role, content });
        return sendSuccess(res, result.data, "Message created successfully", 201);
    } catch (error) {
        console.error("[CHATBOT V1] createMessageV1 error:", error);
        return sendError(res, 500, "Error creating message", [error.message]);
    }
};

/**
 * POST /api/v1/conversations/:conversationId/ask
 */
export const askChatbot = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { rawText } = req.body;

        if (!rawText?.trim()) {
            return sendError(res, 400, "rawText is required");
        }

        const items = await getSmartItem(rawText, conversationId);
        
        const formattedResults = items.map((r) => {
            if (r.question) {
                return {
                    type: 'Question',
                    source: r.source,
                    question: r.question.question,
                    options: {
                        A: r.question.optionA,
                        B: r.question.optionB,
                        C: r.question.optionC,
                        D: r.question.optionD,
                    },
                    answer: r.question.correctAnswer,
                    explanation: r.question.explanation,
                };
            }
            if (r.vocab) {
                return {
                    type: 'Vocabulary-Lookup',
                    source: r.source,
                    word: r.vocab.word,
                    definition: r.vocab.definition,
                    example: r.vocab.example,
                    synonyms: r.vocab.synonyms?.map(s => s.synonym) || [],
                    antonyms: r.vocab.antonyms?.map(a => a.antonym) || [],
                    viExplanation: r.viExplanation || '',
                };
            }
            return {
                type: 'General-AI',
                source: r.source,
                answer: r.answer,
            };
        });

        return sendSuccess(res, {
            count: items.length,
            results: formattedResults
        }, "AI response generated");
    } catch (error) {
        console.error("[CHATBOT V1] askChatbot error:", error);
        return sendError(res, 500, "Error generating AI response", [error.message]);
    }
};
