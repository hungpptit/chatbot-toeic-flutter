# Test Report — Chatbot TOEIC Backend
## Backend API Testing Documentation

---

**Project:** Chatbot TOEIC — Intelligent TOEIC Learning Platform
**Branch:** SWE_BE3
**Test Date:** August 2026
**Tester Role:** Software Engineer & Backend Developer
**Environment:** Local (Docker Compose), `http://localhost:8080/api`

---

## 1. Testing Strategy Overview

This document covers manual API testing performed against the running backend via **Swagger UI** and **Postman/curl**. Tests validate functional correctness, authentication enforcement, error handling, and business logic.

### Testing Levels Applied

| Level | Method | Coverage |
|---|---|---|
| **API Integration Testing** | Swagger UI + curl | All endpoints in all services |
| **Authentication Testing** | Manual | JWT enforcement, role guards |
| **Business Logic Testing** | Manual | Scoring, VIP gating, payment flow |
| **Error Handling Testing** | Manual | 400/401/403/404/409/429 responses |
| **Security Testing** | Manual | CORS, rate limiting, HMAC validation |

### Test Environment Setup

```bash
# 1. Start all services
cd chatbot-toeic-backend/docker
docker compose up -d --build

# 2. Verify all containers are up
docker compose ps

# Expected output:
# api_gateway          running   0.0.0.0:8080->8080/tcp
# auth_service         running
# quiz_service         running
# chatbot_service      running
# payment_service      running
# ml_python_service    running   0.0.0.0:5000->5000/tcp
# mssql_db             running   0.0.0.0:1433->1433/tcp
# rabbitmq_queue       running   0.0.0.0:5672->5672/tcp
# email_worker_service running

# 3. Open Swagger UI
# http://localhost:8080/api/docs
```

---

## 2. Test Accounts

| Account | Email | Password | Role |
|---|---|---|---|
| Admin | admin@test.com | Admin@123 | Admin (role_id=1) |
| Regular User | user@test.com | User@123 | User (role_id=2) |
| VIP User | vip@test.com | Vip@123 | User (VIP active) |

---

## 3. Authentication API Tests

### TC-AUTH-001: User Registration — Success

**Endpoint:** `POST /api/v1/auth/register`
**Precondition:** Email `newuser@test.com` does not exist in DB

**Request:**
```json
{
  "username": "testuser",
  "email": "newuser@test.com",
  "password": "Password@123"
}
```

**Expected Response — 201:**
```json
{
  "code": 201,
  "message": "User registered successfully",
  "data": {
    "id": 10,
    "username": "testuser",
    "email": "newuser@test.com"
  }
}
```

**Result:** PASS
**Notes:** User appears in DB `ChatbotToeic_Auth.Users` table with hashed password.

---

### TC-AUTH-002: User Registration — Duplicate Email

**Endpoint:** `POST /api/v1/auth/register`
**Request:** Same email as TC-AUTH-001

**Expected Response — 409:**
```json
{
  "code": 409,
  "message": "Email already exists"
}
```

**Result:** PASS

---

### TC-AUTH-003: Login — Success

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "newuser@test.com",
  "password": "Password@123"
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 10,
      "username": "testuser",
      "email": "newuser@test.com",
      "role_id": 2
    }
  }
}
```

**Result:** PASS
**Validation:** JWT decoded and verified — payload contains correct user id and role.

---

### TC-AUTH-004: Login — Wrong Password

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "newuser@test.com",
  "password": "WrongPassword"
}
```

**Expected Response — 401:**
```json
{
  "code": 401,
  "message": "Invalid credentials"
}
```

**Result:** PASS

---

### TC-AUTH-005: Get Current User (/me) — With Valid Token

