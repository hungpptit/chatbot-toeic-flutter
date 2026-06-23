import db from '../models/index.js';
import { sendError } from '../utils/response.js';

const FREE_CHAT_LIMIT = 15;

export const vipCheckMiddleware = async (req, res, next) => {
  try {
    if (!req.user || !req.user.id) {
      return sendError(
        res,
        401,
        'Thiếu thông tin người dùng',
        ['Vui lòng đăng nhập để tiếp tục'],
        'UNAUTHORIZED'
      );
    }

    const userId = req.user.id;

    // 1️⃣ Lấy thông tin user hiện tại từ Database
    const user = await db.User.findByPk(userId);
    if (!user) {
      return sendError(
        res,
        404,
        'Không tìm thấy người dùng',
        ['Tài khoản của bạn không tồn tại trên hệ thống'],
        'USER_NOT_FOUND'
      );
    }

    // 2️⃣ Kiểm tra xem người dùng có gói VIP đang kích hoạt hay không
    const now = new Date();
    const isVipActive = user.isVip && user.vipExpireAt && new Date(user.vipExpireAt) > now;

    if (isVipActive) {
      // Người dùng là VIP → Bỏ qua giới hạn tin nhắn
      req.isVip = true;
      return next();
    }

    // 3️⃣ Người dùng thường (Free) → Đếm số tin nhắn đã gửi hôm nay
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const messageCount = await db.Message.count({
      include: [{
        model: db.Conversation,
        as: 'conversation',
        where: { userId }
      }],
      where: {
        role: 'user',
        createdAt: {
          [db.Sequelize.Op.between]: [todayStart, todayEnd]
        }
      }
    });

    if (messageCount >= FREE_CHAT_LIMIT) {
      return sendError(
        res,
        403,
        `Bạn đã đạt giới hạn ${FREE_CHAT_LIMIT} tin nhắn miễn phí hôm nay.`,
        ['Vui lòng nâng cấp tài khoản lên gói VIP để tiếp tục trò chuyện không giới hạn với AI Chatbot.'],
        'CHAT_LIMIT_EXCEEDED'
      );
    }

    // Gắn thêm số tin nhắn đã dùng và giới hạn để controller có thể trả về thông tin meta nếu muốn
    req.isVip = false;
    req.chatLimit = FREE_CHAT_LIMIT;
    req.chatCountToday = messageCount;

    next();
  } catch (error) {
    console.error('[VIP CHECK ERROR]', error);
    return sendError(
      res,
      500,
      'Lỗi kiểm tra quyền hạn tài khoản',
      [error.message],
      'VIP_CHECK_ERROR'
    );
  }
};
