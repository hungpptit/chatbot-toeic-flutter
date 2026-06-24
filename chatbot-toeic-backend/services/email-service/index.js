import amqp from 'amqplib';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost';
const QUEUE_NAME = 'email_queue';

console.log('✉️ [Email Service] Starting worker...');
console.log(`✉️ [Email Service] Connecting to RabbitMQ at: ${RABBITMQ_URL}`);

const getTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
};

async function start() {
  try {
    const connection = await amqp.connect(RABBITMQ_URL);
    const channel = await connection.createChannel();
    await channel.assertQueue(QUEUE_NAME, { durable: true });
    
    console.log('✅ [Email Service] Connected to RabbitMQ successfully. Listening to queue: "email_queue"');

    channel.consume(QUEUE_NAME, async (msg) => {
      if (msg !== null) {
        const emailData = JSON.parse(msg.content.toString());
        console.log(`✉️ [Email Service] Received email request for: ${emailData.to}`);

        try {
          const transporter = getTransporter();
          await transporter.sendMail({
            from: process.env.EMAIL_USER,
            to: emailData.to,
            subject: emailData.subject,
            text: emailData.text,
          });

          console.log(`✅ [Email Service] Email sent successfully to: ${emailData.to}`);
          channel.ack(msg);
        } catch (sendError) {
          console.error(`❌ [Email Service] Failed to send email to ${emailData.to}:`, sendError.message);
          // Requeue if it is a transient error, or reject without requeue if config is wrong
          // Here we do not requeue to avoid infinite loop of failures
          channel.nack(msg, false, false);
        }
      }
    }, { noAck: false });

    // Handle connection closure
    connection.on('close', () => {
      console.warn('⚠️ [Email Service] RabbitMQ connection closed. Attempting reconnect in 10 seconds...');
      setTimeout(start, 10000);
    });

    connection.on('error', (err) => {
      console.error('❌ [Email Service] RabbitMQ error:', err.message);
    });

  } catch (error) {
    console.error('❌ [Email Service] Failed to start worker:', error.message);
    console.log('🔄 [Email Service] Retrying connection in 10 seconds...');
    setTimeout(start, 10000);
  }
}

start();
