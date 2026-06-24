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
 * /api/admin-users:
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
router.get('/', authMiddleware, adminMiddleware, getAllUserController);
router.get('/all', authMiddleware, adminMiddleware, getAllUserController); // Legacy compatibility

/**
 * @swagger
 * /api/admin-users/{userId}:
 *   delete:
 *     summary: Xoá người dùng theo ID
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Xoá thành công
 */
router.delete('/:userId', authMiddleware, adminMiddleware, deleteUserController);
router.delete('/', authMiddleware, adminMiddleware, deleteUserController); // Legacy compatibility

/**
 * @swagger
 * /api/admin-users/{userId}:
 *   patch:
 *     summary: Cập nhật thông tin người dùng (hỗ trợ đổi thông tin, đổi quyền và khóa tài khoản)
 *     tags: [Admin (User)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *               role_id:
 *                 type: integer
 *                 description: ID vai trò mới (1 hoặc 2)
 *               status:
 *                 type: boolean
 *                 description: Trạng thái kích hoạt tài khoản
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.patch('/:userId', authMiddleware, adminMiddleware, (req, res, next) => {
  if (req.body.newRoleId !== undefined && req.body.role_id === undefined) {
    req.body.role_id = req.body.newRoleId;
  }
  if (req.body.newStatus !== undefined && req.body.status === undefined) {
    req.body.status = req.body.newStatus;
  }
  return updateUserController(req, res, next);
});

router.put('/role', authMiddleware, adminMiddleware, updateUserRoleController);
router.put('/lock', authMiddleware, adminMiddleware, lockUserController);
router.put('/update', authMiddleware, adminMiddleware, updateUserController);

export default router;