**Endpoint:** `GET /api/v1/auth/me`
**Header:** `Authorization: Bearer <valid_access_token>`

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "id": 10,
    "username": "testuser",
    "email": "newuser@test.com",
    "role_id": 2,
    "isVip": false
  }
}
```

**Result:** PASS

---

### TC-AUTH-006: Get Current User (/me) — Without Token

**Endpoint:** `GET /api/v1/auth/me`
**Header:** (none)

**Expected Response — 401:**
```json
{
  "code": 401,
  "message": "Access token required"
}
```

**Result:** PASS

---

### TC-AUTH-007: Token Refresh — Valid Refresh Token

**Endpoint:** `POST /api/v1/auth/refresh`

**Request:**
```json
{
  "refreshToken": "<refresh_token_from_login>"
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Result:** PASS
**Validation:** New access token is different from the original. Original token is still valid until expiry.

---

### TC-AUTH-008: Token Refresh — Invalid Refresh Token

**Endpoint:** `POST /api/v1/auth/refresh`

**Request:**
```json
{
  "refreshToken": "invalid_token_string"
}
```

**Expected Response — 401:**
```json
{
  "code": 401,
  "message": "Invalid refresh token"
}
```

**Result:** PASS

---

### TC-AUTH-009: Password Reset Flow

**Step 1** — `POST /api/v1/auth/password/forgot`
```json
{ "email": "newuser@test.com" }
```
**Result:** 200 OK. Email with OTP received in Gmail.

**Step 2** — `POST /api/v1/auth/password/reset`
```json
{
  "email": "newuser@test.com",
  "otp": "482931",
  "newPassword": "NewPassword@456"
}
```
**Result:** 200 OK. Login with new password succeeds. Login with old password fails (401).

**Overall Result:** PASS

---

### TC-AUTH-010: Change Password — Incorrect Current Password

**Endpoint:** `PUT /api/v1/auth/password`
**Auth:** Valid token

**Request:**
```json
{
  "currentPassword": "WrongOldPassword",
  "newPassword": "NewPassword@789"
}
```

**Expected Response — 400:**
```json
{
  "code": 400,
  "message": "Current password is incorrect"
}
```

**Result:** PASS

---

### TC-AUTH-011: Rate Limiting on Auth Endpoints

**Test:** Send 21 login requests in quick succession from the same IP.

**Expected:** After 20 requests, the 21st returns:
```json
{
  "code": 429,
  "message": "Too many requests, please try again later."
}
```

**Result:** PASS (rate limiter triggers at request 21)

---

## 4. Test (TOEIC) API Tests

### TC-TEST-001: Get Test List — Authenticated

**Endpoint:** `GET /api/v1/tests?page=1&limit=5`
**Auth:** Valid user token

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "tests": [ { "id": 1, "title": "TOEIC Practice Test #1", ... } ],
    "pagination": { "totalItems": 12, "totalPages": 3, "currentPage": 1 }
  }
}
```

**Result:** PASS
**Validation:** Pagination metadata is correct. `totalPages = ceil(totalItems / limit)`.

---

### TC-TEST-002: Get Test List — Unauthenticated

**Endpoint:** `GET /api/v1/tests`
**Auth:** None

**Expected Response — 401**

**Result:** PASS

---

### TC-TEST-003: Get Test Questions

**Endpoint:** `GET /api/v1/tests/1/questions`
**Auth:** Valid user token

**Expected Response — 200:** Returns array of questions with `id`, `content`, `options`, `audioUrl`, `imageUrl`, `partId`.

**Result:** PASS
**Validation:** Correct answers (`correctAnswer` field) are NOT returned to the user in this response — only after submission.

---

### TC-TEST-004: Start Test Attempt

**Endpoint:** `POST /api/v1/tests/1/attempts`
**Auth:** Valid user token

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "attemptId": 55,
    "testId": 1,
    "status": "in_progress",
    "startedAt": "2026-08-23T09:00:00.000Z"
  }
}
```

**Result:** PASS
**DB Validation:** `TestAttempts` table shows new record with `status=in_progress`.

---

### TC-TEST-005: Submit Test Attempt — Full Scoring

**Endpoint:** `PATCH /api/v1/tests/1/attempts/55`
**Auth:** Valid user token

**Request:**
```json
{
  "status": "completed",
  "answers": {
    "101": "B",
    "102": "A",
    "103": "C",
    "104": "D"
  },
  "timeSpent": 1800
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "attemptId": 55,
    "score": 495,
    "listeningScore": 250,
    "readingScore": 245,
    "totalCorrect": 3,
    "totalQuestions": 4
  }
}
```

**Result:** PASS
**Scoring Validation:**
- Answers "101": "B" = correct (B is correct answer) -> +1
- Answers "102": "A" = correct -> +1
- Answers "103": "C" = incorrect (D is correct) -> 0
- Answers "104": "D" = correct -> +1
- Total = 3/4 correct -> score calculated accordingly

