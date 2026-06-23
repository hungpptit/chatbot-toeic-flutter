'use strict';
import db from '../models/index.js';
import crypto from 'crypto';
import axios from 'axios';

const Subscription = db.Subscription;
const UserSubscription = db.UserSubscription;
const Transaction = db.Transaction;
const User = db.User;

/**
 * Lấy danh sách gói VIP hiện có
 */
export const getSubscriptions = async () => {
  try {
    const list = await Subscription.findAll({
      order: [['price', 'ASC']]
    });
    return {
      code: 200,
      message: 'Lấy danh sách gói cước thành công',
      data: list
    };
  } catch (error) {
    console.error('[PAYMENT_SERVICE] getSubscriptions error:', error);
    return {
      code: 500,
      message: 'Không thể lấy danh sách gói cước',
      details: [error.message]
    };
  }
};

/**
 * Lấy trạng thái VIP của người dùng hiện tại
 */
export const getVipStatus = async (userId) => {
  try {
    const user = await User.findByPk(userId);
    if (!user) {
      return {
        code: 404,
        message: 'Không tìm thấy người dùng',
        details: []
      };
    }

    const now = new Date();
    const isVipActive = user.isVip && user.vipExpireAt && new Date(user.vipExpireAt) > now;

    // Đếm số tin nhắn đã gửi hôm nay
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

    return {
      code: 200,
      message: 'Lấy trạng thái tài khoản thành công',
      data: {
        userId: user.id,
        isVip: isVipActive,
        vipExpireAt: user.vipExpireAt,
        chatLimitToday: isVipActive ? -1 : 15,
        chatCountToday: messageCount,
        remainingChatsToday: isVipActive ? -1 : Math.max(0, 15 - messageCount)
      }
    };
  } catch (error) {
    console.error('[PAYMENT_SERVICE] getVipStatus error:', error);
    return {
      code: 500,
      message: 'Không thể lấy trạng thái tài khoản',
      details: [error.message]
    };
  }
};

/**
 * Khởi tạo giao dịch thanh toán
 */
export const createPaymentOrder = async ({ userId, subscriptionId, paymentGateway, clientIp, returnUrl }) => {
  try {
    // 1. Kiểm tra gói VIP có tồn tại không
    const subscription = await Subscription.findByPk(subscriptionId);
    if (!subscription) {
      return {
        code: 404,
        message: 'Gói cước không tồn tại',
        details: []
      };
    }

    // 2. Tạo ID giao dịch ngẫu nhiên
    const orderId = `VIP_${userId}_${Date.now()}`;

    // 3. Lưu giao dịch 'pending' vào cơ sở dữ liệu
    const transaction = await Transaction.create({
      userId,
      amount: subscription.price,
      paymentGateway: paymentGateway.toLowerCase(),
      gatewayTransactionId: orderId,
      status: 'pending'
    });

    let paymentUrl = '';
    let finalGatewayTransId = orderId;

    // 4. Xử lý tích hợp từng cổng thanh toán
    if (paymentGateway.toLowerCase() === 'zalopay') {
      const zaloPayResult = await generateZaloPayUrl({
        orderId,
        amount: subscription.price,
        orderInfo: `Thanh toan goi VIP TOEIC: ${subscription.name}`,
        userId
      });
      paymentUrl = zaloPayResult.paymentUrl;
      finalGatewayTransId = zaloPayResult.appTransId;

      // Cập nhật mã giao dịch ZaloPay
      transaction.gatewayTransactionId = finalGatewayTransId;
      await transaction.save();
    } else if (paymentGateway.toLowerCase() === 'momo') {
      paymentUrl = await generateMomoUrl({
        orderId,
        amount: subscription.price,
        orderInfo: `Thanh toan goi VIP TOEIC: ${subscription.name}`
      });
    } else {
      return {
        code: 400,
        message: `Cổng thanh toán ${paymentGateway} không được hỗ trợ.`,
        details: []
      };
    }

    return {
      code: 200,
      message: 'Khởi tạo thanh toán thành công',
      data: {
        transactionId: transaction.id,
        orderId: finalGatewayTransId,
        amount: subscription.price,
        paymentGateway,
        paymentUrl
      }
    };
  } catch (error) {
    console.error('[PAYMENT_SERVICE] createPaymentOrder error:', error);
    return {
      code: 500,
      message: 'Khởi tạo thanh toán thất bại',
      details: [error.message]
    };
  }
};

