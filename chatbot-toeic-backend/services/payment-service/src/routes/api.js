import express from 'express';
import paymentV1Router from './payment_v1_router.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1/payments', paymentV1Router);

export default router;