---

### TC-TEST-006: Get Attempt Result (Review Mode)

**Endpoint:** `GET /api/v1/test-attempts/55/result`
**Auth:** Valid user token

**Expected Response — 200:** Returns full question list with `userAnswer`, `correctAnswer`, `isCorrect`, `explanation`.

**Result:** PASS
**Validation:** `correctAnswer` field is now visible (post-submission). `isCorrect` matches manual calculation.

---

### TC-TEST-007: Submit Practice Attempt

**Endpoint:** `POST /api/v1/practice-attempts`
**Auth:** Valid user token

**Request:**
```json
{
  "questionId": 101,
  "selectedAnswer": "B"
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "isCorrect": true,
    "correctAnswer": "B",
    "explanation": "The woman is clearly holding a book."
  }
}
```

**Result:** PASS

---

### TC-TEST-008: Admin Creates a Test (Non-Admin User)

**Endpoint:** `POST /api/admin-tests`
**Auth:** Regular user token (role_id=2)

**Expected Response — 403:**
```json
{
  "code": 403,
  "message": "Admin access required"
}
```

**Result:** PASS

---

### TC-TEST-009: Admin Creates a Test (Admin User)

**Endpoint:** `POST /api/admin-tests`
**Auth:** Admin token

**Request:**
```json
{
  "title": "Test TC-009",
  "courseId": 1,
  "duration": "30 minutes",
  "questions": [
    {
      "content": "What is the speaker doing?",
      "partId": 1,
      "correctAnswer": "A",
      "options": { "A": "Reading", "B": "Eating", "C": "Sleeping", "D": "Running" },
      "explanation": "The audio indicates reading sounds."
    }
  ]
}
```

**Expected Response — 201:**
```json
{
  "code": 201,
  "message": "Test created successfully",
  "data": { "testId": 20, "questionCount": 1 }
}
```

**Result:** PASS
**DB Validation:** Test and Question records created. AI embedding generated in background.

---

## 5. Statistics API Tests

### TC-STATS-001: Get User Overall Statistics

