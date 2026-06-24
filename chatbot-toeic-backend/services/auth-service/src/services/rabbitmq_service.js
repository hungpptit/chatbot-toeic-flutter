import amqp from 'amqplib';
import nodemailer from 'nodemailer';

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost';
const QUEUE_NAME = 'email_queue';

let connection = null;
let channel = null;
let isConnected = false;

// Transporter cho Nodemailer (chỉ dùng cho chế độ dự phòng gửi đồng bộ từ backend chính)
const getTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

// Khởi tạo kết nối RabbitMQ
export const initRabbitMQ = async () => {
  try {
    console.log(`[RabbitMQ] Đang kết nối tới: ${RABBITMQ_URL}`);
    connection = await amqp.connect(RABBITMQ_URL);
    channel = await connection.createChannel();
    await channel.assertQueue(QUEUE_NAME, { durable: true });
    
    isConnected = true;
    console.log('[RabbitMQ] Kết nối thành công! Đóng vai trò là Email Publisher.');

    // Lắng nghe sự kiện ngắt kết nối
    connection.on('close', () => {
      console.warn('[RabbitMQ] Kết nối bị đóng. Đang chuyển sang chế độ dự phòng (fallback)...');
      isConnected = false;
      setTimeout(initRabbitMQ, 10000); // Thử kết nối lại sau 10s
    });

    connection.on('error', (err) => {
      console.error('[RabbitMQ] Lỗi kết nối:', err.message);
      isConnected = false;
    });

  } catch (error) {
    console.warn('[RabbitMQ] Không thể kết nối tới RabbitMQ. Chế độ dự phòng (Synchronous Fallback) tự động kích hoạt.');
    console.warn(`[RabbitMQ] Chi tiết lỗi: ${error.message}`);
    isConnected = false;
  }
};

// Đẩy message gửi email vào hàng đợi
export const sendEmailAsync = async (emailData) => {
  const { to, subject, text } = emailData;

  // Nếu kết nối RabbitMQ thành công -> Sử dụng hàng đợi bất đồng bộ
  if (isConnected && channel) {
    try {
      const message = JSON.stringify({ to, subject, text });
      channel.sendToQueue(QUEUE_NAME, Buffer.from(message), { persistent: true });
      console.log(`[RabbitMQ] Đã đẩy email cần gửi tới ${to} vào hàng đợi thành công.`);
      return { success: true, mode: 'async' };
    } catch (err) {
      console.error('[RabbitMQ] Gặp lỗi khi đẩy vào hàng đợi, chuyển sang gửi trực tiếp:', err.message);
    }
  }

  // Chế độ dự phòng: Gửi trực tiếp đồng bộ (Nodemailer)
  console.log(`[RabbitMQ Fallback] Đang gửi email trực tiếp tới ${to} (Đồng bộ)...`);
  try {
    const transporter = getTransporter();
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to,
      subject,
      text,
    });
    console.log(`[RabbitMQ Fallback] Đã gửi email trực tiếp tới ${to} thành công.`);
    return { success: true, mode: 'sync' };
  } catch (error) {
    console.error('[RabbitMQ Fallback] Lỗi khi gửi email trực tiếp:', error.message);
    throw error;
  }
};
