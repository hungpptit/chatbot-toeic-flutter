import express from 'express';
import vocabularyRouter from './vocabulary_route.js';
import loginRouter from './login_signup_router.js';
import questionRouter from './question_route.js';
import conversationRouter from './conversation_router.js';
import messageRouter from './message_routes.js';
import authRouter from './auth_router.js';
import authV1Router from './auth_v1_router.js';
import courseV1Router from './course_v1_router.js';
import testV1Router from './test_v1_router.js';
import chatbotV1Router from './chatbot_v1_router.js';
import statsV1Router from './stats_v1_router.js';
import uploadV1Router from './upload_v1_router.js';

import coursesRouter from './course_router.js';
import testcourseRouter from './test_course_router.js';
import questiontestRouter from './question_test_router.js';
import AdminUserRouter from './AdminUser_router.js';
import AminTestRouter from  './AdminTest_router.js';
import accountRouter from './account_router.js';
import statisticalRouter from './statistical_router.js';
import uploadRouter from './upload.js';
import mlRouter from './ml_router.js';
// import userRouter from './user.route.js';
// import questionRouter from './question.route.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1/auth', authV1Router);
router.use('/v1/courses', courseV1Router);
router.use('/v1/tests', testV1Router);
router.use('/v1/statistics', statsV1Router);
router.use('/v1/uploads', uploadV1Router);
router.use('/v1', chatbotV1Router); // Handles /v1/users/me/conversations and /v1/conversations

// === Legacy API (Backward Compatibility) ===
/**
 * @deprecated Legacy APIs - These will be removed once Web migration to v1 is complete.
 * Sunset Timeline: TBD (Expected Q3 2026)
 */
// Gắn các router con
router.use('/vocabulary', vocabularyRouter);
// router.use('/user', userRouter);
router.use('/question', questionRouter);
router.use('/auth', loginRouter);
router.use('/conversations', conversationRouter);
router.use('/messages', messageRouter);
router.use('/', authRouter);
router.use('/courses', coursesRouter);
router.use('/testcourses', testcourseRouter);
router.use('/questionTest', questiontestRouter);
router.use('/adminUser', AdminUserRouter);
router.use('/adminTest', AminTestRouter); 
router.use('/account', accountRouter);
router.use('/statistical', statisticalRouter);
router.use('/', uploadRouter);
router.use('/ml', mlRouter); 

export default router;