**Endpoint:** `GET /api/v1/statistics/user-tests`
**Auth:** User token (with 2+ completed attempts)

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "totalTests": 5,
    "totalCompleted": 4,
    "averageScore": 620,
    "highestScore": 750
  }
}
```

**Result:** PASS

---

### TC-STATS-002: Get Part Statistics

**Endpoint:** `GET /api/v1/statistics/parts`
**Auth:** User token

**Expected Response — 200:** Array with per-part accuracy data.

**Result:** PASS
**Validation:** Sum of (correct/total) per part aligns with manually counted test submission answers.

---

### TC-STATS-003: Get Accuracy Over Time (30 days default)

**Endpoint:** `GET /api/v1/statistics/accuracy-over-time`
**Auth:** User token

**Expected Response — 200:** Time-series data for the past 30 days.

**Result:** PASS

---

### TC-STATS-004: Get Accuracy Over Time (Custom Range)

**Endpoint:** `GET /api/v1/statistics/accuracy-over-time?days=7`
**Auth:** User token

**Expected Response — 200:** Time-series data limited to past 7 days.

**Result:** PASS

---

## 6. Chatbot API Tests

### TC-CHAT-001: Create a New Conversation

**Endpoint:** `POST /api/v1/conversations`
**Auth:** Valid user token

**Request:**
```json
{
  "title": "Grammar Practice"
}
```

**Expected Response — 201:**
```json
{
  "code": 201,
  "data": { "id": 3, "title": "Grammar Practice" }
}
```

**Result:** PASS

---

### TC-CHAT-002: Send Message to AI Chatbot

**Endpoint:** `POST /api/v1/conversations/3/messages`
**Auth:** Valid user token

**Request:**
```json
{
  "rawText": "What is the difference between 'since' and 'for' in TOEIC Part 5?"
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "id": 15,
    "role": "model",
    "content": "'Since' is used with a specific point in time (e.g., 'since 2020'), while 'for' is used with a duration (e.g., 'for 5 years'). In TOEIC Part 5, you'll often see these tested with present perfect tense...",
    "createdAt": "2026-08-23T09:30:00.000Z"
  }
}
```

**Result:** PASS
**Validation:** Response is contextually relevant to the question. User message saved as `role=user`, AI response saved as `role=model`.

---

### TC-CHAT-003: VIP Limit Enforcement — Free User (15 messages/day)

**Test:** Send 16 messages in one day with a free-tier user account.

**Messages 1-15:** Each returns 200 with AI response.

**Message 16:**
**Expected Response — 429:**
```json
{
  "code": 429,
  "message": "Daily message limit reached. Upgrade to VIP for unlimited access.",
  "data": { "messagesUsed": 15, "limit": 15 }
}
```

**Result:** PASS
**Validation:** Message count resets at midnight (server time). Count is queried live from `Messages` table with today's date filter.

---

### TC-CHAT-004: VIP User — No Message Limit

**Test:** Send 20 messages with a VIP user account.

**All 20 responses:** 200 with AI response.

**Result:** PASS

---

### TC-CHAT-005: Get Conversation History

**Endpoint:** `GET /api/v1/conversations/3/messages`
**Auth:** Valid user token

**Expected Response — 200:** Returns all messages in chronological order (alternating user/model).

**Result:** PASS
**Validation:** Message count matches number of sends in TC-CHAT-002 + TC-CHAT-003.

---

### TC-CHAT-006: Delete Conversation

**Endpoint:** `DELETE /api/v1/conversations/3`
**Auth:** Valid user token

**Expected Response — 200:**
```json
{
  "code": 200,
  "message": "Conversation deleted"
}
```

**DB Validation:** Conversation and all associated messages removed.

**Result:** PASS

---

## 7. Payment API Tests

### TC-PAY-001: Get Subscription Plans

**Endpoint:** `GET /api/v1/payments/subscriptions`
**Auth:** None

**Expected Response — 200:** Returns array of available VIP plans with `id`, `name`, `price`, `duration`.

**Result:** PASS

---

### TC-PAY-002: Check VIP Status — Non-VIP User

**Endpoint:** `GET /api/v1/payments/vip-status`
**Auth:** Regular user token

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "isVip": false,
    "vipExpireAt": null,
    "daysRemaining": 0
  }
}
```

**Result:** PASS

---

### TC-PAY-003: Initialize ZaloPay Payment

**Endpoint:** `POST /api/v1/payments/create`
**Auth:** Valid user token

**Request:**
```json
{
  "subscriptionId": 1,
  "paymentGateway": "zalopay",
  "returnUrl": "https://localhost:8080/payment-result"
}
```

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "orderUrl": "https://sb-openapi.zalopay.vn/v2/...",
    "appTransId": "240823_10_1",
    "amount": 50000
  }
}
```

**Result:** PASS
**Validation:** Payment URL is valid. Navigating to `orderUrl` opens ZaloPay sandbox payment page.

---

### TC-PAY-004: ZaloPay Webhook — Valid Signature

**Test:** Simulate ZaloPay callback with correct HMAC-SHA256 signature.

**Endpoint:** `POST /api/v1/payments/zalopay-callback`

**Request:** (computed with correct KEY2)
```json
{
  "data": "{\"app_trans_id\":\"240823_10_1\",\"amount\":50000,\"embed_data\":\"{\\\"userId\\\":10,\\\"subscriptionId\\\":1}\"}",
  "mac": "<correct_hmac_signature>"
}
```

**Expected Response — 200:**
```json
{
  "return_code": 1,
  "return_message": "Success"
}
```

**Post-Conditions:**
- User 10 `isVip = true`
- User 10 `vipExpireAt = today + 30 days`

**Result:** PASS

---

### TC-PAY-005: ZaloPay Webhook — Invalid Signature

**Test:** Send callback with tampered `data` or wrong `mac`.

**Expected Response — 200:**
```json
{
  "return_code": -1,
  "return_message": "MAC validation failed"
}
```

**Post-Conditions:** User VIP status unchanged.

**Result:** PASS

---

### TC-PAY-006: VIP Cumulative Extension

**Precondition:** User has active VIP expiring in 10 days.

**Action:** Successfully complete another 30-day VIP payment.

**Expected Result:** `vipExpireAt` = (current expiry + 30 days), NOT (today + 30 days).

**Result:** PASS
**Validation:** Checked DB `Users` table — `vipExpireAt` extended correctly.

---

## 8. Media Upload API Tests

### TC-UPLOAD-001: Upload Image

**Endpoint:** `POST /api/v1/uploads/images`
**Auth:** Valid token
**Body:** `multipart/form-data`, field `file` = JPEG image (800x600, ~150KB)

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "url": "https://res.cloudinary.com/degzfp5hs/image/upload/v.../test_img.jpg",
    "publicId": "question_images/test_img"
  }
}
```

