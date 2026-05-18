/**
 * Auth Router v1
 * Chuẩn RESTful endpoints cho xác thực
 * Prefix: /api/v1/auth
 */

import express from 'express';
import {
  registerController,
  loginController,
  googleLoginController,
  refreshController,
  logoutController,
  getMeController,
} from '../controllers/auth_v1_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const authV1Router = express.Router();

/**
 * @swagger
 * tags:
 *   - name: Auth (v1)
 *     description: Authentication endpoints (v1 API)
 */

/**
 * @swagger
 * /api/v1/auth/register:
 *   post:
 *     summary: Đăng ký tài khoản mới
 *     description: Tạo một tài khoản người dùng mới với email và password
 *     tags:
 *       - Auth (v1)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 example: johndoe
 *               email:
 *                 type: string
 *                 format: email
 *                 example: john@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *     responses:
 *       201:
 *         description: Đăng ký thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                   example: User registered successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     username:
 *                       type: string
 *                     email:
 *                       type: string
 *       409:
 *         $ref: '#/components/responses/BadRequestError'
 *       500:
 *         $ref: '#/components/responses/BadRequestError'
 */
authV1Router.post('/register', registerController);

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Đăng nhập
 *     description: Đăng nhập với email và password, nhận access token + refresh token
 *     tags:
 *       - Auth (v1)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: john@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: Password@123
 *     responses:
 *       200:
 *         description: Đăng nhập thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                   example: Login successful
 *                 data:
 *                   type: object
 *                   properties:
 *                     accessToken:
 *                       type: string
 *                       description: JWT access token
 *                     refreshToken:
 *                       type: string
 *                       description: JWT refresh token
 *                     user:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                         username:
 *                           type: string
 *                         email:
 *                           type: string
 *                         role_id:
 *                           type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 *       500:
 *         $ref: '#/components/responses/BadRequestError'
 */
authV1Router.post('/login', loginController);

/**
 * @swagger
 * /api/v1/auth/google:
 *   post:
 *     summary: Đăng nhập hoặc đăng ký bằng Google
 *     tags:
 *       - Auth (v1)
 *     requestBody:
 *       required: true
 *     responses:
 *       200:
 *         description: Đăng nhập Google thành công
 */
authV1Router.post('/google', googleLoginController);

/**
 * @swagger
 * /api/v1/auth/refresh:
 *   post:
 *     summary: Làm mới access token
 *     description: Sử dụng refresh token để lấy access token mới
 *     tags:
 *       - Auth (v1)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: Refresh token nhận được từ login
 *                 example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
 *     responses:
 *       200:
 *         description: Token làm mới thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                   example: Token refreshed successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     accessToken:
 *                       type: string
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
authV1Router.post('/refresh', refreshController);

/**
 * @swagger
 * /api/v1/auth/logout:
 *   post:
 *     summary: Đăng xuất
 *     description: Đăng xuất và xóa refresh token
 *     tags:
 *       - Auth (v1)
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: Refresh token (optional)
 *     responses:
 *       200:
 *         description: Đăng xuất thành công
 */
authV1Router.post('/logout', logoutController);

/**
 * @swagger
 * /api/v1/auth/me:
 *   get:
 *     summary: Lấy thông tin người dùng hiện tại
 *     description: Trả về thông tin cơ bản của user đã đăng nhập
 *     tags:
 *       - Auth (v1)
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Lấy thông tin thành công
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: success
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     username:
 *                       type: string
 *                     email:
 *                       type: string
 *                     avatar:
 *                       type: string
 *                     role_id:
 *                       type: integer
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
authV1Router.get('/me', authMiddleware, getMeController);

export default authV1Router;
