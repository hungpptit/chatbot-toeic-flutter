import { 
    getAllTestsWithCourses 
} from "../services/test_course_service.js";
import { 
    RandomQuestionsByTestId,
    updateQuestion, 
    SubmitTestResult, 
    SubmitPracticeResult, 
    CheckUserHasDoneTestDetailed, 
    GetUserTestDetailById, 
    GetUserTestHistoryByTestId,
    StartUserTest,
    createQuestion 
} from '../services/question_test_service.js';
import { triggerMLPredictionAsync } from '../services/mlPredictionService.js';
import { sendSuccess, sendError } from "../utils/response.js";

/**
 * GET /api/v1/tests
 * Lấy danh sách tất cả bài thi
 */
export const getTests = async (req, res) => {
    try {
        const tests = await getAllTestsWithCourses();
        return sendSuccess(res, tests, "Fetched tests successfully");
    } catch (error) {
        console.error("[TEST V1] getTests error:", error);
        return sendError(res, 500, "Error fetching tests", [error.message]);
    }
};

/**
 * GET /api/v1/tests/:testId/questions
 * Lấy danh sách câu hỏi của một bài thi
 */
export const getTestQuestions = async (req, res) => {
    try {
        const { testId } = req.params;
        const questions = await RandomQuestionsByTestId(testId);
        return sendSuccess(res, questions, "Fetched questions successfully");
    } catch (error) {
        console.error("[TEST V1] getTestQuestions error:", error);
        return sendError(res, 500, "Error fetching questions", [error.message]);
    }
};

/**
 * POST /api/v1/tests/:testId/attempts
 * Bắt đầu làm bài thi
 */
export const startTestAttempt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { testId } = req.params;
        const result = await StartUserTest({ userId, testId });
        return sendSuccess(res, result, "Test attempt started");
    } catch (error) {
        console.error("[TEST V1] startTestAttempt error:", error);
        return sendError(res, 500, "Error starting test attempt", [error.message]);
    }
};

/**
 * POST /api/v1/tests/:testId/attempts/:attemptId/submit
 * Nộp bài thi
 * Note: attemptId currently mapped to logic that uses testId in service
 */
export const submitTestAttempt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { testId } = req.params; // attemptId could be used if service supported it
        const { answers } = req.body;

        if (!Array.isArray(answers) || answers.length === 0) {
            return sendError(res, 400, "Answers are required");
        }

        const result = await SubmitTestResult({ userId, testId, answers });

        // Background ML trigger
        triggerMLPredictionAsync(userId);

        return sendSuccess(res, result, "Test submitted successfully");
    } catch (error) {
        console.error("[TEST V1] submitTestAttempt error:", error);
        return sendError(res, 500, "Error submitting test", [error.message]);
    }
};

/**
 * POST /api/v1/practice-attempts/submit
 * Nộp bài luyện tập
 */
export const submitPracticeAttempt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { answers } = req.body;

        if (!Array.isArray(answers) || answers.length === 0) {
            return sendError(res, 400, "Answers are required");
        }

        const result = await SubmitPracticeResult({ userId, answers });

        // Background ML trigger
        triggerMLPredictionAsync(userId);

        return sendSuccess(res, result, "Practice submitted successfully");
    } catch (error) {
        console.error("[TEST V1] submitPracticeAttempt error:", error);
        return sendError(res, 500, "Error submitting practice", [error.message]);
    }
};

/**
 * GET /api/v1/tests/:testId/attempts/latest/check
 * Kiểm tra xem user đã làm bài này chưa
 */
export const checkLatestAttempt = async (req, res) => {
    try {
        const userId = req.user.id;
        const { testId } = req.params;
        const result = await CheckUserHasDoneTestDetailed({ userId, testId });
        return sendSuccess(res, result, "Checked latest attempt");
    } catch (error) {
        console.error("[TEST V1] checkLatestAttempt error:", error);
        return sendError(res, 500, "Error checking attempt", [error.message]);
    }
};

/**
 * GET /api/v1/test-attempts/:attemptId/result
 * Lấy kết quả chi tiết của một lần làm bài
 */
export const getAttemptResult = async (req, res) => {
    try {
        const { attemptId } = req.params;
        const result = await GetUserTestDetailById(attemptId);
        return sendSuccess(res, result, "Fetched attempt result successfully");
    } catch (error) {
        console.error("[TEST V1] getAttemptResult error:", error);
        return sendError(res, 500, "Error fetching attempt result", [error.message]);
    }
};

/**
 * GET /api/v1/tests/:testId/attempts/history
 * Lấy lịch sử làm bài của một test cụ thể
 */
export const getTestHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const { testId } = req.params;
        const result = await GetUserTestHistoryByTestId({ userId, testId });
        return sendSuccess(res, result, "Fetched test history successfully");
    } catch (error) {
        console.error("[TEST V1] getTestHistory error:", error);
        return sendError(res, 500, "Error fetching history", [error.message]);
    }
};

/**
 * PATCH /api/v1/questions/:id
 * Cập nhật câu hỏi
 */
export const updateQuestionV1 = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = req.body;
        const result = await updateQuestion(id, updatedData);
        return sendSuccess(res, result, "Question updated successfully");
    } catch (error) {
        console.error("[TEST V1] updateQuestionV1 error:", error);
        return sendError(res, 500, "Error updating question", [error.message]);
    }
};

/**
 * POST /api/v1/tests/:testId/questions
 * Thêm câu hỏi vào bài thi
 */
export const createQuestionV1 = async (req, res) => {
    try {
        const { testId } = req.params;
        const questionData = req.body;
        const newQuestion = await createQuestion(questionData, testId, questionData.sortOrder);
        return sendSuccess(res, newQuestion, "Question created successfully", 201);
    } catch (error) {
        console.error("[TEST V1] createQuestionV1 error:", error);
        return sendError(res, 500, "Error creating question", [error.message]);
    }
};
