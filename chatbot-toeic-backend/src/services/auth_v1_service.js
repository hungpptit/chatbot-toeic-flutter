/**
 * Auth Service v1
 * Xử lý logic xác thực cho v1 API
 * - Register: Tạo tài khoản mới
 * - Login: Trả access token + refresh token
 * - Refresh: Cấp access token mới từ refresh token
 * - Logout: Xóa refresh token
 * - GetMe: Lấy info user từ token
 */

import db from '../models/index.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import { OAuth2Client } from 'google-auth-library';

const User = db.User;
const JWT_SECRET = process.env.JWT_SECRET_KEY;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET_KEY;
const JWT_EXPIRATION = process.env.JWT_EXPIRATION || '7d';
const REFRESH_EXPIRATION = process.env.JWT_REFRESH_EXPIRATION || '30d';

// Store refresh tokens (trong production nên dùng Redis)
const refreshTokenStore = new Map();

/**
 * Tạo JWT Access Token
 */
function createAccessToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      username: user.username,
      role_id: user.role_id,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRATION }
  );
}

/**
 * Tạo JWT Refresh Token
 */
function createRefreshToken(user) {
  const refreshToken = jwt.sign(
    {
      id: user.id,
      email: user.email,
      type: 'refresh',
    },
    REFRESH_SECRET,
    { expiresIn: REFRESH_EXPIRATION }
  );

  // Lưu refresh token vào store (tạm thời, nên move sang DB sau)
  refreshTokenStore.set(refreshToken, {
    userId: user.id,
    createdAt: new Date(),
  });

  return refreshToken;
}

/**
 * Đăng ký tài khoản mới
 */
export const register = async (data) => {
  try {
    const { username, email, password } = data;

    // Validate input
    if (!email || !password || !username) {
      return {
        code: 400,
        message: 'Missing required fields: username, email, password',
        details: ['username, email, password are required'],
      };
    }

    // Kiểm tra email đã tồn tại
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return {
        code: 409,
        message: 'Email already registered',
        details: ['This email is already in use'],
      };
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Tạo user mới
    const newUser = await User.create({
      username,
      email,
      password: hashedPassword,
      role_id: 1, // User role
    });

    return {
      code: 201,
      message: 'User registered successfully',
      data: {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
      },
    };
  } catch (error) {
    console.error('[AUTH_SERVICE] register error:', error);
    return {
      code: 500,
      message: 'Registration failed',
      details: [error.message],
    };
  }
};

/**
 * Đăng nhập - Trả access token + refresh token
 */
export const login = async (data) => {
  try {
    const { email, password } = data;

    // Validate input
    if (!email || !password) {
      return {
        code: 400,
        message: 'Missing email or password',
        details: ['email and password are required'],
      };
    }

    // Tìm user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return {
        code: 401,
        message: 'Invalid email or password',
        details: ['User not found'],
      };
    }

    // Kiểm tra tài khoản bị khóa
    if (user.status === false) {
      return {
        code: 403,
        message: 'Account is locked',
        details: ['Please contact administrator'],
      };
    }

    // Kiểm tra password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return {
        code: 401,
        message: 'Invalid email or password',
        details: ['Password is incorrect'],
      };
    }

    // Tạo tokens
    const accessToken = createAccessToken(user);
    const refreshToken = createRefreshToken(user);

    return {
      code: 200,
      message: 'Login successful',
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role_id: user.role_id,
        },
      },
    };
  } catch (error) {
    console.error('[AUTH_SERVICE] login error:', error);
    return {
      code: 500,
      message: 'Login failed',
      details: [error.message],
    };
  }
};

/**
 * Refresh Access Token
 * Nhận refresh token, trả access token mới
 */
export const refresh = async (refreshToken) => {
  try {
    if (!refreshToken) {
      return {
        code: 400,
        message: 'Refresh token is required',
        details: ['refreshToken is missing'],
      };
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, REFRESH_SECRET);
    } catch (err) {
      return {
        code: 401,
        message: 'Invalid or expired refresh token',
        details: [err.message],
      };
    }

    // Kiểm tra refresh token có trong store không
    if (!refreshTokenStore.has(refreshToken)) {
      return {
        code: 401,
        message: 'Refresh token revoked or not found',
        details: ['Token not in store'],
      };
    }

    // Lấy user
    const user = await User.findByPk(decoded.id);
    if (!user) {
      return {
        code: 404,
        message: 'User not found',
        details: ['Cannot find user for this token'],
      };
    }

    // Tạo access token mới
    const newAccessToken = createAccessToken(user);

    return {
      code: 200,
      message: 'Token refreshed successfully',
      data: {
        accessToken: newAccessToken,
      },
    };
  } catch (error) {
    console.error('[AUTH_SERVICE] refresh error:', error);
    return {
      code: 500,
      message: 'Token refresh failed',
      details: [error.message],
    };
  }
};

/**
 * Đăng xuất - Xóa refresh token
 */
export const logout = async (refreshToken) => {
  try {
    if (refreshToken && refreshTokenStore.has(refreshToken)) {
      refreshTokenStore.delete(refreshToken);
    }

    return {
      code: 200,
      message: 'Logged out successfully',
    };
  } catch (error) {
    console.error('[AUTH_SERVICE] logout error:', error);
    return {
      code: 500,
      message: 'Logout failed',
      details: [error.message],
    };
  }
};

/**
 * Lấy thông tin user từ access token
 */
export const getMe = async (user) => {
  try {
    if (!user) {
      return {
        code: 401,
        message: 'User not authenticated',
        details: ['No user info in token'],
      };
    }

    const dbUser = await User.findByPk(user.id);
    if (!dbUser) {
      return {
        code: 404,
        message: 'User not found',
        details: [],
      };
    }

    return {
      code: 200,
      message: 'User info retrieved successfully',
      data: {
        id: dbUser.id,
        username: dbUser.username,
        email: dbUser.email,
        avatar: dbUser.avatar || null,
        role_id: dbUser.role_id,
      },
    };
  } catch (error) {
    console.error('[AUTH_SERVICE] getMe error:', error);
    return {
      code: 500,
      message: 'Failed to get user info',
      details: [error.message],
    };
  }
};

export default {
  register,
  login,
  refresh,
  logout,
  getMe,
  createAccessToken,
  createRefreshToken,
};
