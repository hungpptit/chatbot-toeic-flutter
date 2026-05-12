// routes/auth_router.js
import express from 'express';
import { authMiddleware } from '../Middleware/authMiddleware.js';
import { sendSuccess, sendError } from '../utils/response.js';

const authRouter = express.Router();

/**
 * @swagger
 * /api/me:
 *   get:
 *     summary: Lấy thông tin người dùng hiện tại
 *     description: Trả về thông tin cơ bản của user đã đăng nhập (từ JWT token)
 *     tags:
 *       - Auth
 *     security:
 *       - BearerAuth: []
 *       - CookieAuth: []
 *     responses:
 *       200:
 *         $ref: '#/components/responses/SuccessResponse'
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
authRouter.get('/me', authMiddleware, (req, res) => {
  try {
    const user = req.user;
    
    const userData = {
      id: user.id || user.userId || null,
      name: user.name || 'Người dùng',
      email: user.email || '',
      avatar: user.avatar || '',
      role_id: user.role_id || null,
    };

    return sendSuccess(res, userData, 'Lấy thông tin người dùng thành công');
  } catch (err) {
    return sendError(res, 500, 'Lỗi server', [err.message]);
  }
});

/**
 * @swagger
 * /api/logout:
 *   post:
 *     summary: Đăng xuất
 *     description: Xóa token xác thực (cookies hoặc JWT)
 *     tags:
 *       - Auth
 *     responses:
 *       200:
 *         $ref: '#/components/responses/SuccessResponse'
 */
authRouter.post('/logout', (req, res) => {
  try {
    // Clear token cookie (backward compatibility)
    res.clearCookie('token', {
      path: '/',
      httpOnly: true,
      secure: false,
      sameSite: 'Lax',
    });

    return sendSuccess(res, null, 'Đã đăng xuất thành công');
  } catch (err) {
    return sendError(res, 500, 'Lỗi server', [err.message]);
  }
});

export default authRouter;
