# KẾ HOẠCH CHUYỂN ĐỔI KIẾN TRÚC API-FIRST & TÍCH HỢP SWAGGER DỰ ÁN CHATBOT TOEIC

## 1. Mục tiêu & Phạm vi (Scope)
* **Mục tiêu cốt lõi:** Chuyển đổi hệ thống backend hiện tại sang chuẩn kiến trúc RESTful API-first, tách biệt hoàn toàn frontend và backend.
* **Tài liệu hóa (Documentation):** Ứng dụng **Swagger (OpenAPI)** làm "nguồn chân lý" (Source of Truth) duy nhất, cung cấp tài liệu API trực quan để các team Frontend (Web, Mobile) tự do giao tiếp và tích hợp độc lập.
* **Phạm vi:** * Tất cả nghiệp vụ (business logic) phải đi qua Backend API. Client (Next.js Web / Flutter App) chỉ nhận trách nhiệm render giao diện và gọi API.
    * Loại bỏ hoàn toàn các logic phụ thuộc độc quyền vào trình duyệt web (như cookie browser, URL local hardcode).
    * Một bộ REST API duy nhất (`/api/v1/...`) phục vụ song song cho cả 2 nền tảng.

## 2. Đánh giá hiện trạng (Audit)
Từ mã nguồn hiện tại, các vấn đề kỹ thuật (Technical Debt) cần xử lý ngay:
* **Auth:** Đang thiên về Cookie (`authMiddleware` đọc `req.cookies.token`). Middleware auth bị phân mảnh.
* **Tính đồng nhất:** Có các route trùng lặp chức năng (VD: `/api/auth/me` và `/api/me`).
* **Naming Convention:** Nhiều endpoint đặt tên chưa theo chuẩn RESTful (chứa động từ, viết hoa chữ cái đầu).
* **CORS & Config:** Frontend hardcode `http://localhost:8080`. CORS backend đang khóa cứng.
* **Response Format:** Cấu trúc JSON trả về giữa các module chưa có sự thống nhất.
* **Tài liệu:** Chưa có hệ thống tài liệu API chuẩn, team mobile sẽ rất khó khăn khi muốn tích hợp.

## 3. Tiêu chuẩn kiến trúc (API-First Guidelines)
* **Versioning:** Mọi API mới phải bắt đầu bằng `/api/v1/`.
* **Tài liệu (Swagger UI):** Toàn bộ API phải được khai báo Decorator để Swagger tự động đọc và sinh ra giao diện UI (thường ở `localhost:3000/api/docs`). Phải có đầy đủ schema định nghĩa kiểu dữ liệu truyền vào (DTO) và trả về.
* **Authentication:** Sử dụng **JWT (Access Token + Refresh Token)** truyền qua Header `Authorization: Bearer <token>`. 
* **Naming Rule:** Chuẩn RESTful, viết thường (lowercase), sử dụng danh từ số nhiều cho resource (VD: `/users`, `/tests`).
* **Response Format chuẩn:**
    * *Success:* `{ "status": "success", "data": { ... }, "meta": { ... } }`
    * *Error:* `{ "status": "error", "code": 401, "message": "...", "details": [...] }`

---

## 4. Bảng ánh xạ Endpoint (Endpoint Migration Details)

### 4.1. Auth Module
| Method | Endpoint cũ | Endpoint mới (v1) | Ghi chú (Sẽ hiển thị trên Swagger) |
| :--- | :--- | :--- | :--- |
| POST | `/api/auth/register` | `/api/v1/auth/register` | Giữ nghiệp vụ |
| POST | `/api/auth/send-register-otp`| `/api/v1/auth/register/otp` | Rõ ngữ nghĩa REST |
| POST | `/api/auth/verify-register-otp`| `/api/v1/auth/register/verify-otp`| Rõ ngữ nghĩa |
| POST | `/api/auth/login` | `/api/v1/auth/login` | Trả access/refresh token |
| POST | `/api/auth/google-login` | `/api/v1/auth/google` | Chuẩn hóa tên |
| POST | `/api/auth/forgot-password` | `/api/v1/auth/password/forgot` | Nhóm theo resource password|
| POST | `/api/auth/reset-password` | `/api/v1/auth/password/reset` | Nhóm theo resource password|
| GET | `/api/auth/me` & `/api/me` | `/api/v1/auth/me` | Gộp chung, giữ 1 endpoint |
| POST | `/api/logout` | `/api/v1/auth/logout` | Logout theo token |
| POST | *(Chưa có)* | `/api/v1/auth/refresh` | **Bắt buộc cho Flutter session** |

