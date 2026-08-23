# Project Report — Chatbot TOEIC
## Intelligent TOEIC Learning Platform with Microservices Architecture

---

**Project Name:** Chatbot TOEIC — Intelligent TOEIC Learning Platform
**Version:** 2.0.0 (SWE_BE3 Branch)
**Report Date:** August 2026
**Author Role:** Software Engineer & Backend Developer
**Repository:** `SWE_BE3` branch — chatbot-toeic-flutter
**Contact:** phamtuanhung9a5@gmail.com

---

## 1. Executive Summary

Chatbot TOEIC is a full-stack, production-grade TOEIC preparation platform built using a **microservices architecture**. The system provides users with an end-to-end learning experience: taking TOEIC tests, practicing with individual questions, learning via an AI-powered chatbot, tracking progress through analytics dashboards, and predicting their TOEIC scores using Machine Learning.

The backend is composed of **5 independently deployable microservices** orchestrated with **Docker Compose**, fronted by an **Nginx API Gateway**, and backed by **Microsoft SQL Server 2022**. The frontend is a **cross-platform Flutter application** targeting Android, iOS, and Web from a single codebase.

This report documents the system's architecture, technical decisions, features implemented, challenges encountered, and future improvements. It is intended for technical reviewers evaluating the author's capabilities as a **Software Engineer** and **Backend Developer**.

---

## 2. Project Objectives

| Objective | Status |
|---|---|
| Design and implement a scalable microservices backend | Completed |
| Build a RESTful API conforming to industry standards | Completed |
| Integrate Google Gemini AI for conversational chatbot | Completed |
| Implement Machine Learning for TOEIC score prediction | Completed |
| Integrate ZaloPay payment gateway with webhook security | Completed |
| Deploy all services via Docker Compose with Nginx gateway | Completed |
| Build cross-platform Flutter frontend | Completed |
| Implement JWT authentication with OAuth 2.0 | Completed |
| Generate interactive API documentation (Swagger UI) | Completed |

---

## 3. System Architecture

### 3.1 Architecture Pattern: Microservices

The project deliberately avoids a monolithic design in favor of microservices for the following reasons:
- **Independent deployment**: Each service can be updated, scaled, or restarted without affecting others.
- **Technology isolation**: The ML service uses Python/Flask independently of the Node.js services.
- **Fault isolation**: A failure in the email or chatbot service does not bring down the test or auth system.
- **Database-per-Service**: Each service owns its SQL Server database, preventing tight coupling at the data layer.

### 3.2 Service Decomposition

| Service | Technology | Database | Responsibilities |
|---|---|---|---|
| **auth-service** | Node.js 20 + Express 5 | `ChatbotToeic_Auth` | Registration, login, JWT, OAuth, OTP, user management |
| **quiz-service** | Node.js 20 + Express 5 | `ChatbotToeic_Quiz` | Tests, questions, courses, scoring, statistics, file upload, ML cron |
| **chatbot-service** | Node.js 20 + Express 5 | `ChatbotToeic_Chatbot` | Conversations, messages, Gemini AI integration, VIP gating |
| **payment-service** | Node.js 20 + Express 5 | `ChatbotToeic_Payment` | Subscriptions, ZaloPay checkout, webhook handling, VIP activation |
| **email-service** | Node.js + Nodemailer | (none) | RabbitMQ consumer for async email delivery |
| **ml-service** | Python 3.11 + Flask | `ChatbotToeic_Quiz` | TOEIC score prediction, weak skill analysis, model retraining |
| **api-gateway** | Nginx Alpine | (none) | Reverse proxy, routing, security headers |

### 3.3 Communication Patterns

| Pattern | Used For | Technology |
|---|---|---|
| **Synchronous REST** | Client -> Gateway -> Service | HTTP/JSON |
| **Synchronous REST (internal)** | Service-to-service (e.g., payment -> auth to update VIP) | HTTP/JSON |
| **Asynchronous Messaging** | Triggering email notifications (OTP, payment confirmation) | RabbitMQ (AMQP) |

### 3.4 Infrastructure Diagram

