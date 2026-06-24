/**
 * Auth Controller v1
 * Xử lý HTTP requests và responses
 */

import {
  register,
  login,
  googleLogin,
  refresh,
  logout,
  getMe,
  changePassword,
  sendForgotPasswordOtp,
  resetPassword,
} from '../services/auth_v1_service.js';
import { sendSuccess, sendError } from '../utils/response.js';

/**
 * POST /api/v1/auth/register
 */
export const registerController = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    const result = await register({ username, email, password });

    if (result.code !== 201) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, result.data, result.message, 201);
  } catch (error) {
    console.error('[CONTROLLER] registerController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/login
 */
export const loginController = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await login({ email, password });

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    // Set refresh token as secure httpOnly cookie (optional)
    // res.cookie('refreshToken', result.data.refreshToken, {
    //   httpOnly: true,
    //   secure: process.env.NODE_ENV === 'production',
    //   sameSite: 'Lax',
    //   maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    // });

    return sendSuccess(res, result.data, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] loginController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/google
 */
export const googleLoginController = async (req, res) => {
  try {
    const { idToken, accessToken } = req.body;
    const result = await googleLogin({ idToken, accessToken });

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, result.data, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] googleLoginController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/refresh
 */
export const refreshController = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return sendError(res, 400, 'Refresh token is required', ['refreshToken field is missing']);
    }

    const result = await refresh(refreshToken);

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, result.data, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] refreshController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/logout
 */
export const logoutController = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    const result = await logout(refreshToken);

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    // Clear all auth related cookies
    res.clearCookie('token', {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'Lax',
    });
    
    res.clearCookie('refreshToken', {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'Lax',
    });

    return sendSuccess(res, null, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] logoutController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * GET /api/v1/auth/me
 */
export const getMeController = async (req, res) => {
  try {
    const user = req.user; // Set by authMiddleware

    const result = await getMe(user);

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, result.data, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] getMeController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/change-password
 */
export const changePasswordController = async (req, res) => {
  try {
    const userId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return sendError(res, 400, 'Mật khẩu hiện tại và mật khẩu mới không được để trống', ['currentPassword và newPassword là bắt buộc']);
    }

    const result = await changePassword(userId, currentPassword, newPassword);

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, null, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] changePasswordController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/password/forgot
 */
export const forgotPasswordController = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return sendError(res, 400, 'Email không được để trống', ['email là bắt buộc']);
    }

    const result = await sendForgotPasswordOtp(email);

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, null, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] forgotPasswordController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

/**
 * POST /api/v1/auth/password/reset
 */
export const resetPasswordController = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return sendError(res, 400, 'Thông tin không được để trống', ['email, otp và newPassword là bắt buộc']);
    }

    const result = await resetPassword({ email, otp, newPassword });

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, null, result.message, 200);
  } catch (error) {
    console.error('[CONTROLLER] resetPasswordController error:', error);
    return sendError(res, 500, 'Server error', [error.message]);
  }
};

export default {
  registerController,
  loginController,
  googleLoginController,
  refreshController,
  logoutController,
  getMeController,
  changePasswordController,
  forgotPasswordController,
  resetPasswordController,
};
