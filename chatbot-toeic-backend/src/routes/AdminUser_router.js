import express from 'express';
import {   getAllUserController,
  updateUserRoleController,
  deleteUserController,
  lockUserController,
  updateUserController } from '../controllers/AdminUser_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * tags:
 *   - name: Admin (User)
 *     description: Quản lý người dùng dành cho Admin
 */

/**
 * @swagger
 * /api/adminUser/all:
 *   get:
 *     summary: Lấy danh sách toàn bộ người dùng
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về danh sách user
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/User'
 */
router.get('/all', authMiddleware, getAllUserController);

/**
 * @swagger
 * /api/adminUser/role:
 *   put:
 *     summary: Cập nhật vai trò (role) của người dùng
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: integer
 *               newRoleId:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/role', authMiddleware, updateUserRoleController);

/**
 * @swagger
 * /api/adminUser:
 *   delete:
 *     summary: Xoá người dùng
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Xoá thành công
 */
router.delete('/', authMiddleware, deleteUserController);

/**
 * @swagger
 * /api/adminUser/lock:
 *   put:
 *     summary: Khoá hoặc mở khoá tài khoản
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: integer
 *               newStatus:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/lock', authMiddleware, lockUserController);

/**
 * @swagger
 * /api/adminUser/update:
 *   put:
 *     summary: Chỉnh sửa thông tin người dùng tổng quát
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: integer
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *               role_id:
 *                 type: integer
 *               status:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/update', authMiddleware, updateUserController);

export default router;