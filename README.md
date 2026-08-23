# Chatbot TOEIC — Intelligent TOEIC Learning Platform

[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-5.x-000000?logo=express)](https://expressjs.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![SQL Server](https://img.shields.io/badge/SQL_Server-2022-CC2927?logo=microsoftsqlserver)](https://www.microsoft.com/sql-server)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)](https://python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A production-ready, full-stack TOEIC preparation platform built with a **Microservices** architecture. Features AI-powered chatbot (Google Gemini), Machine Learning score prediction, ZaloPay payment integration, and a cross-platform Flutter mobile/web application.

---

## Table of Contents

- [System Architecture](#system-architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [API Overview](#api-overview)
- [Key Features](#key-features)
- [Services and Ports](#services-and-ports)
- [Database Design](#database-design)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributors](#contributors)

---

## System Architecture

The backend is fully containerized and orchestrated via **Docker Compose**, following a microservices pattern where each domain is an independent Node.js service behind an **Nginx API Gateway**.

```
                        +------------------------------------------+
Client (Flutter App) -->|    Nginx API Gateway (:8080)             |
                        +-------------------+----------------------+
                                            |  Route by path prefix
           +-----------+-----------+--------+---------+-----------+
           v           v           v                  v           v
      Auth Service  Quiz Service  Chatbot Service  Payment Svc  ML Service
        (:8081)       (:8082)       (:8084)          (:8083)    (:5000)
           |              |              |               |
           +------+-------+--------------+---------------+
                  |
     +------------+-------------+
     v            v             v
  MSSQL Auth   MSSQL Quiz   MSSQL Payment
     DB           DB            DB
                  |
           RabbitMQ Queue
                  |
          Email Worker Service
```

**Design Decisions:**
- Each microservice owns its own **isolated SQL Server database** (Database-per-Service pattern).
- Services communicate via **REST HTTP** (synchronous) and **RabbitMQ** (asynchronous, for email notifications).
- The **Nginx gateway** handles all routing, load balancing, and serves as a single ingress point for clients.
- **JWT-based authentication** is stateless; tokens are verified in each service independently using a shared secret.

---

## Technology Stack

### Backend (Microservices - Node.js)

| Technology | Version | Purpose |
|---|---|---|
| **Node.js** | 20 LTS | Runtime environment |
| **Express** | 5.x | HTTP server framework |
| **Sequelize** | 6.x | ORM for SQL Server |
| **SQL Server (MSSQL)** | 2022 | Relational database |
| **JWT** | - | Stateless authentication |
| **Bcrypt** | - | Password hashing |
| **Nginx** | Alpine | API Gateway and reverse proxy |
| **RabbitMQ** | 3 | Async message queue (email) |
| **Docker and Compose** | - | Containerization and orchestration |
| **Swagger (OpenAPI 3)** | - | API documentation |
| **Cloudinary** | - | Cloud media storage (images/audio) |
| **Multer** | - | Multipart file upload handling |
| **node-cron** | - | Scheduled jobs (ML retrain, VIP reset) |
| **express-rate-limit** | - | Rate limiting and DDoS protection |

### AI and Machine Learning

| Technology | Purpose |
|---|---|
| **Google Gemini 2.5 Flash** | Conversational AI chatbot |
| **Python 3.11 + Flask** | ML microservice runtime |
| **scikit-learn** | TOEIC score prediction model |
| **ONNX Runtime** | (Optional) model inference |
| **pandas / numpy** | Data processing for training |

### Frontend (Cross-platform Flutter)

| Technology | Purpose |
|---|---|
| **Flutter 3 + Dart** | Cross-platform UI (Android, iOS, Web) |
| **GetX** | State management and navigation |
| **Dio** | HTTP client with interceptors |
| **just_audio** | Audio playback for Listening section |
| **fl_chart** | Data visualization (charts/graphs) |
| **flutter_secure_storage** | Secure token storage |
| **Google Sign-In** | OAuth 2.0 authentication |

---

## Project Structure

```
chatbot-toeic-flutter/
|-- chatbot-toeic-backend/              # Backend (Microservices)
|   |-- docker/                         # Infrastructure
|   |   |-- docker-compose.yml          # Compose: all services + DB + queue
|   |   |-- nginx.conf                  # API Gateway routing config
|   |   `-- db-init/                    # MSSQL init scripts and seed data
|   |-- ml/                             # ML Prediction Microservice (Python Flask)
|   |   |-- app.py                      # Flask entrypoint
|   |   |-- train_unified_model.py      # Model training script
|   |   |-- predict_hybrid_unified.py   # Hybrid prediction logic
|   |   `-- model/                      # Trained .pkl/.onnx model artifacts
|   `-- services/                       # Node.js Microservices
|       |-- auth-service/               # Authentication and User Management (:8081)
|       |   `-- src/
|       |       |-- controllers/        # Request handlers
|       |       |-- services/           # Business logic layer
|       |       |-- models/             # Sequelize DB models
|       |       |-- routes/             # Express routers (RESTful v1 + legacy)
|       |       |-- Middleware/         # JWT auth, admin guard, rate limiter
|       |       `-- utils/              # Response helpers, validators
|       |-- quiz-service/               # TOEIC Tests, Courses and Statistics (:8082)
|       |   `-- src/
|       |       |-- controllers/        # Test, course, stats, upload controllers
|       |       |-- services/           # Scoring, embedding, ML integration
|       |       |-- cronJobs/           # ML retrain cron, embedding cron
|       |       `-- config/             # Swagger spec, Sequelize config
|       |-- chatbot-service/            # AI Chatbot (Gemini) (:8084)
|       |   `-- src/
|       |       |-- controllers/        # Conversation and message controllers
|       |       |-- Middleware/         # VIP check middleware
|       |       `-- services/           # Gemini API integration
|       |-- payment-service/            # ZaloPay Integration (:8083)
|       |   `-- src/
|       |       |-- controllers/        # Payment and subscription controllers
|       |       `-- services/           # ZaloPay HMAC validation, order creation
|       `-- email-service/              # Email Worker (RabbitMQ consumer)
|           `-- src/                    # Nodemailer + queue consumer
|
`-- chat_toeic_app/                     # Flutter Frontend
    |-- lib/
    |   |-- controllers/                # GetX state controllers
    |   |-- models/                     # Data models (Dart)
    |   |-- views/                      # Screens and widgets
    |   `-- services/                   # Dio API clients, secure storage
    `-- assets/                         # Fonts, images, env config
```

---

## Prerequisites

| Requirement | Minimum Version | Notes |
|---|---|---|
| **Docker Desktop** | Latest | Required for running backend |
| **Node.js** | 18+ | For local development only |
| **Flutter SDK** | 3.x | For running frontend |
| **RAM** | 8 GB | 16 GB recommended for Docker |
| **Disk Space** | 5 GB free | For Docker images + database |

---

## Quick Start

### 1. Clone the Repository

```bash
git clone -b SWE_BE3 https://github.com/hungpptit/chatbot-toeic-flutter.git
cd chatbot-toeic-flutter
```

### 2. Configure Environment Variables

```bash
cd chatbot-toeic-backend
cp .env.example .env
# Edit .env and fill in all required values
```

### 3. Start All Backend Services

```bash
cd chatbot-toeic-backend/docker
docker compose up -d --build
```

Wait ~2-3 minutes on first run for MSSQL to initialize.

### 4. Verify Services

```bash
docker compose ps
curl http://localhost:8080/health
# Open: http://localhost:8080/api/docs
```

### 5. Run Flutter Frontend

```bash
cd chat_toeic_app
flutter pub get
flutter run
```

**API Base URL by Platform:**

| Platform | API Base URL |
|---|---|
| Android Emulator | `http://10.0.2.2:8080` |
| iOS Simulator | `http://localhost:8080` |
| Physical Device | `http://<YOUR_LOCAL_IP>:8080` |

---

## Environment Variables

Copy `.env.example` to `.env` in the `chatbot-toeic-backend` directory:

| Variable | Required | Description |
|---|---|---|
| `DB_HOST` | Yes | `mssql` (Docker) or `localhost` (local) |
| `DB_USERNAME` | Yes | SQL Server username |
| `DB_PASS` | Yes | SQL Server password |
| `JWT_SECRET_KEY` | Yes | Access token signing secret |
| `JWT_REFRESH_SECRET_KEY` | Yes | Refresh token signing secret |
| `JWT_EXPIRATION` | Yes | Access token TTL (e.g., `7d`) |
| `JWT_REFRESH_EXPIRATION` | Yes | Refresh token TTL (e.g., `30d`) |
| `GOOGLE_CLIENT_ID` | Yes | Google OAuth 2.0 Client ID |
| `GOOGLE_CLIENT_SECRET` | Yes | Google OAuth 2.0 Client Secret |
| `GEMINI_API_KEYS` | Yes | Google Gemini API Key(s) |
| `CLOUDINARY_NAME` | Yes | Cloudinary Cloud Name |
| `CLOUDINARY_API_KEY` | Yes | Cloudinary API Key |
| `CLOUDINARY_API_SECRET` | Yes | Cloudinary API Secret |
| `ZALOPAY_APP_ID` | Yes | ZaloPay App ID |
| `ZALOPAY_KEY1` | Yes | ZaloPay HMAC Key 1 |
| `ZALOPAY_KEY2` | Yes | ZaloPay HMAC Key 2 |
| `ZALOPAY_CALLBACK_URL` | Yes | Public URL for ZaloPay webhook |
| `RABBITMQ_URL` | Yes | RabbitMQ connection string |
| `EMAIL_USER` | Yes | Gmail address for notifications |
| `EMAIL_PASS` | Yes | Gmail App Password |
| `ML_AUTO_PREDICTION` | Optional | `true` to auto-predict after test submission |

---

## API Overview

**Base URL:** `http://localhost:8080/api`
**Swagger UI:** `http://localhost:8080/api/docs`

All authenticated endpoints require:
```
Authorization: Bearer <access_token>
```

### Endpoint Groups

| Module | Prefix | Auth | Description |
|---|---|---|---|
| **Authentication** | `/v1/auth` | Partial | Register, login, token refresh, OAuth |
| **Account** | `/account` | Required | User profile management |
| **TOEIC Tests** | `/v1/tests` | Required | Test listing, questions, attempts |
| **Courses** | `/v1/courses` | Required | Course management |
| **Statistics** | `/v1/statistics` | Required | Learning analytics |
| **Media Upload** | `/v1/uploads` | Required | Image/audio upload to Cloudinary |
| **AI Chatbot** | `/v1/conversations` | Required | Gemini AI conversations |
| **Payment** | `/v1/payments` | Required | VIP subscriptions, ZaloPay |
| **ML Prediction** | `/ml/recommend` | Required | TOEIC score prediction |
| **Admin - Users** | `/admin-users` | Admin | User CRUD, roles, lock |
| **Admin - Tests** | `/admin-tests` | Admin | Test and question management |
| **Admin - Metadata** | `/admin-metadata` | Admin | Parts, types, skills CRUD |

Full API specification: see **[API_SPECIFICATION.md](./API_SPECIFICATION.md)**

---

## Key Features

### Authentication and Authorization
- JWT stateless auth: access token (7d) + refresh token (30d)
- Google OAuth 2.0 sign-in integration
- OTP via Email for registration and password reset
- Role-based access control (User / Admin)
- VIP middleware enforcing chatbot daily message limits (15 msgs/day for free users)

### TOEIC Test Engine
- Supports all 7 TOEIC parts: Listening (Parts 1-4) and Reading (Parts 5-7)
- Test modes: Full test, Mixed (Listening + Reading), and Practice (single question)
- Automatic scoring with per-part breakdown
- Attempt lifecycle: start - in-progress - submitted/cancelled
- Review mode with correct answers and explanations

### AI Chatbot (Google Gemini)
- Context-aware multi-turn conversations (Gemini 2.5 Flash)
- Conversation history persisted in database
- VIP gating with daily message enforcement
- API key rotation for rate limit handling

### Machine Learning Score Prediction
- Python Flask microservice with scikit-learn model
- Predicts TOEIC score and identifies weak skills
- Features: part accuracy, time spent, score trend
- Auto-retrain via cron job on new user data

### Payment - ZaloPay Integration
- Full ZaloPay Sandbox integration
- HMAC-SHA256 webhook signature validation
- Automatic VIP activation on payment callback
- Cumulative VIP expiry calculation

### Media Management
- Upload images and audio to Cloudinary
- Auto-detect audio duration
- Batch upload from local paths (Admin)

### Learning Analytics
- Dashboard: total tests, average score, time studied
- Per-part accuracy across all 7 TOEIC parts
- Accuracy trend chart (configurable range, default 30 days)
- Full test history with scores and timestamps

### Admin Panel
- User management: list, update roles, lock/unlock
- Full test creation with questions in one API call
- AI Embedding generation for ML similarity search
- Metadata CRUD: Parts, Question Types, Skills

---

## Services and Ports

| Service | Container | Internal Port | External Port | Description |
|---|---|---|---|---|
| Nginx (Gateway) | `api_gateway` | 8080 | **8080** | Single client entry point |
| Auth Service | `auth_service` | 8081 | - | Authentication and user data |
| Quiz Service | `quiz_service` | 8082 | - | Tests, courses, stats, uploads |
| Payment Service | `payment_service` | 8083 | - | ZaloPay transactions |
| Chatbot Service | `chatbot_service` | 8084 | - | Gemini AI conversations |
| ML Service | `ml_python_service` | 5000 | **5000** | Python prediction service |
| SQL Server | `mssql_db` | 1433 | **1433** | Relational databases |
| RabbitMQ | `rabbitmq_queue` | 5672 | **5672** | Message broker |
| RabbitMQ UI | `rabbitmq_queue` | 15672 | **15672** | Admin UI (guest/guest) |
| Flutter Web | `nginx_frontend` | 80 | **8000** | Optional Flutter web build |

---

## Database Design

Four isolated SQL Server databases (Database-per-Service pattern):

| Database | Service | Key Tables |
|---|---|---|
| `ChatbotToeic_Auth` | auth-service | `Users`, `Roles`, `RefreshTokens`, `OTPs` |
| `ChatbotToeic_Quiz` | quiz-service | `Tests`, `Questions`, `Courses`, `TestAttempts`, `UserAnswers`, `Parts`, `Skills` |
| `ChatbotToeic_Payment` | payment-service | `Subscriptions`, `Transactions`, `UserSubscriptions` |
| `ChatbotToeic_Chatbot` | chatbot-service | `Conversations`, `Messages` |

Cross-service data access is handled via internal REST calls (e.g., payment-service calls auth-service to update VIP status).

---

## Security Considerations

> **Warning:** Never commit real secrets to version control. Use `.env.example` as a template only.

**Implemented:**
- `express-rate-limit` on all API routes (stricter on auth endpoints)
- HMAC-SHA256 validation on ZaloPay webhook
- Bcrypt password hashing
- CORS whitelist with dynamic origin validation
- Nginx security headers: `X-Frame-Options`, `X-XSS-Protection`, `X-Content-Type-Options`
- JWT secrets in environment variables, never hardcoded

**Recommended for Production:**
1. Rotate all secrets; use a secrets manager (AWS Secrets Manager / Vault)
2. Enable HTTPS/TLS at Nginx layer (Let's Encrypt)
3. Use least-privilege DB users per service
4. Enable SQL Server encryption (`DB_ENCRYPT=true`)
5. Configure automated database backups

---

## Troubleshooting

### Containers not starting

```bash
docker compose logs -f
docker compose logs auth-service -f
docker compose restart quiz-service
```

### SQL Server slow startup

MSSQL may take 30-60 seconds. Restart services after it is ready:

```bash
docker compose restart auth-service quiz-service payment-service chatbot-service
```

### Port conflicts

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Linux / macOS
lsof -ti:8080 | xargs kill -9
```

### ZaloPay callback not received

Use ngrok to expose localhost:
```bash
ngrok http 8080
# Update ZALOPAY_CALLBACK_URL in .env with ngrok URL
docker compose restart payment-service
```

---

## Contributors

| Name | Role |
|---|---|
| **Pham Tuan Hung** | Backend Architecture, Microservices, ML Integration, DevOps |
| **Ho Thuan Kieu** | Frontend Development (Flutter), UI/UX |
| **Nguyen Tan Quy** | Backend Development, Database Design |

**Institution:** Posts and Telecommunications Institute of Technology (PTIT)
**Contact:** phamtuanhung9a5@gmail.com

---

## License

MIT License - Free to use for educational and research purposes.

---

**Version:** 2.0.0 (SWE_BE3) | **Last Updated:** August 2026
