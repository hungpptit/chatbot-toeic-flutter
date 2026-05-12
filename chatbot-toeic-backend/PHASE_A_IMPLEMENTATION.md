# PHASE A: Foundation - Hoàn thành ✅

## 📋 Tóm tắt những gì đã được thực hiện

### 1. ✅ Thêm Dependencies
**File: `package.json`**
- Thêm `swagger-jsdoc` (v6.2.8) - Tạo specification OpenAPI từ JSDoc comments
- Thêm `swagger-ui-express` (v5.0.0) - UI dashboard cho API documentation

**Chạy lệnh để cài đặt:**
```bash
npm install
```

---

### 2. ✅ Tạo Response Wrapper Utility
**File: `src/utils/response.js`**

Chuẩn hóa format response cho toàn bộ API:

**Success Response:**
```json
{
  "status": "success",
  "message": "Operation successful",
  "data": { /* actual data */ },
  "meta": {
    "timestamp": "2024-05-08T10:30:00.000Z"
  }
}
```

**Error Response:**
```json
{
  "status": "error",
  "code": 400,
  "message": "Error message",
  "errorCode": "VALIDATION_ERROR",
  "details": ["Field validation failed"],
  "timestamp": "2024-05-08T10:30:00.000Z"
}
```

**Hàm có sẵn:**
- `sendSuccess(res, data, message, statusCode, meta)` - Trả về success response
- `sendError(res, code, message, details, errorCode)` - Trả về error response
- `errorHandler` - Middleware xử lý lỗi tập trung
- `APIError` - Class custom error để dùng trong controller

---

### 3. ✅ Cập nhật Auth Middleware
**File: `src/Middleware/authMiddleware.js`**

**Thay đổi chính:**
- ✅ **Ưu tiên Bearer Token** từ `Authorization: Bearer <token>` header
- ✅ **Fallback Cookie** cho backward compatibility (Web cũ vẫn chạy được)
- ✅ Phân biệt các loại lỗi token (expired, invalid, missing)
- ✅ Dùng `sendError()` để response chuẩn định dạng

**Cách hoạt động:**
1. Kiểm tra `Authorization: Bearer <token>` trước
2. Nếu không có, lấy từ `req.cookies.token` (tạm thời)
3. Verify JWT token
4. Attach user info vào `req.user`

**Ví dụ sử dụng:**
```javascript
// Header (ưu tiên)
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// hoặc Cookie (fallback)
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### 4. ✅ Tạo Swagger Configuration
**File: `src/config/swagger.js`**

**Cấu hình bao gồm:**
- ✅ OpenAPI 3.0.0 specification
- ✅ Security schemes (JWT Bearer + Cookie)
- ✅ Common response schemas (Success, Error, 401, 400, 404)
- ✅ Dynamic server URLs từ `.env`
- ✅ Tìm kiếm JSDoc comments trong routes, controllers, models

**Cách Swagger hoạt động:**
- Swagger sẽ tự động quét tất cả `src/routes/*.js`, `src/controllers/*.js`, `src/models/*.js`
- Tìm các JSDoc comments với `@swagger` tag
- Generate interactive API documentation

---

### 5. ✅ Cập nhật Server Entry Point
**File: `src/server.js`**

**Thay đổi chính:**
- ✅ Import Swagger UI + config
- ✅ **CORS Config Linh Hoạt**: Đọc từ `CORS_ORIGINS` env variable (comma-separated)
- ✅ **Swagger UI**: Trang docs tại `/api/docs` với persistent authorization
- ✅ **Error Handler Middleware**: Xử lý lỗi tập trung ở cuối (middleware cuối cùng)
- ✅ **Health Check Endpoint**: `GET /health` để kiểm tra server sống

**Swagger Features:**
- 🔐 Padlock authorization button hoạt động với Bearer token
- 💾 Persistent authorization (token được lưu khi reload)
- 🧪 "Try it out" button để test API trực tiếp

---

### 6. ✅ Cập nhật Auth Router
**File: `src/routes/auth_router.js`**

**Thay đổi chính:**
- ✅ Thêm JSDoc Swagger comments cho mỗi endpoint
- ✅ Sử dụng `sendSuccess()` + `sendError()` thay vì `res.json()`
- ✅ Response format chuẩn

**Endpoints được tài liệu hóa:**
- `GET /api/me` - Lấy thông tin user hiện tại
- `POST /api/logout` - Đăng xuất

---

### 7. ✅ Tạo .env.example
**File: `.env.example`**

Hướng dẫn các biến môi trường cần thiết:
- `CORS_ORIGINS` - Danh sách origin được phép (comma-separated)
- `JWT_SECRET_KEY` - Secret key cho JWT token
- `JWT_REFRESH_SECRET_KEY` - Secret key cho refresh token
- Các config khác (DB, Google, Cloudinary, Email, etc.)

---

## 🚀 Cách sử dụng Phase A

### Step 1: Cài dependencies
```bash
cd chatbot-toeic-backend
npm install
```

### Step 2: Setup .env
```bash
cp .env.example .env
# Cập nhật các biến môi trường trong .env
```

### Step 3: Khởi động server
```bash
npm run dev
```

### Step 4: Truy cập Swagger UI
Mở browser → http://localhost:8080/api/docs

---

## 📚 Cách sử dụng Swagger để Document API

### Ví dụ JSDoc Swagger comment:
```javascript
/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Đăng nhập user
 *     tags:
 *       - Auth
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 example: password123
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         $ref: '#/components/responses/UnauthorizedError'
 */
router.post('/api/v1/auth/login', loginController);
```

### Nguyên tắc documenting endpoints:
1. Mỗi endpoint mới phải có JSDoc với `@swagger` tag
2. Define rõ: path, method (post/get/put/delete), summary, tags
3. Define requestBody schema (input)
4. Define responses (output + lỗi)
5. Security: thêm `security: [{ BearerAuth: [] }]` nếu cần auth

---

## ✅ Definition of Done - Phase A

- [x] Swagger UI hoạt động ✅
- [x] Auth Middleware hỗ trợ cả Bearer token + Cookie ✅
- [x] Response format chuẩn hóa ✅
- [x] CORS config linh hoạt ✅
- [x] Error handling tập trung ✅
- [x] Swagger decorator examples có ✅

---

## 🎯 Bước tiếp theo - Phase B: Auth API v1

Sau khi xác nhận Phase A hoạt động tốt, sẽ:
1. Tạo `/api/v1/auth/register` endpoint + Swagger doc
2. Tạo `/api/v1/auth/login` endpoint (trả JWT + Refresh token)
3. Tạo `/api/v1/auth/refresh` endpoint (refresh access token)
4. Tạo `/api/v1/auth/me` endpoint (v1 version)
5. Tạo `/api/v1/auth/logout` endpoint (v1 version)

---

## 📝 Notes

- Các endpoint cũ (`/api/...`) vẫn hoạt động (backward compatibility)
- Swagger sẽ auto-generate docs từ JSDoc comments
- Bearer token trong Swagger UI được lưu persistent (dùng "Authorize" button)
- CORS được config từ `.env` → dễ dàng thay đổi per environment
