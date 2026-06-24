import { rateLimit } from 'express-rate-limit';

/**
 * Tần suất giới hạn chung cho toàn bộ API (200 requests / 1 phút)
 */
export const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 phút
  max: 200, // Tối đa 200 request từ 1 IP trong 1 phút
  standardHeaders: true, // Trả về thông tin RateLimit trong Headers
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    res.status(options.statusCode).json({
      status: 'error',
      message: 'Quá nhiều yêu cầu từ IP của bạn. Vui lòng thử lại sau 1 phút.',
      details: ['Rate limit exceeded. Max 200 requests per minute.'],
      errorCode: 'TOO_MANY_REQUESTS',
    });
  },
});

/**
 * Tần suất giới hạn nghiêm ngặt cho các API Xác thực (Đăng nhập, Đăng ký, Quên mật khẩu - 10 requests / 1 phút)
 */
export const authLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 phút
  max: 10, // Tối đa 10 request từ 1 IP trong 1 phút
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    res.status(options.statusCode).json({
      status: 'error',
      message: 'Bạn đã thực hiện thao tác xác thực quá nhiều lần. Vui lòng thử lại sau 1 phút.',
      details: ['Auth rate limit exceeded. Max 10 attempts per minute.'],
      errorCode: 'TOO_MANY_AUTH_REQUESTS',
    });
  },
});
