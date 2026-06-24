import express from 'express';
import { authLimiter } from '../Middleware/rateLimiter.js';
import loginRouter from './login_signup_router.js';
import authV1Router from './auth_v1_router.js';
import adminUsersRouter from './admin-users_router.js';
import accountRouter from './account_router.js';
import internalRouter from './internal_router.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1/auth', authLimiter, authV1Router);
router.use('/v1/internal', internalRouter);

// === Legacy API (Backward Compatibility) ===
router.use('/auth', authLimiter, loginRouter);
router.use('/adminUser', adminUsersRouter);
router.use('/admin-users', adminUsersRouter); // RESTful Alias
router.use('/account', accountRouter);

export default router;