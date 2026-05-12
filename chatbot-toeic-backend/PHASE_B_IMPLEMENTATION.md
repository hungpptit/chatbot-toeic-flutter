# PHASE B: Auth v1 API - Hoàn thành ✅

## 📋 Tóm tắt những gì đã được thực hiện

### 1. ✅ Tạo Auth Service v1
**File: `src/services/auth_v1_service.js`**

**Chức năng:**
- ✅ `register()` - Tạo tài khoản mới
- ✅ `login()` - Đăng nhập, trả access token + refresh token
- ✅ `refresh()` - Cấp access token mới từ refresh token
- ✅ `logout()` - Xóa refresh token
- ✅ `getMe()` - Lấy thông tin user từ token

**Đặc điểm:**
- JWT Access Token: Hết hạn theo `JWT_EXPIRATION` (.env)
- JWT Refresh Token: Hết hạn theo `JWT_REFRESH_EXPIRATION` (.env)
- Refresh tokens lưu tạm trong memory Map (nên move sang Redis sau)
- Error handling chuẩn với status code + details

---

### 2. ✅ Tạo Auth Controller v1
**File: `src/controllers/auth_v1_controller.js`**

**Controllers:**
- `registerController` - Handle POST /api/v1/auth/register
- `loginController` - Handle POST /api/v1/auth/login
- `refreshController` - Handle POST /api/v1/auth/refresh
- `logoutController` - Handle POST /api/v1/auth/logout
- `getMeController` - Handle GET /api/v1/auth/me

**Đặc điểm:**
- Sử dụng `sendSuccess()` và `sendError()` từ utils
- Try-catch error handling
- Input validation
- Consistent response format

---

### 3. ✅ Tạo Auth Router v1
**File: `src/routes/auth_v1_router.js`**

**Endpoints được tạo:**

```
POST   /api/v1/auth/register      - Đăng ký
POST   /api/v1/auth/login         - Đăng nhập
POST   /api/v1/auth/refresh       - Làm mới token
POST   /api/v1/auth/logout        - Đăng xuất
GET    /api/v1/auth/me            - Lấy info user (require Bearer token)
```

**Swagger Decorators:**
- ✅ Full JSDoc comments cho mỗi endpoint
- ✅ Request/Response schemas
- ✅ Error response definitions
- ✅ Security annotations

---

### 4. ✅ Cập nhật Main API Router
**File: `src/routes/api.js`**

**Thay đổi:**
- ✅ Import auth_v1_router
- ✅ Gắn router: `router.use('/v1/auth', authV1Router)`
- ✅ Giữ legacy API endpoints (backward compatibility)
- ✅ Tách rõ: v1 (new) vs legacy (old)

---

## 🚀 Cách sử dụng Phase B

### Step 1: Restart server
```bash
# (Hoặc để nodemon tự reload)
npm run dev
```

### Step 2: Mở Swagger UI
```
http://localhost:8080/api/docs
```

### Step 3: Xem endpoints mới
Scroll xuống, sẽ thấy section **"Auth (v1)"** với 5 endpoints:
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/refresh
- POST /api/v1/auth/logout
- GET /api/v1/auth/me

---

## 📝 Cách Test Endpoints

### Test 1: Register
1. Mở Swagger UI
2. Scroll đến "Auth (v1)"
3. Click POST `/api/v1/auth/register`
4. Click "Try it out"
5. Điền JSON body:
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "Password@123"
}
```
6. Click "Execute"
✅ Response 201: User registered successfully

### Test 2: Login
1. Click POST `/api/v1/auth/login`
2. Điền body:
```json
{
  "email": "test@example.com",
  "password": "Password@123"
}
```
3. Click "Execute"
✅ Response 200: accessToken + refreshToken

### Test 3: Get Me (require token)
1. Copy `accessToken` từ login response
2. Click "Authorize" (padlock icon top right)
3. Paste vào: `Bearer <accessToken>`
4. Click "Authorize"
5. Scroll đến GET `/api/v1/auth/me`
6. Click "Try it out" → "Execute"
✅ Response 200: User info

### Test 4: Refresh Token
1. Copy `refreshToken` từ login response
2. Click POST `/api/v1/auth/refresh`
3. Điền body:
```json
{
  "refreshToken": "<paste-refresh-token-here>"
}
```
4. Click "Execute"
✅ Response 200: New accessToken

### Test 5: Logout
1. Click POST `/api/v1/auth/logout`
2. Điền body (optional):
```json
{
  "refreshToken": "<paste-refresh-token-here>"
}
```
3. Click "Execute"
✅ Response 200: Logged out successfully

---

## 📚 API Request Examples (cURL)

### Register
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Password@123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password@123"
  }'
```

