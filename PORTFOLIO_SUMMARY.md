# PORTFOLIO SUMMARY — Chatbot TOEIC Platform
## Dự án Nổi Bật | Software Engineer & Backend Developer

> **Stack:** Node.js · Express · Microservices · Docker · SQL Server · Python ML · Flutter · Google Gemini AI · ZaloPay

---

## 1. Bối cảnh & Đặt vấn đề

### Bối cảnh

TOEIC (Test of English for International Communication) là chứng chỉ tiếng Anh quan trọng được hàng triệu người lao động và sinh viên tại Việt Nam theo đuổi mỗi năm. Tuy nhiên, phần lớn thí sinh gặp phải các vấn đề sau trong quá trình tự ôn luyện:

| Vấn đề | Mô tả |
|---|---|
| **Thiếu công cụ học tập thông minh** | Các nền tảng học TOEIC hiện tại chủ yếu cung cấp bài thi tĩnh, không có phản hồi cá nhân hóa |
| **Không biết điểm yếu của mình** | Người học khó xác định được Part nào họ cần cải thiện nhất |
| **Chi phí gia sư cao** | Việc được hướng dẫn 1-1 đòi hỏi chi phí lớn và không linh hoạt về thời gian |
| **Thiếu tính tương tác** | Thiếu công cụ hỏi đáp tức thời về ngữ pháp, từ vựng trong bối cảnh TOEIC |

### Đặt vấn đề

> *Làm thế nào để xây dựng một nền tảng luyện thi TOEIC toàn diện, có khả năng **cá nhân hóa lộ trình học**, **dự đoán điểm số**, và **tương tác thông minh như một gia sư AI**, với chi phí tiếp cận thấp?*

---

## 2. Mục tiêu & Phạm vi dự án

### Mục tiêu tổng thể

Xây dựng một hệ thống full-stack, production-ready phục vụ việc luyện thi TOEIC với 3 trụ cột:

```
+------------------+    +----------------------+    +-------------------+
|   PRACTICE       |    |   AI-POWERED         |    |   DATA-DRIVEN     |
|                  |    |                      |    |                   |
|  Full TOEIC test |    |  Chatbot Gemini AI   |    |  ML Score         |
|  engine with     |    |  for on-demand       |    |  Prediction &     |
|  auto-scoring    |    |  TOEIC tutoring      |    |  Weak Skill Reco  |
+------------------+    +----------------------+    +-------------------+
```

### Phạm vi kỹ thuật

| Phạm vi | Chi tiết |
|---|---|
| **Backend** | 5 microservices độc lập (Node.js/Express) + 1 ML service (Python Flask) |
| **Frontend** | Ứng dụng Flutter đa nền tảng (Android, iOS, Web) |
| **Cơ sở hạ tầng** | Docker Compose, Nginx API Gateway, SQL Server 2022 |
| **Tích hợp** | Google Gemini AI, ZaloPay Payment, Cloudinary Media, RabbitMQ Email |
| **ML Pipeline** | Thu thập dữ liệu → Train model → Auto-retrain → Serving REST API |

### Mục tiêu cụ thể (KPIs)

- [x] Hỗ trợ đầy đủ 7 Parts TOEIC (Listening Parts 1-4, Reading Parts 5-7)
- [x] Chấm điểm tự động sau mỗi lần nộp bài
- [x] Chatbot AI trả lời câu hỏi TOEIC trong vòng < 3 giây
- [x] Dự đoán điểm TOEIC dựa trên lịch sử làm bài
- [x] Tích hợp thanh toán ZaloPay cho gói VIP
- [x] Triển khai toàn bộ hệ thống qua Docker với 1 lệnh duy nhất
- [x] API Documentation đầy đủ qua Swagger UI

---

## 3. Trách nhiệm kỹ thuật cá nhân

> **Vai trò:** Software Engineer & Backend Developer (Lead Backend)

### 3.1 Thiết kế Kiến trúc Hệ thống

