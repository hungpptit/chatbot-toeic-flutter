// middlewares/authMiddleware.js
import jwt from "jsonwebtoken";
import { sendError } from "../utils/response.js";

const SECRET_KEY = process.env.JWT_SECRET_KEY;

/**
 * Unified Auth Middleware
 * Ưu tiên: Authorization header (Bearer token) > Cookie
 * Hỗ trợ cả JWT access token từ header hoặc cookie
 */
export const authMiddleware = (req, res, next) => {
  try {
    let token = null;

    // 1️⃣ Ưu tiên lấy từ Authorization header (Bearer token)
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.slice(7); // Bỏ "Bearer " prefix
      console.log('[AUTH] Token from Authorization header');
    }

    // 2️⃣ Fallback: Lấy từ Cookie (cho backward compatibility Web cũ)
    if (!token) {
      token = req.cookies.token;
      if (token) {
        console.log('[AUTH] Token from Cookie (fallback)');
      }
    }

    // 3️⃣ Nếu không có token nào, trả về lỗi
    if (!token) {
      return sendError(
        res,
        401,
        'Thiếu token xác thực',
        ['Token không tìm thấy trong Authorization header hoặc Cookie'],
        'MISSING_TOKEN'
      );
    }

    // 4️⃣ Verify token
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded; // Gắn thông tin người dùng vào request object
    req.token = token; // Lưu token để có thể sử dụng lại (ví dụ: refresh token)
    next();
  } catch (err) {
    console.error('[AUTH ERROR]', err.message);

    // Phân biệt loại lỗi
    let message = 'Token không hợp lệ';
    let errorCode = 'INVALID_TOKEN';

    if (err.name === 'TokenExpiredError') {
      message = 'Token đã hết hạn';
      errorCode = 'TOKEN_EXPIRED';
    } else if (err.name === 'JsonWebTokenError') {
      message = 'Token không hợp lệ';
      errorCode = 'INVALID_TOKEN';
    }

    return sendError(
      res,
      401,
      message,
      [err.message],
      errorCode
    );
  }
};
