import db from './models/index.js';

async function resetVip() {
  try {
    const email = 'hungneverdie24@gmail.com';
    const user = await db.User.findOne({ where: { email } });
    if (!user) {
      console.log(`Không tìm thấy người dùng có email: ${email}`);
      process.exit(1);
    }
    user.isVip = false;
    user.vipExpireAt = null;
    await user.save();
    
    // Xoá hoặc reset các giao dịch/lịch sử đăng ký VIP của user để test lại sạch sẽ
    await db.Transaction.destroy({ where: { userId: user.id } });
    await db.UserSubscription.destroy({ where: { userId: user.id } });

    console.log(`Đã reset thành công trạng thái VIP và lịch sử thanh toán của tài khoản: ${email}`);
    process.exit(0);
  } catch (error) {
    console.error('Lỗi khi reset VIP:', error);
    process.exit(1);
  }
}

resetVip();
