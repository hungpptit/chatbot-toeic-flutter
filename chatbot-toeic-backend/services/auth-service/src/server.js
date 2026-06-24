import dotenv from 'dotenv';
dotenv.config(); // Load biến môi trường từ .env
import express, { json, urlencoded } from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import router from './routes/api.js';
import { apiLimiter } from './Middleware/rateLimiter.js';
import db from './models/index.js';
import { errorHandler } from './utils/response.js';
import { initRabbitMQ } from './services/rabbitmq_service.js';

const app = express();
const port = process.env.PORT || 8081;

// CORS CONFIG
const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5173,http://localhost:3000,http://localhost:8080').split(',');

app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    const isLocalhost = origin.startsWith('http://localhost:') || origin === 'http://localhost' || origin.startsWith('http://127.0.0.1:');
    if (isLocalhost || corsOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(json());
app.use(urlencoded({ extended: true }));
app.use(cookieParser());

app.use('/api', apiLimiter, router);

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'auth-service', timestamp: new Date().toISOString() });
});

app.use(errorHandler);

// Connect to DB and RabbitMQ
db.connectToDB();
initRabbitMQ();

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Auth Service server listening on http://0.0.0.0:${port}`);
});