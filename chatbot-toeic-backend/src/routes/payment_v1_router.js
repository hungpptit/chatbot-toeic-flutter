import express from 'express';
import {
  getSubscriptionsController,
  getVipStatusController,
  createPaymentController,
  zalopayCallbackController
} from '../controllers/payment_v1_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/payments/subscriptions:
 *   get:
 *     summary: Lấy danh sách gói cước VIP
 *     tags: [Payment (v1)]
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/subscriptions', getSubscriptionsController);

/**
 * @swagger
 * /api/v1/payments/vip-status:
 *   get:
 *     summary: Kiểm tra trạng thái VIP hiện tại của tôi
 *     tags: [Payment (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.get('/vip-status', authMiddleware, getVipStatusController);

/**
 * @swagger
 * /api/v1/payments/create:
 *   post:
 *     summary: Khởi tạo giao dịch thanh toán
 *     tags: [Payment (v1)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [subscriptionId, paymentGateway]
 *             properties:
 *               subscriptionId:
 *                 type: integer
 *                 example: 1
 *               paymentGateway:
 *                 type: string
 *                 enum: [zalopay, momo, mock]
 *                 example: mock
 *               returnUrl:
 *                 type: string
 *                 example: http://localhost:8080/api/v1/payments/mock-success
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/create', authMiddleware, createPaymentController);

/**
 * @swagger
 * /api/v1/payments/zalopay-callback:
 *   post:
 *     summary: Webhook nhận kết quả thanh toán từ ZaloPay
 *     tags: [Payment (v1)]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [data, mac]
 *             properties:
 *               data:
 *                 type: string
 *               mac:
 *                 type: string
 *     responses:
 *       200:
 *         description: Trả về trạng thái xử lý cho ZaloPay
 */
router.post('/zalopay-callback', zalopayCallbackController);

export default router;
