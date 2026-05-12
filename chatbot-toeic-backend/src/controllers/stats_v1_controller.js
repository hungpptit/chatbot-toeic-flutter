import {
    getUserTestStats,
    getPartStatisticsByUser,
    getAccuracyOverTime,
    getUserTestHistory
} from "../services/statistical_service.js";
import { sendSuccess, sendError } from "../utils/response.js";

/**
 * GET /api/v1/statistics/user-tests
 */
export const getUserStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const stats = await getUserTestStats(userId);
        return sendSuccess(res, stats, "Fetched user test statistics successfully");
    } catch (error) {
        console.error("[STATS V1] getUserStats error:", error);
        return sendError(res, 500, "Error fetching statistics", [error.message]);
    }
};

/**
 * GET /api/v1/statistics/parts
 */
export const getPartStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const stats = await getPartStatisticsByUser(userId);
        return sendSuccess(res, stats, "Fetched part statistics successfully");
    } catch (error) {
        console.error("[STATS V1] getPartStats error:", error);
        return sendError(res, 500, "Error fetching part statistics", [error.message]);
    }
};

/**
 * GET /api/v1/statistics/accuracy-over-time
 */
export const getAccuracyStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const days = parseInt(req.query.days) || 30;
        const data = await getAccuracyOverTime(userId, days);
        return sendSuccess(res, data, "Fetched accuracy stats successfully");
    } catch (error) {
        console.error("[STATS V1] getAccuracyStats error:", error);
        return sendError(res, 500, "Error fetching accuracy stats", [error.message]);
    }
};

/**
 * GET /api/v1/statistics/user-test-history
 */
export const getHistoryStats = async (req, res) => {
    try {
        const userId = req.user.id;
        const history = await getUserTestHistory(userId);
        return sendSuccess(res, history, "Fetched test history successfully");
    } catch (error) {
        console.error("[STATS V1] getHistoryStats error:", error);
        return sendError(res, 500, "Error fetching history statistics", [error.message]);
    }
};
