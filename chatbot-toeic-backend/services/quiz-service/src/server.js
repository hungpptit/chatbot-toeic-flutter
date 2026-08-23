import dotenv from 'dotenv';
dotenv.config(); // Load biến môi trường từ .env
import express, { json, urlencoded } from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger.js';
import router from './routes/api.js';
import { apiLimiter } from './Middleware/rateLimiter.js';
import db from './models/index.js';
import { errorHandler } from './utils/response.js';
import { initRabbitMQ } from './services/rabbitmq_service.js';

const app = express();
const port = process.env.PORT || 8082;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

// Serve static assets
app.use(express.static(path.join(__dirname, 'public')));

// Preview local file endpoint (mostly used by Admin Quiz Editor)
app.get('/api/admin/preview-local-file', (req, res) => {
  let filePath = req.query.path;
  if (!filePath) {
    return res.status(400).json({ message: 'Path is required' });
  }

  // Convert Windows path to Linux path in Docker
  if (process.platform === 'linux' && filePath.match(/^[a-zA-Z]:[\\/]/)) {
    const drive = filePath[0].toLowerCase();
    const relativePath = filePath.slice(3).replace(/\\/g, '/');
    filePath = `/mnt/${drive}/${relativePath}`;
  }

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ message: 'File not found: ' + filePath });
  }
  const ext = path.extname(filePath).toLowerCase();
  let contentType = 'application/octet-stream';
  if (['.jpg', '.jpeg'].includes(ext)) contentType = 'image/jpeg';
  else if ('.png' === ext) contentType = 'image/png';
  else if ('.gif' === ext) contentType = 'image/gif';
  else if ('.webp' === ext) contentType = 'image/webp';
  else if ('.mp3' === ext) contentType = 'audio/mpeg';
  else if ('.wav' === ext) contentType = 'audio/wav';

  res.setHeader('Content-Type', contentType);
  fs.createReadStream(filePath).pipe(res);
});

// === SWAGGER UI DOCUMENTATION ===
console.log('[SWAGGER] Swagger docs available at /api/docs');
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  swaggerOptions: {
    persistAuthorization: true, // Lưu Authorization token khi reload page
  },
}));

// API Endpoint to get raw OpenAPI JSON (For Flutter team)
app.get('/api/docs-json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

app.use('/api', apiLimiter, router);

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'quiz-service', timestamp: new Date().toISOString() });
});

app.use(errorHandler);

// Connect to DB and RabbitMQ
db.connectToDB();
initRabbitMQ();

// Start Learning Service Cron Jobs
import "./cronJobs/embeddingCron.js";
import "./cronJobs/mlRetrainCron.js";

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Quiz & Learning Service listening on http://0.0.0.0:${port}`);
  console.log(`📚 Swagger API Docs: http://localhost:8080/api/docs`);
});