```
+-----------------------------------------------------------+
|                Docker Compose Network                      |
|                                                           |
|  +------------------+    +---------------------------+   |
|  |   Nginx Gateway  |    |   SQL Server 2022         |   |
|  |    port 8080     |    |  - ChatbotToeic_Auth      |   |
|  +--------+---------+    |  - ChatbotToeic_Quiz      |   |
|           |              |  - ChatbotToeic_Payment   |   |
|    +------+------+       |  - ChatbotToeic_Chatbot   |   |
|    |      |      |       +---------------------------+   |
|    v      v      v                                       |
|  auth   quiz  chatbot   +---------------------------+   |
|  svc    svc    svc      |        RabbitMQ           |   |
|    |      |      |      |  - email.queue            |   |
|  payment email   ml     +---------------------------+   |
|    svc   svc    svc                                      |
+-----------------------------------------------------------+
              |
     Flutter App (Android/iOS/Web)
```

---

## 4. Backend Implementation Details

### 4.1 Authentication System

**Design:** Stateless JWT authentication using dual-token strategy.

- **Access Token**: Short-lived (7 days), signed with `JWT_SECRET_KEY`, used for all API calls.
- **Refresh Token**: Long-lived (30 days), stored in the database (`RefreshTokens` table), used only to issue new access tokens.
- **Token Rotation**: On refresh, the old refresh token is invalidated and a new one is issued.

**Middleware Stack (`authMiddleware`):**
1. Extract `Authorization: Bearer <token>` header
2. Verify JWT signature and expiry
3. Attach `req.user` (decoded payload) for downstream controllers
4. Return `401` if token is missing, invalid, or expired

**OTP Flow for Registration:**
1. User calls `/api/v1/auth/register/send-otp` with email
2. System generates a 6-digit OTP, stores it with a 10-minute TTL, sends via RabbitMQ -> email-service
3. User calls `/api/v1/auth/register/verify-otp` to confirm
4. User calls `/api/v1/auth/register` to complete account creation

**Google OAuth:**
- Frontend sends Google `idToken` from Google Sign-In SDK
- Backend verifies the token with Google's public keys via `google-auth-library`
- Auto-registers if email is new, or logs in existing account

### 4.2 TOEIC Test Engine

**Test Lifecycle:**
```
GET /tests           -> browse available tests
GET /tests/:id/questions -> load test questions
POST /tests/:id/attempts  -> start attempt (creates DB record, status=in_progress)
PATCH /tests/:id/attempts/:attemptId (status=completed, answers, timeSpent)
                     -> score calculation + store results
GET /test-attempts/:attemptId/result -> review with correct answers
```

**Scoring Algorithm:**
- Compare each submitted answer against `correctAnswer` in the database
- Aggregate correct answers per part
- Map part scores to TOEIC-scaled scores using a lookup table (approximated from official TOEIC score conversion)
- Store `listeningScore`, `readingScore`, and total `score` in `TestAttempts`

**Test Formats Supported:**
| Format | Parts | Description |
|---|---|---|
| Full TOEIC | Parts 1-7 | Complete 200-question test |
| Listening Only | Parts 1-4 | 100 listening questions |
| Reading Only | Parts 5-7 | 100 reading questions |
| Mixed | Any combination | Custom subset |
| Practice | Single question | One-question practice mode |

### 4.3 AI Chatbot Integration

**Technology:** Google Gemini 2.5 Flash (REST API, not SDK)

**Implementation:**
1. User sends `rawText` to `/api/v1/conversations/:id/messages`
2. Middleware fetches conversation history from DB (all prior messages)
3. History is formatted in Gemini's `contents` array format (alternating user/model roles)
4. Request is sent to Gemini API with a system prompt tuned for TOEIC coaching
5. Response is saved to DB as `role=model` message
6. Response is returned to client

**VIP Gating Logic (`vipCheckMiddleware`):**
```
1. Call internal endpoint: GET /api/v1/internal/users/:userId
2. If isVip=true and vipExpireAt > now -> allow through
3. If free user: count today's messages from chatbot-service DB
4. If count >= 15 -> return 429 with remaining count
5. Otherwise -> allow through
```