**Trách nhiệm:** Đề xuất và triển khai toàn bộ kiến trúc Microservices từ đầu.

- Phân tích yêu cầu nghiệp vụ và chia tách thành các bounded contexts độc lập
- Thiết kế service decomposition: Auth, Quiz, Chatbot, Payment, Email, ML
- Chọn pattern Database-per-Service để đảm bảo isolation giữa các service
- Thiết kế Nginx API Gateway routing cho toàn bộ hệ thống
- Quyết định communication pattern: REST (sync) + RabbitMQ (async for email)

### 3.2 Phát triển Auth Service

**Trách nhiệm:** Toàn bộ hệ thống xác thực và phân quyền.

- Implement JWT dual-token strategy (access token 7d + refresh token 30d)
- Tích hợp Google OAuth 2.0 cho đăng nhập bằng tài khoản Google
- Xây dựng luồng OTP qua email cho đăng ký và quên mật khẩu
- Thiết kế Role-Based Access Control (Admin / User)
- Implement VIP middleware kiểm tra giới hạn tin nhắn Chatbot theo ngày

### 3.3 Phát triển Quiz Service

**Trách nhiệm:** Engine chấm điểm và toàn bộ logic bài thi TOEIC.

- Thiết kế data model cho Tests, Questions, Parts, Skills, TestAttempts
- Implement thuật toán chấm điểm TOEIC theo từng Part
- Xây dựng lifecycle management cho attempt: start → in-progress → submitted/cancelled
- Tích hợp Cloudinary cho upload audio/image bài thi
- Xây dựng tính năng batch upload từ local path (Admin tool)
- Triển khai Swagger/OpenAPI 3 documentation cho toàn bộ API

### 3.4 Tích hợp AI Chatbot (Google Gemini)

**Trách nhiệm:** Toàn bộ module chatbot AI.

- Tích hợp Google Gemini 2.5 Flash qua REST API (không dùng SDK)
- Implement multi-turn conversation với context history từ database
- Xây dựng API key rotation (round-robin) để phân tán rate limit
- Thiết kế VIP gating logic: kiểm tra số tin nhắn trong ngày cross-service
- Lưu trữ toàn bộ conversation history theo user

### 3.5 Tích hợp ZaloPay Payment

**Trách nhiệm:** Toàn bộ module thanh toán.

- Implement ZaloPay Sandbox integration (tạo order, generate payment URL)
- Xây dựng webhook receiver với HMAC-SHA256 signature validation
- Logic kích hoạt VIP tự động sau khi nhận callback hợp lệ
- Thiết kế cumulative VIP expiry (cộng dồn, không ghi đè)
- Sử dụng ngrok để test webhook trong môi trường local

### 3.6 ML Pipeline Integration

**Trách nhiệm:** Tích hợp backend với ML service và cron jobs.

- Tích hợp Python Flask ML service vào hệ thống microservices
- Implement `mlRetrainCron.js`: auto-retrain model hàng ngày lúc 2:00 AM
- Implement `embeddingCron.js`: tự động tạo AI embeddings cho câu hỏi mới
- Xây dựng REST API proxy từ quiz-service đến ml-service

### 3.7 DevOps & Infrastructure

**Trách nhiệm:** Toàn bộ containerization và triển khai.

- Viết `Dockerfile` cho 5 Node.js services
- Cấu hình `docker-compose.yml` điều phối 9 containers
- Cấu hình `nginx.conf` routing theo path prefix cho từng service
- Viết MSSQL init script tự động tạo schema và seed data khi khởi động lần đầu
- Cấu hình Docker volumes cho database persistence

---

## 4. Kiến trúc Hệ thống Tổng thể

### 4.1 System Architecture Overview