### Get Me (with token)
```bash
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer <accessToken>"
```

### Refresh Token
```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

### Logout
```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

---

## 🔍 Response Format Examples

### Success Response (Login)
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "testuser",
      "email": "test@example.com",
      "role_id": 1
    }
  },
  "meta": {
    "timestamp": "2024-05-08T10:30:00.000Z"
  }
}
```

### Error Response (Invalid Password)
```json
{
  "status": "error",
  "code": 401,
  "message": "Invalid email or password",
  "errorCode": null,
  "details": ["Password is incorrect"],
  "timestamp": "2024-05-08T10:30:00.000Z"
}
```

---

## ✅ Definition of Done - Phase B

- [x] Auth Service v1 với JWT + Refresh token ✅
- [x] Auth Controller v1 ✅
- [x] Auth Router v1 với Swagger decorators ✅
- [x] 5 endpoints được tài liệu hóa ✅
- [x] Registered trong main API router ✅
- [x] Response format chuẩn ✅
- [x] Error handling đầy đủ ✅

---

## 🎯 Bước tiếp theo - Phase C (Optional)

### Option 1: Test Phase B ngay
→ Chạy tests trên Swagger UI
→ Xác nhận all 5 endpoints hoạt động

### Option 2: Chuyển sang Phase C (Test/Course APIs)
→ Migrate `/api/v1/tests`, `/api/v1/courses` endpoints
→ Tương tự cách làm Phase B

### Option 3: Setup Refresh Token persistence
→ Move refresh tokens từ memory Map sang Redis
→ Hoặc lưu vào DB column trong User model

---

## 📝 Lưu ý

### ⚠️ Temporary Refresh Token Store
Hiện tại refresh tokens được lưu trong memory Map:
```javascript
const refreshTokenStore = new Map();
```

**Vấn đề:**
- Token bị mất nếu server restart
- Không scale được trên multi-server

**Giải pháp cho Production:**
1. Lưu vào Redis cache
2. Hoặc add `refresh_tokens` table trong DB
3. Hoặc store refresh token hash vào column `User.refreshTokens`

---

## 🔐 Security Notes

✅ **JWT tokens được sinh với:**
- User ID + Email + Username + Role
- Expiration time từ .env
- Signed với SECRET_KEY

✅ **Password hashing:**
- Bcrypt hash 10 rounds
- So sánh safe với bcrypt.compare()

⚠️ **Improvements cần thiết:**
- Implement rate limiting trên login endpoint
- Add email verification (OTP) cho register
- Password reset flow
- Add refresh token rotation (invalidate old token khi refresh)

---

## 📊 Endpoints Summary

| Method | Endpoint | Auth | Status | Swagger |
|--------|----------|------|--------|---------|
| POST | /api/v1/auth/register | ❌ | ✅ | ✅ Full |
| POST | /api/v1/auth/login | ❌ | ✅ | ✅ Full |
| POST | /api/v1/auth/refresh | ❌ | ✅ | ✅ Full |
| POST | /api/v1/auth/logout | ❌ | ✅ | ✅ Full |
| GET | /api/v1/auth/me | ✅ Bearer | ✅ | ✅ Full |

---

**Phase B hoàn thành! 🎉**

Tất cả 5 auth endpoints v1 đã sẵn sàng với:
- Full Swagger documentation
- Chuẩn JWT + Refresh token
- Error handling
- Standard response format

Tiếp theo: Test trên Swagger UI hoặc chuyển Phase C! 🚀