**API Key Rotation:**
- `GEMINI_API_KEYS` accepts comma-separated keys
- System cycles through keys on each request (round-robin) to distribute rate limits

### 4.4 Machine Learning Service

**Architecture:** Standalone Python Flask microservice (`ml-service`) connected to `ChatbotToeic_Quiz` database.

**Model:** Unified scikit-learn model (`train_unified_model.py`) using:
- `RandomForestRegressor` for score prediction
- Feature engineering: per-part accuracy, attempt count, time efficiency, score trend

**Features Used for Prediction:**
| Feature | Description |
|---|---|
| `part1_accuracy` to `part7_accuracy` | Correct/total per TOEIC part |
| `avg_time_per_question` | Average seconds spent per question |
| `total_attempts` | Number of tests completed |
| `score_trend` | Linear regression slope of recent scores |
| `days_since_start` | Days since first test attempt |

**Auto-Retrain Flow:**
- `mlRetrainCron.js` in quiz-service runs daily at 2:00 AM
- Calls ML service `/retrain` endpoint
- ML service fetches latest attempt data from `ChatbotToeic_Quiz`
- Retrains model and saves new `.pkl` artifact

**Hybrid Prediction (`predict_hybrid_unified.py`):**
- Combines collaborative filtering similarity with the trained ML model
- Uses pre-generated question embeddings to identify similar users' weak areas

### 4.5 Payment Integration (ZaloPay)

**Flow:**
```
User clicks "Buy VIP"
  -> POST /api/v1/payments/create (subscriptionId, paymentGateway=zalopay)
  -> payment-service creates order with ZaloPay API (HMAC-SHA256 signed)
  -> Returns ZaloPay payment URL
  -> User completes payment on ZaloPay
  -> ZaloPay POSTs to callback URL
  -> payment-service validates HMAC signature
  -> PATCH /api/v1/internal/users/:id {isVip: true, vipExpireAt: ...}
  -> auth-service updates user record
```

**Security:**
- All ZaloPay requests are signed with `HMAC-SHA256(KEY1, data)`
- Callback payloads are verified by recomputing MAC and comparing with received MAC
- Invalid MAC -> `return_code: -1` (payment not credited)

**VIP Expiry Logic:**
```javascript
if (user.isVip && user.vipExpireAt > now) {
  // Extend from current expiry (cumulative)
  newExpiry = user.vipExpireAt + subscriptionDays
} else {
  // Start from today
  newExpiry = today + subscriptionDays
}
```

### 4.6 Media Management (Cloudinary)

**Upload Pipeline:**
1. Client sends `multipart/form-data` to `/api/v1/uploads/images` or `/api/v1/uploads/audio`
2. Multer buffers the file in memory (no disk writes)
3. Cloudinary SDK uploads the buffer
4. Cloudinary returns a secure URL and `publicId`
5. URL is stored in the question/entity record

**Batch Upload (Admin):**
- Admin provides local file paths in JSON payload
- Server resolves Windows/Linux path differences (Docker volume mount at `/mnt/d/`)
- Reads files from disk and uploads to Cloudinary sequentially
- Returns mapping of original paths to Cloudinary URLs

### 4.7 API Design Principles

All v1 APIs follow REST conventions:
- **Nouns for resources**: `/tests`, `/conversations`, `/users`
- **HTTP verbs for actions**: `GET` (read), `POST` (create), `PUT/PATCH` (update), `DELETE` (delete)
- **Consistent response envelope**: `{ code, message, data }`
- **Versioning via path**: `/api/v1/...`
- **Pagination**: `page` + `limit` query params with `pagination` metadata in response
- **Backward compatibility**: Legacy routes preserved alongside v1 routes (e.g., `/api/adminUser` -> `/api/admin-users`)

---

## 5. Security Implementation

### 5.1 Rate Limiting

```javascript
// Auth endpoints (stricter)
authLimiter: 20 requests per 15 minutes per IP

// All other API endpoints
apiLimiter: 200 requests per 15 minutes per IP
```

### 5.2 CORS Policy

