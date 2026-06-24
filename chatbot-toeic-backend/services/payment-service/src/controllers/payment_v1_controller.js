'use strict';
import * as paymentService from '../services/payment_v1_service.js';
import { sendSuccess, sendError } from '../utils/response.js';

/**
 * Lấy danh sách gói cước VIP
 */
export const getSubscriptionsController = async (req, res, next) => {
  try {
    const result = await paymentService.getSubscriptions();
    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }
    return sendSuccess(res, result.data, result.message, result.code);
  } catch (error) {
    next(error);
  }
};

/**
 * Kiểm tra trạng thái VIP hiện tại của tôi
 */
export const getVipStatusController = async (req, res, next) => {
  try {
    const result = await paymentService.getVipStatus(req.user.id);
    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }
    return sendSuccess(res, result.data, result.message, result.code);
  } catch (error) {
    next(error);
  }
};

/**
 * Khởi tạo đơn hàng thanh toán
 */
export const createPaymentController = async (req, res, next) => {
  try {
    const { subscriptionId, paymentGateway, returnUrl } = req.body;
    const userId = req.user.id;
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';

    if (!subscriptionId || !paymentGateway) {
      return sendError(
        res,
        400,
        'Thiếu thông tin yêu cầu',
        ['subscriptionId và paymentGateway là bắt buộc.'],
        'MISSING_REQUIRED_FIELDS'
      );
    }

    const result = await paymentService.createPaymentOrder({
      userId,
      subscriptionId,
      paymentGateway,
      clientIp,
      returnUrl
    });

    if (result.code !== 200) {
      return sendError(res, result.code, result.message, result.details);
    }

    return sendSuccess(res, result.data, result.message, result.code);
  } catch (error) {
    next(error);
  }
};




/**
 * Nhận kết quả thanh toán webhook từ ZaloPay
 */
export const zalopayCallbackController = async (req, res, next) => {
  try {
    const { data, mac } = req.body;
    if (!data || !mac) {
      return res.status(400).json({
        return_code: -1,
        return_message: 'missing data or mac'
      });
    }

    const result = await paymentService.processZaloPayCallback(data, mac);
    return res.json(result);
  } catch (error) {
    next(error);
  }
};
