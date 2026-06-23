import express from 'express';
import {   getAllUserController,
  updateUserRoleController,
  deleteUserController,
  lockUserController,
  updateUserController } from '../controllers/AdminUser_controller.js';
import { authMiddleware, adminMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * tags:
 *   - name: Admin (User)
 *     description: Quản lý người dùng dành cho Admin
 */

/**
 * @swagger
 * /api/admin-users/all:
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
router.get('/all', authMiddleware, adminMiddleware, getAllUserController);

/**
 * @swagger
 * /api/admin-users/role:
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
router.put('/role', authMiddleware, adminMiddleware, updateUserRoleController);

/**
 * @swagger
 * /api/admin-users:
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
router.delete('/', authMiddleware, adminMiddleware, deleteUserController);

/**
 * @swagger
 * /api/admin-users/lock:
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
router.put('/lock', authMiddleware, adminMiddleware, lockUserController);

/**
 * @swagger
 * /api/admin-users/update:
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
router.put('/update', authMiddleware, adminMiddleware, updateUserController);

export default router;