/**
 * Xử lý sau khi thanh toán thành công
 */
export const activateVipSubscription = async (orderId) => {
  const t = await db.sequelize.transaction();
  try {
    // 1. Tìm giao dịch
    const transaction = await Transaction.findOne({
      where: { gatewayTransactionId: orderId },
      transaction: t
    });

    if (!transaction) {
      await t.rollback();
      return { code: 404, message: 'Giao dịch không tồn tại' };
    }

    if (transaction.status === 'success') {
      await t.rollback();
      return { code: 200, message: 'Giao dịch đã được xử lý trước đó' };
    }

    // 2. Cập nhật trạng thái giao dịch
    transaction.status = 'success';
    await transaction.save({ transaction: t });

    // Trích xuất userId và lấy thông tin gói cước
    // Mã orderId có định dạng: VIP_{userId}_{timestamp} hoặc {yymmdd}_VIP_{userId}_{timestamp}
    const parts = orderId.split('_');
    const vipIndex = parts.indexOf('VIP');
    const userId = parseInt(parts[vipIndex !== -1 ? vipIndex + 1 : 1]);

    // Phân tích gói cước từ số tiền giao dịch
    // Tìm gói cước khớp với số tiền giao dịch
    const subscription = await Subscription.findOne({
      where: { price: transaction.amount },
      transaction: t
    });

    if (!subscription) {
      await t.rollback();
      return { code: 404, message: 'Không xác định được gói cước cho giao dịch này' };
    }

    const user = await User.findByPk(userId, { transaction: t });
    if (!user) {
      await t.rollback();
      return { code: 404, message: 'Người dùng không tồn tại' };
    }

    // 3. Tính toán ngày hết hạn VIP mới
    const now = new Date();
    let newVipExpireAt;

    if (user.isVip && user.vipExpireAt && new Date(user.vipExpireAt) > now) {
      // Nếu đã có VIP và còn hạn -> Cộng thêm ngày
      newVipExpireAt = new Date(user.vipExpireAt);
      newVipExpireAt.setDate(newVipExpireAt.getDate() + subscription.durationDays);
    } else {
      // Nếu chưa có VIP hoặc hết hạn -> Bắt đầu từ hiện tại
      newVipExpireAt = new Date();
      newVipExpireAt.setDate(newVipExpireAt.getDate() + subscription.durationDays);
    }

    // 4. Cập nhật trạng thái VIP của User
    user.isVip = true;
    user.vipExpireAt = newVipExpireAt;
    await user.save({ transaction: t });

    // 5. Ghi nhận nhật ký đăng ký gói
    await UserSubscription.create({
      userId: user.id,
      subscriptionId: subscription.id,
      startDate: now,
      endDate: newVipExpireAt,
      status: 'active'
    }, { transaction: t });

    await t.commit();
    console.log(`[PAYMENT] VIP activated successfully for User ID: ${userId}. New Expire: ${newVipExpireAt}`);

    return {
      code: 200,
      message: 'Kích hoạt gói VIP thành công',
      data: {
        userId,
        isVip: true,
        vipExpireAt: newVipExpireAt
      }
    };
  } catch (error) {
    await t.rollback();
    console.error('[PAYMENT_SERVICE] activateVipSubscription error:', error);
    return {
      code: 500,
      message: 'Lỗi kích hoạt gói VIP',
      details: [error.message]
    };
  }
};