```mermaid
graph TB
    subgraph Client["📱 Client Layer"]
        APP["Flutter App\n(Android / iOS / Web)"]
    end

    subgraph Gateway["🔀 API Gateway Layer"]
        NGINX["Nginx Reverse Proxy\nport 8080\n(Routing + Security Headers)"]
    end

    subgraph Services["⚙️ Microservices Layer"]
        AUTH["Auth Service\n:8081\nNode.js + Express"]
        QUIZ["Quiz Service\n:8082\nNode.js + Express"]
        CHAT["Chatbot Service\n:8084\nNode.js + Express"]
        PAY["Payment Service\n:8083\nNode.js + Express"]
        ML["ML Service\n:5000\nPython Flask"]
        EMAIL["Email Worker\nNode.js\n(RabbitMQ Consumer)"]
    end

    subgraph Data["🗄️ Data Layer"]
        DB_AUTH["MSSQL\nChatbotToeic_Auth"]
        DB_QUIZ["MSSQL\nChatbotToeic_Quiz"]
        DB_CHAT["MSSQL\nChatbotToeic_Chatbot"]
        DB_PAY["MSSQL\nChatbotToeic_Payment"]
        MQ["RabbitMQ\nMessage Queue"]
        CDN["Cloudinary\nMedia CDN"]
    end

    subgraph External["🌐 External APIs"]
        GEMINI["Google Gemini 2.5 Flash\nGenerative AI"]
        ZALOPAY["ZaloPay Sandbox\nPayment Gateway"]
        GOOGLE["Google OAuth 2.0"]
    end

    APP -->|"HTTPS :8080"| NGINX
    NGINX -->|"/api/v1/auth"| AUTH
    NGINX -->|"/api/v1/tests\n/api/v1/courses\n/api/v1/statistics"| QUIZ
    NGINX -->|"/api/v1/conversations"| CHAT
    NGINX -->|"/api/v1/payments"| PAY
    NGINX -->|"/api/ml"| QUIZ
    QUIZ -->|"REST HTTP"| ML

    AUTH --- DB_AUTH
    QUIZ --- DB_QUIZ
    CHAT --- DB_CHAT
    PAY --- DB_PAY

    AUTH -->|"Publish OTP event"| MQ
    PAY -->|"Publish payment event"| MQ
    MQ -->|"Consume & send email"| EMAIL

    PAY -->|"PATCH /internal/users/:id\n(VIP activation)"| AUTH
    CHAT -->|"GET /internal/users/:id\n(VIP check)"| AUTH

    QUIZ -->|"Upload media"| CDN
    CHAT -->|"generateContent"| GEMINI
    PAY -->|"Create order / Verify callback"| ZALOPAY
    AUTH -->|"Verify ID Token"| GOOGLE
```

### 4.2 Authentication Flow

```mermaid
sequenceDiagram
    participant C as Flutter App
    participant G as Nginx Gateway
    participant A as Auth Service
    participant DB as MSSQL Auth DB
    participant MQ as RabbitMQ
    participant E as Email Service

    C->>G: POST /api/v1/auth/register/send-otp
    G->>A: Forward request
    A->>DB: Check email not exists
    A->>MQ: Publish {email, otp, type: "register"}
    MQ->>E: Consume message
    E-->>C: Send OTP email
    A-->>C: 200 OTP sent

    C->>G: POST /api/v1/auth/register/verify-otp
    G->>A: Forward request
    A->>DB: Validate OTP (TTL 10 min)
    A-->>C: 200 OTP verified

    C->>G: POST /api/v1/auth/register
    G->>A: Forward request
    A->>DB: Create user (bcrypt password)
    A-->>C: 201 {user, accessToken, refreshToken}

    Note over C,E: Subsequent requests use accessToken in Authorization header
```