### 4.2. Test (Course + Question/Test flow)
| Method | Endpoint cũ | Endpoint mới (v1) | Ghi chú (Sẽ hiển thị trên Swagger) |
| :--- | :--- | :--- | :--- |
| GET | `/api/testcourses/all` | `/api/v1/tests?include=course` | REST query |
| GET | `/api/testcourses/courses` | `/api/v1/courses` | Lấy danh sách course |
| GET | `/api/testcourses/with-tests` | `/api/v1/courses?include=tests`| REST query |
| PUT | `/api/testcourses/update/:id` | `PATCH /api/v1/courses/:id` | Update chuẩn REST |
| DELETE| `/api/testcourses/delete/:id` | `DELETE /api/v1/courses/:id` | Chuẩn REST |
| POST | `/api/testcourses/insert` | `/api/v1/courses` | Tạo mới |
| GET | `/api/questionTest/Detail/:testId`| `/api/v1/tests/:testId/questions`| Tên rõ ràng, nested routing |
| PUT | `/api/questionTest/update-question`| `PATCH /api/v1/questions/:questionId`| Update theo resource |
| POST | `/api/questionTest/create-question`| `/api/v1/tests/:testId/questions`| Tạo question theo test |
| POST | `/api/questionTest/StartTest/:testId`| `/api/v1/tests/:testId/attempts`| Bắt đầu 1 lần làm bài |
| POST | `/api/questionTest/Submit/:testId`| `/api/v1/tests/:testId/attempts/:attemptId/submit`| Submit attempt cụ thể |
| POST | `/api/questionTest/SubmitPractice`| `/api/v1/practice-attempts/submit`| Tách flow practice |
| GET | `/api/questionTest/Check/:testId` | `/api/v1/tests/:testId/attempts/latest/check`| Kiểm tra kết quả gần nhất |
| GET | `/api/questionTest/DetailResult/:userTestId`| `/api/v1/test-attempts/:attemptId/result`| Đổi tên ID rõ nghĩa |
| GET | `/api/questionTest/HistoryTest/:testId`| `/api/v1/tests/:testId/attempts/history`| Lịch sử theo test |

### 4.3. Chatbot Module
| Method | Endpoint cũ | Endpoint mới (v1) | Ghi chú (Sẽ hiển thị trên Swagger) |
| :--- | :--- | :--- | :--- |
| POST | `/api/conversations/` | `/api/v1/conversations` | Chuẩn REST |
| GET | `/api/conversations/user` | `/api/v1/users/me/conversations` | Rõ "của tôi" |
| GET | `/api/conversations/:id` | `/api/v1/conversations/:id` | Giữ nguyên format |
| DELETE| `/api/conversations/deleteConverssation/:id`| `DELETE /api/v1/conversations/:id`| Sửa typo + REST |
| PUT | `/api/conversations/updateConverssation/:id`| `PATCH /api/v1/conversations/:id`| Sửa typo + REST |
| POST | `/api/messages/` | `/api/v1/conversations/:conversationId/messages`| Message thuộc conversation|
| GET | `/api/messages/:conversationId`| `/api/v1/conversations/:conversationId/messages`| Nhất quán |
| GET | `/api/messages/:conversationId/gemini`| `/api/v1/conversations/:conversationId/messages?format=gemini`| Dùng query format |
| POST | `/api/question/:conversationId`| `/api/v1/conversations/:conversationId/ask` | Rõ intent hỏi chatbot |

### 4.4. Statistics & Upload
| Method | Endpoint cũ | Endpoint mới (v1) | Ghi chú (Sẽ hiển thị trên Swagger) |
| :--- | :--- | :--- | :--- |
| GET | `/api/statistical/user-tests` | `/api/v1/statistics/user-tests` | Chuẩn hóa tên module |
| GET | `/api/statistical/parts/statistics`| `/api/v1/statistics/parts` | Rút gọn |
| GET | `/api/statistical/accuracy-over-time`| `/api/v1/statistics/accuracy-over-time`| Giữ nguyên format |
| GET | `/api/statistical/user-test-history`| `/api/v1/statistics/user-test-history`| Giữ nguyên format |
| POST | `/api/upload/upload/image` | `/api/v1/uploads/images` | Bỏ lặp từ upload |
| POST | `/api/upload/upload/audio` | `/api/v1/uploads/audio` | Bỏ lặp từ upload |
| DELETE| `/api/upload/upload/delete/:publicId`| `DELETE /api/v1/uploads/:publicId`| resourceType giữ ở query/body|
| POST | `/api/upload/upload/batch-from-paths`| `/api/v1/uploads/batch` | Tên ngắn gọn |
| POST | `/api/upload/upload/validate-paths`| `/api/v1/uploads/validate-paths`| Giữ nghiệp vụ |

