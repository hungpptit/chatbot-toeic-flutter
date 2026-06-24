import express from 'express';
import { authLimiter } from '../Middleware/rateLimiter.js';
import vocabulariesRouter from './vocabularies_router.js';
import loginRouter from './login_signup_router.js';
import authV1Router from './auth_v1_router.js';
import courseV1Router from './course_v1_router.js';
import testV1Router from './test_v1_router.js';
import chatbotV1Router from './chatbot_v1_router.js';
import statsV1Router from './stats_v1_router.js';
import uploadV1Router from './upload_v1_router.js';
import paymentV1Router from './payment_v1_router.js';

import adminUsersRouter from './admin-users_router.js';
import adminTestsRouter from  './admin-tests_router.js';
import adminMetadataRouter from './admin-metadata_router.js';
import accountRouter from './account_router.js';
import mlRouter from './ml_router.js';
// import userRouter from './user.route.js';
// import questionRouter from './question.route.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1/auth', authLimiter, authV1Router);
router.use('/v1/courses', courseV1Router);
router.use('/v1', testV1Router); // Handles /v1/tests and /v1/test-attempts
router.use('/v1/statistics', statsV1Router);
router.use('/v1/uploads', uploadV1Router);
router.use('/v1/payments', paymentV1Router);
router.use('/v1', chatbotV1Router); // Handles /v1/users/me/conversations and /v1/conversations

// === Legacy API (Backward Compatibility) ===
/**
 * @deprecated Legacy APIs - These will be removed once Web migration to v1 is complete.
 * Sunset Timeline: TBD (Expected Q3 2026)
 */
// Gắn các router con (Cả định dạng cũ và định dạng chuẩn RESTful mới để đảm bảo tương thích ngược)
router.use('/vocabulary', vocabulariesRouter);
router.use('/vocabularies', vocabulariesRouter); // RESTful Alias

router.use('/auth', authLimiter, loginRouter);

router.use('/adminUser', adminUsersRouter);
router.use('/admin-users', adminUsersRouter); // RESTful Alias

router.use('/adminTest', adminTestsRouter); 
router.use('/admin-tests', adminTestsRouter); // RESTful Alias

router.use('/adminMetadata', adminMetadataRouter);
router.use('/admin-metadata', adminMetadataRouter); // RESTful Alias

router.use('/account', accountRouter);
router.use('/ml', mlRouter); 

export default router;