### 4.3 TOEIC Test Attempt Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Browse : GET /api/v1/tests
    Browse --> Loading : GET /api/v1/tests/:id/questions
    Loading --> InProgress : POST /api/v1/tests/:id/attempts\n(status = in_progress)
    InProgress --> Submitted : PATCH attempts/:id\n(status = completed, answers, timeSpent)
    InProgress --> Cancelled : PATCH attempts/:id\n(status = cancelled)
    Submitted --> Review : GET /api/v1/test-attempts/:id/result\n(show correct answers + explanations)
    Cancelled --> [*]
    Review --> [*]

    note right of Submitted
        Auto-scoring:
        - Compare answers vs correctAnswer
        - Calculate per-part scores
        - Map to TOEIC scale
        - Store listeningScore + readingScore
        - Trigger ML prediction (if enabled)
    end note
```

### 4.4 AI Chatbot Flow (with VIP Gating)

```mermaid
sequenceDiagram
    participant C as Flutter App
    participant G as Nginx Gateway
    participant CS as Chatbot Service
    participant AS as Auth Service
    participant DB as Chatbot DB
    participant GEM as Gemini AI API

    C->>G: POST /api/v1/conversations/:id/messages\n{rawText: "Explain present perfect..."}
    G->>CS: Forward (with JWT)
    CS->>CS: authMiddleware: verify JWT
    CS->>AS: GET /api/v1/internal/users/:id\n(check VIP status)
    AS-->>CS: {isVip: false, role_id: 2}

    alt Free User - Check daily limit
        CS->>DB: COUNT messages WHERE role=user AND today
        DB-->>CS: count = 14

        alt count < 15
            CS->>DB: Fetch conversation history
            DB-->>CS: [{role: user, content: ...}, ...]
            CS->>GEM: POST generateContent\n{system_prompt + history + rawText}
            GEM-->>CS: AI response text
            CS->>DB: Save user message (role=user)
            CS->>DB: Save AI response (role=model)
            CS-->>C: 200 {role: model, content: "..."}
        else count >= 15
            CS-->>C: 429 Daily limit reached\nUpgrade to VIP
        end
    else VIP User - No limit
        CS->>DB: Fetch conversation history
        CS->>GEM: POST generateContent
        GEM-->>CS: AI response
        CS-->>C: 200 {role: model, content: "..."}
    end
```

### 4.5 ZaloPay Payment Flow

```mermaid
sequenceDiagram
    participant C as Flutter App
    participant G as Nginx Gateway
    participant PS as Payment Service
    participant AS as Auth Service
    participant ZP as ZaloPay Sandbox

    C->>G: POST /api/v1/payments/create\n{subscriptionId: 1, paymentGateway: zalopay}
    G->>PS: Forward (with JWT)
    PS->>PS: Lookup subscription price (50,000 VND)
    PS->>ZP: POST /v2/create\n(HMAC-SHA256 signed order)
    ZP-->>PS: {order_url, app_trans_id}
    PS-->>C: 200 {orderUrl: "https://zalopay..."}

    C->>ZP: User opens payment URL & completes payment
    ZP->>G: POST /api/v1/payments/zalopay-callback\n{data, mac}
    G->>PS: Forward callback
    PS->>PS: Validate HMAC-SHA256 signature
    
    alt Valid signature
        PS->>PS: Parse embed_data (userId, subscriptionId)
        PS->>PS: Calculate new vipExpireAt (cumulative)
        PS->>AS: PATCH /api/v1/internal/users/:id\n{isVip: true, vipExpireAt: ...}
        AS-->>PS: 200 Updated
        PS-->>ZP: {return_code: 1, return_message: "Success"}
    else Invalid signature
        PS-->>ZP: {return_code: -1, return_message: "MAC validation failed"}
    end
