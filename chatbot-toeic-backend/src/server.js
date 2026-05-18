import dotenv from 'dotenv';
dotenv.config(); // Load biến môi trường từ .env
import express, { json, urlencoded } from 'express'; // Import express và middleware
import path from 'path'; // <-- THÊM IMPORT NÀY
import { fileURLToPath } from 'url'; // <-- THÊM IMPORT NÀY (nếu dùng ES Modules)
import router from './routes/api.js'; // Import router từ file api.js
import db from './models/index.js'; // Import db từ file index.js trong thư mục models
import cookieParser from 'cookie-parser';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger.js';
import { errorHandler } from './utils/response.js';


const app = express();
const port = process.env.PORT;
const hostname = process.env.HOSTNAME;

// --- LẤY ĐƯỜNG DẪN THƯ MỤC HIỆN TẠI ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
console.log('Serving static files from directory:', path.join(__dirname, 'public')); // Log đường dẫn để kiểm tra
// --------------------------------------

// === CORS CONFIG (LINH HOẠT THEO MÔI TRƯỜNG) ===
const corsOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5173,http://localhost:3000,http://localhost:8080').split(',');
console.log('[CORS] Allowed origins:', corsOrigins);

app.use(cors({
  origin: (origin, callback) => {
    console.log('[CORS] Request from origin:', origin);
    // Cho phép requests không có origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    // Trong môi trường development, cho phép tất cả các port từ localhost (cho Flutter Web)
    const isLocalhost = origin.startsWith('http://localhost:') || origin === 'http://localhost' || origin.startsWith('http://127.0.0.1:');

    if (isLocalhost || corsOrigins.includes(origin)) {
      callback(null, true);
    } else {
      console.warn('[CORS] Blocked origin:', origin);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true, // Cho phép cookies/auth headers
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(json()); // Parse dữ liệu từ request body với định dạng json
app.use(urlencoded({ extended: true })); // Parse dữ liệu từ request body với định dạng urlencoded
app.use(express.json());
app.use(cookieParser());

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

// --- PHỤC VỤ FILE TĨNH TỪ THƯ MỤC 'public' ---
// Middleware này phải được đặt TRƯỚC app.use('/api', router)
app.use(express.static(path.join(__dirname, 'public')));
// Giờ đây, yêu cầu GET /assets/track_image/ten_anh.jpg sẽ được phục vụ từ thư mục public/assets/track_image
// --------------------------------------------

app.use('/api', router); // Định nghĩa các route API SAU middleware static

// === HEALTH CHECK ENDPOINT ===
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// === ERROR HANDLER MIDDLEWARE (PHẢI ĐẶT CUỐI CÙNG) ===
app.use(errorHandler);

// Test kết nối database
db.connectToDB();
import "./cronJobs/embeddingCron.js";
import "./cronJobs/mlRetrainCron.js"; // ✅ Auto-retrain ML models every 6 hours

app.listen(port || 8080, '0.0.0.0', () => {
  console.log(`✅ Backend server listening on http://0.0.0.0:${port || 8080}`);
  console.log(`📚 Swagger API Docs: http://localhost:${port || 8080}/api/docs`);
});