---

## 5. Lộ trình thực thi & Phân công (Roadmap)

Việc chuyển đổi được chia thành các Phase để đảm bảo Web hiện tại không bị gãy (Break) trong lúc phát triển.

### Phase A: Nền tảng chung & Setup Swagger (Foundation)
* **Task 1:** Tích hợp thư viện Swagger (VD: `@nestjs/swagger`). Cấu hình để hệ thống tự động sinh trang tài liệu `/api/docs`. Thiết lập bảo mật cho trang docs nếu cần.
* **Task 2:** Tạo Unified Auth Middleware. Hỗ trợ đọc cả `Bearer Token` (ưu tiên) và `Cookie` (fallback cho Web cũ). Cấu hình Swagger nhận diện Bearer Token để có thể test API có bảo mật ngay trên trình duyệt.
* **Task 3:** Chuẩn hóa biến môi trường (`.env`), cấu hình lại CORS. Định nghĩa lớp Response Interceptor để ép chuẩn format trả về.

### Phase B: Chuẩn hóa Auth
* **Task 1:** Tạo mới các endpoint `/api/v1/auth/...` và gắn các Decorator của Swagger (như `@ApiTags`, `@ApiOperation`, `@ApiResponse`) cho từng endpoint.
* **Task 2:** Tích hợp logic sinh và xác thực **Refresh Token**.
* **Task 3:** Cập nhật logic Logout để xóa Refresh Token trong DB.

### Phase C: Chuẩn hóa Domain APIs (Tiến hành song song)
* *Gợi ý phân công:* Hùng thiết kế core API và xử lý phần tích hợp AI (Chatbot). Kiều và Quý hỗ trợ chuẩn hóa các endpoint Test, Courses và Upload. **Quy định chung:** Ai code endpoint nào, người đó có trách nhiệm viết đủ Swagger Decorator cho endpoint đó.
* **Task 1:** Migrate API Test/Question (`/v1/tests`, `/v1/courses`).
* **Task 2:** Migrate API Chatbot (`/v1/conversations`).
* **Task 3:** Migrate API Stats & Media Upload (`/v1/statistics`, `/v1/uploads`).

### Phase D: Hoàn thiện Tài liệu hóa & Tương thích ngược
* **Task 1:** Rà soát lại toàn bộ trang Swagger UI. Đảm bảo 100% các API `/api/v1` đều hiển thị mô tả, body schema, và liệt kê các mã lỗi (400, 401, 404, 500) chi tiết. Xuất ra file `.json` hoặc `.yaml` của OpenAPI để cung cấp cho team mobile sinh code tự động (nếu dùng Swagger Codegen).
* **Task 2:** Tạo Postman Collection hoàn chỉnh làm phương án backup bổ sung.
* **Task 3 (Tương thích ngược):** Giữ nguyên các endpoint cũ, gắn tag `@ApiExcludeEndpoint` hoặc `@deprecated` để giấu đi trên Swagger. Tiến hành update dần lời gọi API trên Web hiện tại sang v1.

# PHASE E: Phát triển Frontend Đa nền tảng (Full Flutter) 🚀

## 1. Mục tiêu & Phạm vi (Scope)
* **Mục tiêu cốt lõi:** Xây dựng một ứng dụng duy nhất bằng Flutter có khả năng chạy mượt mà trên cả trình duyệt Web và thiết bị Android.
* **Chiến lược "Write Once, Run Anywhere":** Tận dụng tối đa bộ API v1 đã hoàn thiện để đồng bộ hóa dữ liệu giữa các nền tảng [cite: API_MIGRATION_PLAN.md].
* **Phạm vi:** * Xây dựng giao diện Responsive (đáp ứng) tự động thay đổi theo kích thước màn hình.
    * Tích hợp chatbot AI luyện thi TOEIC trực tiếp từ Backend v1 [cite: PHASE_C_IMPLEMENTATION.md].
    * Triển khai hệ thống nộp bài, xem kết quả và thống kê học tập.