```javascript
// Dynamic origin validation:
// - Allow all localhost:* origins (for development)
// - Allow whitelisted production origins from CORS_ORIGINS env var
// - Reject all others with 403
```

### 5.3 Input Validation

- Request body validation using custom validators before controller execution
- SQL injection prevention via Sequelize ORM parameterized queries
- Path traversal protection for local file preview endpoint

### 5.4 Nginx Security Headers

```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
add_header X-Content-Type-Options "nosniff";
client_max_body_size 50M;
```

---

## 6. DevOps and Infrastructure

### 6.1 Docker Compose Setup

All 9 services (including DB and queue) are defined in a single `docker-compose.yml`:
- Services declare `depends_on` relationships for startup ordering
- `restart: always` ensures services recover from crashes automatically
- Environment variables injected from `.env` file (secrets never hardcoded in Compose)
- Shared `mssql_data` Docker volume for database persistence
- MSSQL init script (`import-data.sh`) auto-runs to seed database schema on first boot

### 6.2 Nginx API Gateway Configuration

```nginx
# Route /api/v1/auth     -> auth-service:8081
# Route /api/v1/tests    -> quiz-service:8082
# Route /api/v1/conversations -> chatbot-service:8084
# Route /api/v1/payments -> payment-service:8083
# Route /api/ml          -> quiz-service:8082 (ML proxy)
# Route /api/docs        -> quiz-service:8082 (Swagger UI)
```

### 6.3 Health Checks

All services expose a `GET /health` endpoint:
```json
{ "status": "healthy", "service": "quiz-service", "timestamp": "..." }
```

Nginx gateway also has its own health check at `/health`.

### 6.4 Cron Jobs

| Job | Schedule | Service | Description |
|---|---|---|---|
| ML Retrain | Daily 2:00 AM | quiz-service | Retrains prediction model on new data |
| Embedding Generation | Hourly | quiz-service | Generates vector embeddings for new questions |
| VIP Reset | Daily midnight | auth-service | Expires outdated VIP statuses |

---

## 7. Technical Challenges and Solutions

### Challenge 1: SQL Server Startup Race Condition
**Problem:** Node.js services started before MSSQL was ready, causing connection failures.
**Solution:** Implemented `wait-for-db.sh` startup script + `restart: always` in Compose. Services auto-reconnect on startup.

### Challenge 2: Cross-Service VIP Check in Chatbot
**Problem:** The chatbot-service has no direct access to the auth database.
**Solution:** Chatbot-service calls `GET /api/v1/internal/users/:id` on auth-service before each AI request to check VIP status. Internal endpoints are only accessible within the Docker network.

### Challenge 3: ZaloPay Callback in Local Development
**Problem:** ZaloPay needs a public HTTPS URL for the webhook callback.
**Solution:** Used `ngrok` to tunnel `localhost:8080` to a public URL. Documented this in troubleshooting guide.

### Challenge 4: Windows Path vs. Docker Linux Path for Batch Upload
**Problem:** Admin uploads specify Windows paths (e.g., `D:/Downloads/audio.mp3`) but the service runs inside a Linux Docker container.
**Solution:** Mapped the Windows drive into the container via Docker volume (`D:/Downloads:/mnt/d/Downloads`) and added path conversion logic in the batch upload controller.

### Challenge 5: Gemini API Rate Limits
**Problem:** A single Gemini API key has request rate limits that could block heavy users.
**Solution:** Implemented round-robin rotation across multiple API keys specified in `GEMINI_API_KEYS` (comma-separated).

### Challenge 6: ML Model Cold Start
**Problem:** On first deploy, no training data exists for the ML model.
**Solution:** Seeded a small dataset via the DB init script and pre-trained a default model. The model auto-retrains as real user data accumulates.

---

## 8. Performance Considerations

- **Database indexing**: Key query fields (`userId`, `testId`, `status`, `createdAt`) are indexed in Sequelize models.
- **Pagination**: All list endpoints implement cursor/offset pagination to prevent full table scans on large datasets.
- **Async email**: Email sending is delegated to a RabbitMQ queue, ensuring API responses are not blocked by SMTP latency.
- **Nginx keep-alive**: `keepalive_timeout 65` reduces TCP handshake overhead for repeated client requests.
- **Stateless JWT**: Avoids session store lookups; token validation is a pure in-memory cryptographic operation.

