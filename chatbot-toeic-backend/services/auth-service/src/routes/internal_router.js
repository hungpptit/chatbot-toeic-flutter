import express from 'express';
import db from '../models/index.js';
import { sendSuccess, sendError } from '../utils/response.js';

const router = express.Router();

// GET /api/v1/internal/users/:id
router.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const user = await db.User.findByPk(id);
    if (!user) {
      return sendError(res, 404, 'Không tìm thấy người dùng', ['Người dùng không tồn tại.']);
    }
    return sendSuccess(res, {
      id: user.id,
      username: user.username,
      email: user.email,
      role_id: user.role_id,
      isVip: user.isVip,
      vipExpireAt: user.vipExpireAt
    }, 'Lấy thông tin người dùng thành công');
  } catch (error) {
    console.error('[INTERNAL USER GET ERROR]', error);
    return sendError(res, 500, 'Lỗi hệ thống', [error.message]);
  }
});

// PATCH /api/v1/internal/users/:id
router.patch('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { isVip, vipExpireAt } = req.body;

    const user = await db.User.findByPk(id);
    if (!user) {
      return sendError(res, 404, 'Không tìm thấy người dùng', ['Người dùng không tồn tại.']);
    }

    if (isVip !== undefined) {
      user.isVip = isVip;
    }
    if (vipExpireAt !== undefined) {
      user.vipExpireAt = vipExpireAt ? new Date(vipExpireAt) : null;
    }
    await user.save();

    return sendSuccess(res, {
      id: user.id,
      isVip: user.isVip,
      vipExpireAt: user.vipExpireAt
    }, 'Cập nhật trạng thái người dùng thành công');
  } catch (error) {
    console.error('[INTERNAL USER PATCH ERROR]', error);
    return sendError(res, 500, 'Lỗi hệ thống', [error.message]);
  }
});

export default router;