## 2. Tech Stack & Công cụ
* **Framework:** Flutter (phiên bản ổn định mới nhất).
* **Quản lý trạng thái (State Management):** GetX hoặc Provider (Tùy chọn theo thế mạnh của team).
* **Kết nối API:** Dio kết hợp với `swagger_dart_code_generator` (để tự động sinh Model từ file JSON của Phase D) [cite: PHASE_D_IMPLEMENTATION.md].
* **Lưu trữ cục bộ:** `flutter_secure_storage` để quản lý Access/Refresh Token an toàn.
* **UI/UX:** Material Design 3.

## 3. Lộ trình thực thi (Roadmap)

### Bước 1: Khởi tạo & Cấu hình Core
* Khởi tạo dự án Flutter với hỗ trợ Web và Android.
* Cấu hình **Dio Interceptor**: Tự động đính kèm `Bearer Token` vào header và xử lý logic `Refresh Token` khi nhận lỗi 401 từ v1 API [cite: PHASE_B_IMPLEMENTATION.md].
* Chạy code generator từ link `http://localhost:8080/api/docs-json` để có bộ Model/Client hoàn chỉnh [cite: PHASE_D_IMPLEMENTATION.md].

### Bước 2: Thiết kế Giao diện Responsive
* **Mobile Layout (Android):** Thiết kế dạng dọc, ưu tiên sự gọn gàng, sử dụng Bottom Navigation để chuyển đổi giữa Học tập và Chatbot.
* **Web Layout (Desktop):** Tận dụng không gian rộng để hiển thị song song (Ví dụ: Bên trái là đề thi, bên phải là khung Chatbot AI giải thích ngữ pháp).
* **Shared Widgets:** Xây dựng hệ thống Component dùng chung (Button, Card bài học, Timer) để tiết kiệm thời gian code.

### Bước 3: Phát triển Module chức năng
* **Module Auth:** Màn hình Đăng nhập/Đăng ký tích hợp logic lưu Token.
* **Module Test:** Hiển thị bộ đề TOEIC, xử lý chọn đáp án, tính giờ và gọi API nộp bài [cite: PHASE_C_IMPLEMENTATION.md].
* **Module Chatbot:** Giao diện hội thoại thời gian thực, tích hợp AI phân tích lỗi sai và gợi ý từ vựng.

## 4. Phân công công việc (Gợi ý cho Team)

| Thành viên | Trách nhiệm chính |
| :--- | :--- |
| **Hùng** | Thiết kế kiến trúc Core, quản lý State, tích hợp API Chatbot AI và xử lý logic Token. |
| **Kiều & Quy** | Xây dựng hệ thống UI Components (Widgets), thiết kế màn hình Responsive cho Web/Mobile và module Statistics. |

## 5. Kiểm thử & Nghiệm thu (Definition of Done)
* [ ] Ứng dụng kết nối thành công với API v1 và hiển thị đúng dữ liệu thực tế [cite: PHASE_C_IMPLEMENTATION.md].
* [ ] Giao diện hoạt động ổn định trên cả Chrome (Web) và Emulator/Device thật (Android).
* [ ] Logic Refresh Token hoạt động tự động khi Access Token hết hạn.
* [ ] File APK được build thành công và bản Web được deploy lên Hosting (Vercel/Firebase).

---
*Tài liệu này được kế thừa và phát triển dựa trên kết quả của Phase A, B, C và D.*

## 6. Kiểm thử & Tiêu chí nghiệm thu (Definition of Done)
1.  **Test Coverage:** Có thể sử dụng trực tiếp nút **"Try it out" trên giao diện Swagger** để chạy thử luồng Đăng nhập -> Lấy Token -> Chatbot thành công 100%.
2.  **Security:** Swagger được cấu hình khóa bảo mật (Authorize padlock) hoạt động chuẩn xác với JWT Bearer.
3.  **Client Độc lập:** Ứng dụng Flutter chỉ cần nhìn vào Swagger UI là có thể tự tin gọi API, không cần hỏi thêm backend về cấu trúc trả về.
4.  **Graceful Migration:** Phiên bản Web hiện tại vẫn chạy ổn định. Gỡ bỏ endpoint cũ khi hoàn tất chuyển đổi.