**Result:** PASS
**Validation:** URL is accessible in browser. Image visible on Cloudinary dashboard.

---

### TC-UPLOAD-002: Upload Audio

**Endpoint:** `POST /api/v1/uploads/audio`
**Auth:** Valid token
**Body:** `multipart/form-data`, field `file` = MP3 audio (~2MB, 45s)

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "url": "https://res.cloudinary.com/degzfp5hs/video/upload/v.../track.mp3",
    "publicId": "audio/track",
    "duration": 45.2
  }
}
```

**Result:** PASS
**Validation:** Audio URL playable. Duration correctly detected.

---

### TC-UPLOAD-003: Delete Media File

**Endpoint:** `DELETE /api/v1/uploads/question_images%2Ftest_img?resourceType=image`
**Auth:** Valid token

**Expected Response — 200:**
```json
{
  "code": 200,
  "message": "File deleted successfully"
}
```

**Validation:** Image no longer accessible at the previous URL. Cloudinary dashboard confirms deletion.

**Result:** PASS

---

## 9. ML Recommendation API Tests

### TC-ML-001: Get Recommendations

**Endpoint:** `GET /api/ml/recommend/:userId`
**Auth:** Valid token (user with 3+ completed tests)

**Expected Response — 200:**
```json
{
  "code": 200,
  "data": {
    "predictedScore": 680,
    "weakSkills": ["Conversations (Part 3)", "Text Completion (Part 6)"],
    "recommendedQuestionIds": [101, 205, 318]
  }
}
```

**Result:** PASS
**Validation:** Predicted score is reasonable given test history. Weak skills match parts where user has lowest accuracy.

---

### TC-ML-002: Get Recommendation Details

**Endpoint:** `GET /api/ml/recommend/details/:userId`
**Auth:** Valid token

**Expected Response — 200:** Same as TC-ML-001 but includes full question objects for recommended IDs.

**Result:** PASS

---

### TC-ML-003: Manual Retrain (Admin Only)

**Endpoint:** `POST /api/ml/retrain`
**Auth:** Admin token

**Expected Response — 200:**
```json
{
  "code": 200,
  "message": "Model retrain triggered"
}
```

**Result:** PASS
**Validation:** ML service logs show retraining process. New `.pkl` file timestamp updated.

---

## 10. Admin API Tests

### TC-ADMIN-001: List All Users

**Endpoint:** `GET /api/admin-users`
**Auth:** Admin token

**Expected Response — 200:** Array of all user objects.

**Result:** PASS

---

### TC-ADMIN-002: Lock User Account

**Endpoint:** `PATCH /api/admin-users/10`
**Auth:** Admin token

**Request:**
```json
{
  "status": false
}
```

**Expected Response — 200:** User updated with `status=false`.

**Post-Validation:** Attempt to login as user 10 returns `401: Account is locked`.

**Result:** PASS

---

### TC-ADMIN-003: Change User Role to Admin

**Endpoint:** `PATCH /api/admin-users/10`
**Auth:** Admin token

**Request:**
```json
{
  "role_id": 1
}
```

**Expected Response — 200:** User updated with `role_id=1`.

**Post-Validation:** User 10 can now access admin endpoints.

**Result:** PASS

---

### TC-ADMIN-004: Delete Test

**Endpoint:** `DELETE /api/admin-tests/20`
**Auth:** Admin token

**Expected Response — 200:**
```json
{
  "code": 200,
  "message": "Test deleted successfully"
}
```

**Post-Validation:** Test 20 no longer appears in `GET /api/v1/tests`. All linked `TestAttempts` also removed.

**Result:** PASS

---

## 11. Security Tests

### TC-SEC-001: CORS — Disallowed Origin

**Test:** Send request with `Origin: https://malicious-site.com` (not in CORS whitelist).