```

### 4.6 ML Score Prediction Pipeline

```mermaid
flowchart TD
    A[User completes TOEIC test] --> B[Quiz Service stores attempt results]
    B --> C{ML_AUTO_PREDICTION\nenabled?}
    C -->|Yes| D[Call ML Service\nPOST /predict]
    C -->|No| Z[End]
    
    D --> E[ML Service reads ChatbotToeic_Quiz DB]
    E --> F[Feature Engineering\n- Part accuracy 1-7\n- Avg time per question\n- Score trend\n- Total attempts]
    F --> G[Load unified_model.pkl\nscikit-learn RandomForest]
    G --> H[Generate predictions:\n- TOEIC total score\n- Listening / Reading split\n- Weak skill identification]
    H --> I[Return recommendations\nto Quiz Service]
    I --> J[Store & return to Flutter App]

    subgraph Retrain["Auto-Retrain (Daily 2:00 AM)"]
        K[mlRetrainCron.js triggers] --> L[Call ML Service\nPOST /retrain]
        L --> M[Fetch latest attempt data from DB]
        M --> N[Re-train RandomForest model]
        N --> O[Save new unified_model.pkl]
        O --> P[Model ready for next predictions]
    end
```

### 4.7 Docker Infrastructure

```mermaid
graph LR
    subgraph HOST["Host Machine (Windows)"]
        ENV[".env file\n(secrets)"]
        VOL["D:/Downloads\n(local media)"]
    end

    subgraph COMPOSE["Docker Compose Network (chatbot_network)"]
        direction TB
        
        subgraph PROXY["Gateway"]
            NGINX["nginx:alpine\napi_gateway\n:8080"]
        end

        subgraph NODES["Node.js Services"]
            AS["auth_service\n:8081"]
            QS["quiz_service\n:8082"]
            PS["payment_service\n:8083"]
            CS["chatbot_service\n:8084"]
            ES["email_worker_service"]
        end

        subgraph PYTHON["Python Service"]
            ML["ml_python_service\n:5000"]
        end

        subgraph INFRA["Infrastructure"]
            DB["mssql_db\n:1433\n(4 databases)"]
            RMQ["rabbitmq_queue\n:5672 / :15672"]
        end
    end

    NGINX --> AS
    NGINX --> QS
    NGINX --> PS
    NGINX --> CS
    NGINX --> ML

    AS --> DB
    QS --> DB
    PS --> DB
    CS --> DB
    ML --> DB

    AS --> RMQ
    PS --> RMQ
    RMQ --> ES

    ENV -.->|"env_file"| COMPOSE
    VOL -.->|"volume mount\n/mnt/d/Downloads"| QS
```

---

## 5. Kết quả & Hiệu quả

### Technical Achievements

| Thành tựu | Chi tiết |
|---|---|
| **Scalable Architecture** | Mỗi service có thể scale độc lập; thêm instance mà không cần sửa code |
| **Zero-downtime Deployment** | Docker restart policy đảm bảo service tự phục hồi sau crash |
| **API Documentation** | 55+ endpoints có Swagger UI, ready for team onboarding |
| **Security** | Rate limiting, JWT, HMAC validation, CORS whitelist, security headers |
| **Async Processing** | Email gửi bất đồng bộ qua RabbitMQ, không block API response |
| **Auto ML Retrain** | Model tự cải thiện theo dữ liệu người dùng mới mà không cần can thiệp |
| **One-command Deploy** | `docker compose up -d --build` khởi động toàn bộ 9 containers |

### Skills Demonstrated

```
Backend Development:     ████████████████████  Node.js, Express, REST API Design
Database Design:         ████████████████      SQL Server, Sequelize ORM, DB-per-Service
Microservices:           ████████████████████  Service decomposition, inter-service comm
Authentication:          ████████████████████  JWT, OAuth 2.0, OTP, RBAC
Third-party Integration: ████████████████      Gemini AI, ZaloPay, Cloudinary, Google Auth
DevOps:                  ████████████          Docker, Docker Compose, Nginx
Machine Learning:        ████████              scikit-learn, Flask, auto-retrain pipeline
Message Queue:           ████████████          RabbitMQ, async event-driven patterns
API Documentation:       ████████████████████  Swagger/OpenAPI 3
```

---

**Prepared by:** Pham Tuan Hung
**Role:** Software Engineer & Backend Developer
**Contact:** phamtuanhung9a5@gmail.com
**Repository Branch:** SWE_BE3
**Date:** August 2026