---

## 9. API Documentation

The API is documented using **Swagger/OpenAPI 3** annotations directly in the route files (`*.router.js`). The Swagger spec is auto-generated on service startup and served via Swagger UI at:

```
http://localhost:8080/api/docs
```

The raw OpenAPI JSON spec is available at:
```
http://localhost:8080/api/docs-json
```

This JSON can be imported into **Postman**, **Insomnia**, or any other API client.

---

## 10. Project Statistics

| Metric | Value |
|---|---|
| Total backend services | 5 Node.js + 1 Python + 1 Nginx |
| Total API endpoints | ~55 REST endpoints |
| API versioning | v1 (with legacy backward-compatible aliases) |
| Languages used | JavaScript (Node.js), Python, Dart (Flutter) |
| Database tables | ~20+ across 4 databases |
| Docker containers | 9 total |
| Lines of backend code | ~8,000+ (estimated) |
| Test coverage | Manual + Integration (via Swagger UI) |

---

## 11. Technology Decisions Rationale

| Decision | Rationale |
|---|---|
| **Node.js + Express 5** | Non-blocking I/O ideal for API-heavy workloads; Express 5 adds async error handling |
| **SQL Server (MSSQL)** | Project requirement; Sequelize ORM provides cross-DB portability |
| **Microservices** | Separation of concerns, independent deployment, fault isolation |
| **Nginx as Gateway** | Lightweight, battle-tested, handles routing without additional code |
| **RabbitMQ for Email** | Decouples email delivery from API response time; retryable, auditable |
| **Python Flask for ML** | scikit-learn ecosystem; Python is the de facto language for ML |
| **JWT (stateless)** | Scales horizontally without shared session store |
| **Cloudinary** | Managed CDN for media; handles format optimization, bandwidth |
| **Docker Compose** | One-command startup for all 9 services; reproducible environment |
| **ZaloPay** | Vietnamese payment gateway; supports local payment methods |

---

## 12. Future Improvements

| Priority | Improvement |
|---|---|
| High | Add comprehensive unit and integration tests (Jest, Supertest) |
| High | Implement HTTPS/TLS at Nginx layer for production readiness |
| High | Centralized logging (Winston + ELK stack or Grafana Loki) |
| High | Centralized error tracking (Sentry) |
| Medium | Add Redis for caching hot data (test lists, user stats) |
| Medium | Implement API versioning strategy for v2 endpoints |
| Medium | Add WebSocket support for real-time features (live chat, progress updates) |
| Medium | Kubernetes migration for production auto-scaling |
| Low | Add GraphQL layer alongside REST for flexible client queries |
| Low | Add comprehensive E2E tests with Cypress or Playwright |

---

## 13. Conclusion

This project demonstrates the design and implementation of a production-grade, full-stack application from the perspective of a Software Engineer and Backend Developer. Key strengths include:

1. **Architectural maturity**: Microservices pattern with proper service decomposition, database isolation, and inter-service communication patterns.
2. **Security**: JWT authentication, rate limiting, HMAC webhook validation, CORS policy, and security headers.
3. **Third-party integrations**: Google Gemini AI, ZaloPay payment gateway, Cloudinary media storage, Google OAuth.
4. **DevOps**: Full Docker containerization with Compose, Nginx API gateway, automated cron jobs, and health endpoints.
5. **Code quality**: Consistent response envelope, versioned APIs, backward compatibility, and inline Swagger documentation.
6. **Machine Learning**: End-to-end ML pipeline from data collection, model training, auto-retraining, to serving predictions via REST API.

The project is suitable for presentation in a **Software Engineer** or **Backend Developer** portfolio, demonstrating real-world skills in distributed systems, API design, security, database management, third-party integrations, and containerized deployment.

---

**Report prepared by:** Pham Tuan Hung
**Role:** Software Engineer & Backend Developer
**Date:** August 2026