**Expected:** Request rejected with CORS error (browser blocks the response).

**Result:** PASS (verified via browser DevTools console)

---

### TC-SEC-002: JWT Tampering

**Test:** Modify the payload of a valid JWT (change `role_id` to 1) without resigning.

**Endpoint:** `GET /api/admin-users`
**Auth:** Tampered token

**Expected Response — 401:**
```json
{
  "code": 401,
  "message": "Invalid token"
}
```

**Result:** PASS

---

### TC-SEC-003: Admin Route with User Token

**Endpoint:** `POST /api/admin-tests`
**Auth:** Regular user token (role_id=2)

**Expected Response — 403:**
```json
{
  "code": 403,
  "message": "Admin access required"
}
```

**Result:** PASS

---

### TC-SEC-004: API Rate Limiting — General Endpoints

**Test:** Send 201 requests in 15 minutes to `GET /api/v1/tests`.

**Expected:** 201st request returns HTTP 429.

**Result:** PASS

---

### TC-SEC-005: ZaloPay Webhook Signature Replay Attack

**Test:** Replay a previously valid ZaloPay callback with the same `data` and `mac`.

**Expected Result:** VIP not duplicated. The payment service checks for duplicate `appTransId` in the `Transactions` table and returns `return_code: 0` (already processed).

**Result:** PASS

---

## 12. Test Summary

### Results Overview

| Category | Total Tests | Passed | Failed | Pass Rate |
|---|---|---|---|---|
| Authentication | 11 | 11 | 0 | 100% |
| TOEIC Test Engine | 9 | 9 | 0 | 100% |
| Statistics | 4 | 4 | 0 | 100% |
| Chatbot | 6 | 6 | 0 | 100% |
| Payment | 6 | 6 | 0 | 100% |
| Media Upload | 3 | 3 | 0 | 100% |
| ML Recommendation | 3 | 3 | 0 | 100% |
| Admin | 4 | 4 | 0 | 100% |
| Security | 5 | 5 | 0 | 100% |
| **TOTAL** | **51** | **51** | **0** | **100%** |

---

## 13. Known Limitations and Defects

| ID | Description | Severity | Status |
|---|---|---|---|
| BUG-001 | `depends_on` in Compose does not wait for MSSQL to be fully ready — requires manual restart on first boot | Medium | Workaround documented |
| BUG-002 | ZaloPay callback URL requires a public HTTPS endpoint; local testing requires ngrok | Low | Documented |
| BUG-003 | Batch upload path on Docker for paths outside the mounted volume returns 404 without clear error message | Low | Workaround: mount correct path in Compose |
| LIMIT-001 | No automated test suite (Jest/Supertest); all testing is manual | High | Planned for v2.1 |
| LIMIT-002 | ML model accuracy depends on volume of training data; small dataset reduces precision | Medium | Improves automatically as users increase |
| LIMIT-003 | Gemini API latency (~1-3 seconds) affects chatbot response time | Low | Acceptable for chat UX |

---

## 14. Test Environment Details

| Parameter | Value |
|---|---|
| OS | Windows 11 (host) / Alpine Linux (Docker containers) |
| Docker Engine | 24.x |
| Node.js | 20.x (inside containers) |
| SQL Server | 2022 (Microsoft image) |
| Test Tool | Swagger UI, Postman, curl |
| API Base URL | `http://localhost:8080/api` |
| Swagger UI | `http://localhost:8080/api/docs` |

---

## 15. Recommendations for Future Testing

1. **Automated Unit Tests**: Implement Jest test suites for all service controllers and utility functions.
2. **Integration Test Suite**: Use Supertest to run automated API tests against a test database.
3. **Load Testing**: Use k6 or Apache JMeter to benchmark API throughput under concurrent users.
4. **E2E Testing**: Implement Playwright or Cypress tests for the Flutter Web frontend.
5. **Security Scanning**: Run OWASP ZAP or Snyk against the API for vulnerability scanning.
6. **CI/CD Pipeline**: Integrate automated tests into a GitHub Actions pipeline on every push.

---

**Report prepared by:** Pham Tuan Hung
**Role:** Software Engineer & Backend Developer
**Date:** August 2026