// ==========================================
// CÁC HÀM TIỆN ÍCH TẠO LINK CỔNG THANH TOÁN
// ==========================================

async function generateMomoUrl({ orderId, amount, orderInfo }) {
  // Demo MoMo Sandbox configuration
  return 'https://test-payment.momo.vn/v2/gateway/api/create'; // Đối với MoMo cần thực hiện POST request
}

function sortObject(obj) {
  const sorted = {};
  const str = [];
  let key;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      str.push(encodeURIComponent(key));
    }
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
    sorted[str[key]] = obj[str[key]];
  }
  return sorted;
}

/**
 * Xử lý callback từ ZaloPay
 */
export const processZaloPayCallback = async (dataStr, macStr) => {
  try {
    const key2 = process.env.ZALOPAY_KEY2 || 'trMrHtvjo6myautxDUiAcYsVtaeQ8nhf';

    // Xác minh chữ ký bảo mật MAC
    const reqMac = crypto.createHmac('sha256', key2).update(dataStr).digest('hex');
    if (reqMac !== macStr) {
      console.warn('[ZALOPAY CALLBACK] Invalid MAC signature.');
      return {
        return_code: -1,
        return_message: 'mac invalid'
      };
    }

    // Kích hoạt VIP
    const dataObj = JSON.parse(dataStr);
    const appTransId = dataObj.app_trans_id;
    console.log(`[ZALOPAY CALLBACK] Verify success. appTransId: ${appTransId}`);

    const result = await activateVipSubscription(appTransId);
    if (result.code === 200) {
      return {
        return_code: 1,
        return_message: 'success'
      };
    } else {
      return {
        return_code: 2,
        return_message: result.message || 'activation failed'
      };
    }
  } catch (error) {
    console.error('[ZALOPAY CALLBACK ERROR]', error);
    return {
      return_code: 500,
      return_message: error.message
    };
  }
};

async function generateZaloPayUrl({ orderId, amount, orderInfo, userId }) {
  const appId = parseInt(process.env.ZALOPAY_APP_ID || '2554');
  const key1 = process.env.ZALOPAY_KEY1 || 'sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn';
  const endpoint = process.env.ZALOPAY_ENDPOINT || 'https://sb-openapi.zalopay.vn';
  const callbackUrl = process.env.ZALOPAY_CALLBACK_URL || 'http://localhost:8080/api/v1/payments/zalopay-callback';

  const date = new Date();
  const yymmdd = formatDateYYMMDD(date);
  const appTransId = `${yymmdd}_${orderId}`;

  const embedData = JSON.stringify({});
  const item = JSON.stringify([]);
  const appTime = Date.now();
  const appUser = `user_${userId}`;

  // Formula: app_id|app_trans_id|app_user|amount|app_time|embed_data|item
  const dataToSign = `${appId}|${appTransId}|${appUser}|${amount}|${appTime}|${embedData}|${item}`;
  const mac = crypto.createHmac('sha256', key1).update(dataToSign).digest('hex');

  const payload = {
    app_id: appId,
    app_trans_id: appTransId,
    app_user: appUser,
    app_time: appTime,
    amount: amount,
    item: item,
    embed_data: embedData,
    callback_url: callbackUrl,
    description: orderInfo,
    bank_code: '',
    mac: mac
  };

  const response = await axios.post(`${endpoint}/v2/create`, payload);
  if (response.data && response.data.return_code === 1) {
    return {
      paymentUrl: response.data.order_url,
      appTransId: appTransId
    };
  } else {
    throw new Error(response.data.return_message || 'ZaloPay Create Order Error');
  }
}

function formatDateYYMMDD(date) {
  const yy = date.getFullYear().toString().slice(-2);
  const mm = ('0' + (date.getMonth() + 1)).slice(-2);
  const dd = ('0' + date.getDate()).slice(-2);
  return `${yy}${mm}${dd}`;
}
