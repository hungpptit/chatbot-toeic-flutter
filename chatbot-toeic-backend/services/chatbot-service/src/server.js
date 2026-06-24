import dotenv from 'dotenv';
dotenv.config(); // Load biến môi trường từ .env
import express, { json, urlencoded } from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import router from './routes/api.js';
import { apiLimiter } from './Middleware/rateLimiter.js';
import db from './models/index.js';
import { errorHandler } from './utils/response.js';

const app = express();
const port = process.env.PORT || 8084;

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
  res.json({ status: 'healthy', service: 'chatbot-service', timestamp: new Date().toISOString() });
});

app.use(errorHandler);

// Connect to DB only
db.connectToDB();

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Chatbot Service listening on http://0.0.0.0:${port}`);
});