# CHƯƠNG 4: ĐẶC TẢ RESTFUL API

## 4.1 Tổng quan kiến trúc API
Hệ thống **Chatbot TOEIC** sử dụng mô hình kiến trúc **API-First**, tách biệt hoàn toàn giữa ứng dụng giao diện (Flutter App chạy trên Web/Mobile) và hệ thống xử lý nghiệp vụ (Backend Node.js/Express). 

Tất cả các API mới được thiết kế tuân thủ nghiêm ngặt chuẩn **RESTful API** phiên bản v1 (`/api/v1/`):
*   **Đồng nhất định dạng dữ liệu (Unified Format):**
    *   **Thành công (200, 201):**
        ```json
        {
          "status": "success",
          "message": "Thông báo thành công",
          "data": { ... },
          "meta": {
            "timestamp": "2026-06-22T13:38:09.000Z"
          }
        }
        ```
    *   **Lỗi (400, 401, 403, 404, 500):**
        ```json
        {
          "status": "error",
          "code": 401,
          "message": "Thông báo lỗi chi tiết",
          "errorCode": "INTERNAL_ERROR_CODE",
          "details": [ ... ],
          "timestamp": "2026-06-22T13:38:09.000Z"
        }
        ```
*   **Phương thức HTTP:** Sử dụng đúng động từ HTTP tương ứng nghiệp vụ (`GET` để lấy dữ liệu, `POST` để tạo mới, `PUT`/`PATCH` để cập nhật, `DELETE` để xóa).
*   **Định dạng tên tài nguyên:** Danh từ số nhiều, viết thường (lowercase).

---

## 4.2 Xác thực và phân quyền
*   **Bảo mật:** Hệ thống sử dụng cơ chế xác thực dựa trên **JSON Web Token (JWT)**.
    *   Sau khi đăng nhập thành công, máy chủ cấp cho Client một cặp mã thông báo: `accessToken` (ngắn hạn, dùng để đính kèm vào tiêu đề yêu cầu) và `refreshToken` (dài hạn, dùng để cấp lại Access Token mới khi hết hạn).
    *   Mỗi khi gọi API cần bảo mật, Client phải đính kèm Token trong tiêu đề yêu cầu:
        `Authorization: Bearer <access_token>`
*   **Tiêu đề yêu cầu (Request Headers):** Mọi request header đều phải tuân thủ các quy ước sau:

    | Tên header | Bắt buộc | Giá trị |
    | :--- | :--- | :--- |
    | `Authorization` | Có (Với các API cần xác thực) | `Bearer <access_token>` |
    | `Content-Type` | Có (Với các phương thức POST, PUT, PATCH) | `application/json` hoặc `multipart/form-data` (khi tải tệp tin) |
    | `Accept` | Không | `application/json` |

*   **Phân quyền (RBAC):** Middleware `authMiddleware` sẽ kiểm tra JWT và vai trò của tài khoản trong cơ sở dữ liệu để quyết định quyền truy cập:
    *   `Role 1` (Admin): Toàn quyền quản trị khóa học, người dùng, metadata, cấu hình hệ thống.
    *   `Role 2` (User/Student): Có quyền học tập, làm bài thi, xem thống kê cá nhân và sử dụng Chatbot AI.

---

## 4.3 Danh sách đặc tả API chi tiết

### 4.3.1 Module Xác thực & Tài khoản (Authentication)
Module này xử lý tất cả các yêu cầu đăng ký, đăng nhập, làm mới token và phục hồi mật khẩu.

#### 4.3.1.1 API Đăng ký tài khoản (Register)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/register`
*   **Mô tả:** Đăng ký tài khoản người dùng mới bằng email và mật khẩu.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `username` | String | Có | Tên đăng nhập người dùng |
    | `email` | String | Có | Địa chỉ email người dùng |
    | `password` | String | Có | Mật khẩu tài khoản |
*   **Phản hồi thành công (201 Created):**
    ```json
    {
      "status": "success",
      "message": "User registered successfully",
      "data": {
        "id": 15,
        "username": "tuanhung",
        "email": "hung@example.com"
      }
    }
    ```

#### 4.3.1.2 API Gửi mã OTP đăng ký (Send OTP)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/register/otp`
*   **Mô tả:** Gửi mã OTP xác minh qua Email trước khi hoàn tất đăng ký.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `email` | String | Có | Địa chỉ email nhận mã OTP |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "OTP sent to email successfully"
    }
    ```

#### 4.3.1.3 API Xác thực OTP hoàn tất đăng ký (Verify OTP)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/register/verify-otp`
*   **Mô tả:** Xác thực mã OTP gửi qua Email để kích hoạt tài khoản.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `email` | String | Có | Địa chỉ email cần xác minh |
    | `otp` | String | Có | Mã OTP nhận từ email |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Email verified and registration completed successfully"
    }
    ```

#### 4.3.1.4 API Đăng nhập hệ thống (Login)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/login`
*   **Mô tả:** Kiểm tra thông tin đăng nhập và trả về cặp token JWT.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `email` | String | Có | Địa chỉ email đăng nhập |
    | `password` | String | Có | Mật khẩu truy cập |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Login successful",
      "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
        "refreshToken": "eyJhbGciOiJIUzI1NiIsIn...",
        "user": {
          "id": 15,
          "username": "tuanhung",
          "email": "hung@example.com",
          "role_id": 2
        }
      }
    }
    ```

#### 4.3.1.5 API Đăng nhập bằng Google (Google Login)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/google`
*   **Mô tả:** Xác thực người dùng bằng tài khoản Google (OAuth2).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `token` | String | Có | ID Token trả về từ thư viện đăng nhập Google trên Client |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Google login successful",
      "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
        "refreshToken": "eyJhbGciOiJIUzI1NiIsIn...",
        "user": {
          "id": 16,
          "username": "Hung Google",
          "email": "hung.google@gmail.com",
          "role_id": 2
        }
      }
    }
    ```

#### 4.3.1.6 API Làm mới Token (Refresh Token)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/refresh`
*   **Mô tả:** Dùng Refresh Token để cấp lại Access Token mới (khi token cũ hết hạn).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `refreshToken` | String | Có | Refresh Token hợp lệ được cung cấp khi login |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Token refreshed successfully",
      "data": {
        "accessToken": "eyJhbGciOiJIUzI1NiIsIn..."
      }
    }
    ```

#### 4.3.1.7 API Đăng xuất (Logout)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/logout`
*   **Mô tả:** Đăng xuất khỏi hệ thống, hủy bỏ hiệu lực của Refresh Token hiện tại.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `refreshToken` | String | Không | Refresh Token để hủy trên Server (nếu có) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Logged out successfully"
    }
    ```

#### 4.3.1.8 API Lấy thông tin cá nhân hiện tại (Get Me)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/auth/me`
*   **Mô tả:** Lấy thông tin chi tiết của người dùng đang đăng nhập dựa trên token.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Get user profile success",
      "data": {
        "id": 15,
        "username": "tuanhung",
        "email": "hung@example.com",
        "avatar": "https://cloudinary.com/path/to/avatar.jpg",
        "role_id": 2
      }
    }
    ```

#### 4.3.1.9 API Quên mật khẩu (Forgot Password)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/password/forgot`
*   **Mô tả:** Gửi yêu cầu lấy lại mật khẩu. Hệ thống sẽ gửi OTP phục hồi mật khẩu qua Email.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `email` | String | Có | Email tài khoản cần đặt lại mật khẩu |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Reset OTP code has been sent to your email"
    }
    ```

#### 4.3.1.10 API Đặt lại mật khẩu (Reset Password)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/auth/password/reset`
*   **Mô tả:** Đặt lại mật khẩu mới bằng mã OTP xác minh đã nhận.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `email` | String | Có | Email tài khoản cần khôi phục |
    | `otp` | String | Có | Mã OTP xác nhận được gửi qua email |
    | `newPassword` | String | Có | Mật khẩu mới thiết lập |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Password reset successfully"
    }
    ```

---

### 4.3.2 Module Khóa học & Đề thi (Courses & Tests)
Hỗ trợ quản lý khóa học luyện thi TOEIC, ngân hàng câu hỏi, thực hiện làm bài và nộp bài thi.

#### 4.3.2.1 API Lấy danh sách khóa học (Get Courses)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/courses`
*   **Mô tả:** Lấy danh sách các khóa học TOEIC hiện có.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `include` | String | Không | Query Param - ví dụ `tests` (trả về danh sách bài test thuộc khóa) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 1,
          "name": "Luyện thi TOEIC Starter",
          "tests": [
            { "id": 10, "title": "Test 1 - Reading", "duration": "45 mins" }
          ]
        }
      ]
    }
    ```

#### 4.3.2.2 API Lấy danh sách bài thi trong khóa học (Get Course Tests)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/courses/:id/tests`
*   **Mô tả:** Lấy toàn bộ các đề thi thuộc về một khóa học chỉ định.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID của khóa học |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 10,
          "title": "Test 1 - Reading & Listening",
          "duration": "120 minutes",
          "totalQuestions": 200
        }
      ]
    }
    ```

#### 4.3.2.3 API Tạo khóa học mới (Create Course)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/courses`
*   **Mô tả:** Tạo một khóa học luyện thi mới *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `name` | String | Có | Tên của khóa học mới cần tạo |
*   **Phản hồi thành công (201 Created):**
    ```json
    {
      "status": "success",
      "message": "Course created successfully",
      "data": {
        "id": 5,
        "name": "TOEIC Đột Phá 750+"
      }
    }
    ```

#### 4.3.2.4 API Cập nhật thông tin khóa học (Update Course)
*   **HTTP Method:** `PATCH`
*   **Endpoint:** `/api/v1/courses/:id`
*   **Mô tả:** Chỉnh sửa tên của khóa học chỉ định *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID khóa học cần chỉnh sửa |
    | `name` | String | Có | Tên khóa học mới |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Course updated successfully"
    }
    ```

#### 4.3.2.5 API Xóa khóa học (Delete Course)
*   **HTTP Method:** `DELETE`
*   **Endpoint:** `/api/v1/courses/:id`
*   **Mô tả:** Xóa một khóa học luyện thi khỏi hệ thống *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID khóa học cần xóa |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Course deleted successfully"
    }
    ```

#### 4.3.2.6 API Lấy danh sách đề thi tổng hợp (Get Tests)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/tests`
*   **Mô tả:** Lấy danh sách toàn bộ đề thi trong hệ thống.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 12,
          "title": "TOEIC ETS 2024 - Test 1",
          "duration": "120 minutes",
          "course_id": 2
        }
      ]
    }
    ```

#### 4.3.2.7 API Lấy danh sách câu hỏi của bài thi (Get Test Questions)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/tests/:testId/questions`
*   **Mô tả:** Lấy toàn bộ câu hỏi (kèm hình ảnh, âm thanh, các lựa chọn A, B, C, D) thuộc đề thi.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi cần lấy danh sách câu hỏi |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 101,
          "questionText": "What is the main topic of the conversation?",
          "optionA": "Scheduling a meeting",
          "optionB": "Ordering office supplies",
          "optionC": "Hiring new staff",
          "optionD": "Planning a conference",
          "audioPath": "https://cloudinary.com/audio/sample1.mp3",
          "imagePath": null,
          "partId": 3,
          "skillId": 1
        }
      ]
    }
    ```

#### 4.3.2.8 API Thêm câu hỏi vào bài thi (Create Question)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/tests/:testId/questions`
*   **Mô tả:** Thêm một câu hỏi trắc nghiệm mới vào bài thi chỉ định *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID đề thi đích |
    | `questionText`| String | Có | Văn bản hiển thị câu hỏi |
    | `optionA` | String | Có | Nội dung đáp án trắc nghiệm A |
    | `optionB` | String | Có | Nội dung đáp án trắc nghiệm B |
    | `optionC` | String | Có | Nội dung đáp án trắc nghiệm C |
    | `optionD` | String | Có | Nội dung đáp án trắc nghiệm D |
    | `correctAnswer`| String | Có | Đáp án đúng tương ứng (giá trị 'A', 'B', 'C', 'D') |
    | `partId` | Integer | Có | ID của phần thi (Part 1 - Part 7) |
    | `skillId` | Integer | Có | ID kỹ năng (Ví dụ: 1 cho Listening, 2 cho Reading) |
*   **Phản hồi thành công (201 Created):**
    ```json
    {
      "status": "success",
      "message": "Question created successfully",
      "data": {
        "id": 254,
        "testId": 12
      }
    }
    ```

#### 4.3.2.9 API Bắt đầu làm bài thi (Start Attempt)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/tests/:testId/attempts`
*   **Mô tả:** Ghi nhận người dùng bắt đầu thực hiện bài thi, hệ thống sẽ lưu thời gian bắt đầu làm.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi bắt đầu |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "attemptId": 58,
        "testId": 12,
        "userId": 15,
        "startTime": "2026-06-22T20:45:00.000Z",
        "status": "in_progress"
      }
    }
    ```

#### 4.3.2.10 API Nộp bài thi (Submit Attempt)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/tests/:testId/attempts/:attemptId/submit`
*   **Mô tả:** Nộp danh sách đáp án đã chọn của bài thi để chấm điểm và lưu kết quả.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi |
    | `attemptId` | Integer | Có | Path Param - ID phiên làm bài |
    | `answers` | Object | Có | Đối tượng JSON ánh xạ câu hỏi:đáp án (VD: `{"101": "B"}`) |
    | `timeSpent` | Integer | Có | Tổng thời gian làm bài (giây) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Test submitted successfully",
      "data": {
        "attemptId": 58,
        "score": 450,
        "totalCorrect": 45,
        "totalQuestions": 50,
        "timeSpent": 3600,
        "skillsBreakdown": {
          "listening": { "correct": 20, "total": 25 },
          "reading": { "correct": 25, "total": 25 }
        }
      }
    }
    ```

#### 4.3.2.11 API Hủy bài thi đang làm dở (Cancel Attempt)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/tests/:testId/attempts/:attemptId/cancel`
*   **Mô tả:** Hủy phiên làm bài hiện tại đang dang dở.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi |
    | `attemptId` | Integer | Có | Path Param - ID phiên làm bài cần hủy |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Attempt canceled successfully"
    }
    ```

#### 4.3.2.12 API Kiểm tra trạng thái làm bài gần nhất (Check Latest Attempt)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/tests/:testId/attempts/latest/check`
*   **Mô tả:** Kiểm tra xem người dùng có lượt làm bài thi nào đang dang dở (`in_progress`) đối với đề thi này hay không.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi cần kiểm tra |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "hasActiveAttempt": true,
        "activeAttempt": {
          "attemptId": 58,
          "startTime": "2026-06-22T20:45:00.000Z"
        }
      }
    }
    ```

#### 4.3.2.13 API Lấy lịch sử làm bài của bài thi (Get Test Attempts History)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/tests/:testId/attempts/history`
*   **Mô tả:** Lấy danh sách lịch sử tất cả các lần làm bài thi của user đối với bài thi cụ thể này.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `testId` | Integer | Có | Path Param - ID bài thi cần lấy lịch sử |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "attemptId": 58,
          "score": 450,
          "correctCount": 45,
          "totalQuestions": 50,
          "createdAt": "2026-06-22T20:45:00.000Z"
        }
      ]
    }
    ```

#### 4.3.2.14 API Lấy kết quả chi tiết bài thi (Get Attempt Result Details)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/test-attempts/:attemptId/result`
*   **Mô tả:** Lấy bảng phân tích chi tiết đáp án đã chọn, đáp án đúng, lời giải thích và các thông tin thống kê của một lượt thi cụ thể.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `attemptId` | Integer | Có | Path Param - ID phiên làm bài cần truy xuất kết quả |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "attemptId": 58,
        "score": 450,
        "answersBreakdown": [
          {
            "questionId": 101,
            "userAnswer": "B",
            "correctAnswer": "B",
            "isCorrect": true,
            "explanation": "Dựa trên nội dung đoạn nghe tại giây thứ 15, người phụ nữ nói..."
          }
        ]
      }
    }
    ```

#### 4.3.2.15 API Nộp bài thi luyện tập tự do (Submit Practice Attempt)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/tests/practice-attempts`
*   **Mô tả:** Nộp câu trả lời cho bài luyện tập tự do theo danh sách câu hỏi để tạo lượt luyện tập mới và lưu lịch sử.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `answers` | Array | Có | Mảng đáp án lựa chọn của người học. Mỗi phần tử chứa `questionId` (Integer, bắt buộc) và `selectedAnswer` (String, có thể null nếu bỏ qua). |
    | `timeSpent` | Integer | Không | Thời gian làm bài (giây). Client gửi lên nhưng Backend không bắt buộc/không lưu trữ trực tiếp. |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Practice submitted successfully",
      "data": {
        "userTestId": 58,
        "correctCount": 1,
        "total": 1,
        "score": 10.0,
        "incorrectAnswers": []
      }
    }
    ```

#### 4.3.2.16 API Cập nhật thông tin câu hỏi (Update Question)
*   **HTTP Method:** `PATCH`
*   **Endpoint:** `/api/v1/questions/:id`
*   **Mô tả:** Cập nhật thông tin, nội dung câu hỏi trong ngân hàng câu hỏi *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID câu hỏi cần chỉnh sửa |
    | `questionText`| String | Không | Văn bản câu hỏi mới |
    | `correctAnswer`| String | Không | Đáp án đúng mới |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Question updated successfully"
    }
    ```

#### 4.3.2.17 API Cập nhật thông tin bài thi (Update Test)
*   **HTTP Method:** `PATCH`
*   **Endpoint:** `/api/v1/tests/:id`
*   **Mô tả:** Cập nhật thông tin cấu hình của một bài thi chỉ định *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID bài thi cần cập nhật |
    | `title` | String | Không | Tiêu đề bài thi mới |
    | `duration` | String | Không | Thời gian thi thiết lập mới (Ví dụ: "45 mins") |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Test updated successfully"
    }
    ```

---

### 4.3.3 Module Trò chuyện & Chatbot AI (Conversations & Chatbot AI)
Phụ trách quản lý lịch sử hội thoại và tương tác trực tiếp với mô hình ngôn ngữ lớn (Gemini LLM) phục vụ giải đáp thắc mắc ngữ pháp tiếng Anh.

#### 4.3.3.1 API Lấy danh sách cuộc trò chuyện của tôi (Get My Conversations)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/users/me/conversations`
*   **Mô tả:** Lấy danh sách tất cả các cuộc trò chuyện của người dùng hiện tại với Chatbot AI.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 201,
          "title": "Giải thích ngữ pháp Part 5",
          "createdAt": "2026-06-22T10:00:00.000Z"
        }
      ]
    }
    ```

#### 4.3.3.2 API Tạo cuộc trò chuyện mới (Start Conversation)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/conversations`
*   **Mô tả:** Tạo một phòng chat/phiên trò chuyện mới với Chatbot AI.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `title` | String | Có | Tiêu đề cuộc trò chuyện cần thiết lập ban đầu |
*   **Phản hồi thành công (201 Created):**
    ```json
    {
      "status": "success",
      "data": {
        "id": 202,
        "title": "Luyện dịch đoạn văn Part 6",
        "createdAt": "2026-06-22T20:50:00.000Z"
      }
    }
    ```

#### 4.3.3.3 API Lấy chi tiết cuộc trò chuyện (Get Conversation Details)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/conversations/:id`
*   **Mô tả:** Lấy thông tin cơ bản của một cuộc trò chuyện cụ thể theo ID.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID phòng trò chuyện cần xem |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "id": 202,
        "title": "Luyện dịch đoạn văn Part 6",
        "createdAt": "2026-06-22T20:50:00.000Z"
      }
    }
    ```

#### 4.3.3.4 API Cập nhật cuộc trò chuyện (Update Conversation)
*   **HTTP Method:** `PATCH`
*   **Endpoint:** `/api/v1/conversations/:id`
*   **Mô tả:** Cập nhật lại tiêu đề (title) của cuộc trò chuyện chỉ định.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID cuộc trò chuyện |
    | `title` | String | Có | Tiêu đề mới cần cập nhật |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Conversation updated successfully"
    }
    ```

#### 4.3.3.5 API Xóa cuộc trò chuyện (Delete Conversation)
*   **HTTP Method:** `DELETE`
*   **Endpoint:** `/api/v1/conversations/:id`
*   **Mô tả:** Xóa hoàn toàn một phòng trò chuyện và lịch sử tin nhắn đi kèm.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID cuộc trò chuyện cần xóa |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Conversation deleted successfully"
    }
    ```

#### 4.3.3.6 API Lấy danh sách tin nhắn trong cuộc trò chuyện (Get Messages)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/conversations/:conversationId/messages`
*   **Mô tả:** Tải lại toàn bộ lịch sử tin nhắn trong phòng trò chuyện chỉ định.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `conversationId`| Integer | Có | Path Param - ID cuộc trò chuyện |
    | `format` | String | Không | Query Param - `gemini` để chuyển đổi dạng cấu trúc role model phù hợp API Gemini |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "id": 1502,
          "role": "user",
          "content": "Tại sao câu 5 lại chọn B vậy bot?",
          "timestamp": "2026-06-22T20:51:00.000Z"
        },
        {
          "id": 1503,
          "role": "model",
          "content": "Chào bạn! Trong câu số 5, chúng ta cần một trạng từ để bổ nghĩa cho động từ 'run'...",
          "timestamp": "2026-06-22T20:51:10.000Z"
        }
      ]
    }
    ```

#### 4.3.3.7 API Gửi tin nhắn và Hỏi Chatbot AI (Send Message / Ask Chatbot)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/conversations/:conversationId/messages`
*   **Mô tả:** Gửi tin nhắn vào cuộc hội thoại. API này hỗ trợ 2 cơ chế dựa trên dữ liệu truyền vào:
    1. **Hỏi AI (Chatbot):** Truyền `rawText` để chatbot AI phân tích, giải thích và trả về câu trả lời.
    2. **Lưu tin nhắn thủ công:** Truyền `role` và `content` để lưu trữ trực tiếp tin nhắn vào cơ sở dữ liệu.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `conversationId` | Integer | Có | Path Param - ID cuộc trò chuyện |
    | `rawText` | String | Không | Bắt buộc nếu chọn cơ chế **Hỏi AI**. Nội dung câu hỏi gửi tới AI. |
    | `role` | String | Không | Bắt buộc nếu chọn cơ chế **Lưu tin nhắn thủ công** ('user' hoặc 'model'). |
    | `content` | String | Không | Bắt buộc nếu chọn cơ chế **Lưu tin nhắn thủ công**. Nội dung tin nhắn cần lưu. |
*   **Phản hồi thành công (201 Created / 200 OK):**
    *   **Trường hợp Hỏi AI (Chatbot):**
        ```json
        {
          "status": "success",
          "message": "AI response generated and saved",
          "data": {
            "count": 1,
            "results": [
              {
                "type": "General-AI",
                "source": "gemini",
                "answer": "Chào bạn! Đây là cách phân biệt:\n1. 'Affect' (Động từ): Gây ảnh hưởng...\n2. 'Effect' (Danh từ): Sự ảnh hưởng..."
              }
            ]
          }
        }
        ```
    *   **Trường hợp lưu tin nhắn thủ công:**
        ```json
        {
          "status": "success",
          "message": "Message created successfully",
          "data": {
            "id": 1504,
            "role": "user",
            "content": "Phân biệt giúp mình 'affect' và 'effect' với!"
          }
        }
        ```

---

### 4.3.4 Module Thống kê & Báo cáo học tập (Statistics & Analytics)
Module phục vụ việc vẽ biểu đồ tiến độ học tập trên dashboard của học viên.

#### 4.3.4.1 API Thống kê tổng quan số bài thi đã làm (Get User Test Stats)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/statistics/user-tests`
*   **Mô tả:** Trả về dữ liệu tổng quan bao gồm tổng số lượt làm bài, điểm trung bình, thời gian trung bình.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "totalAttempts": 12,
        "averageScore": 580,
        "maxScore": 750,
        "totalStudyTimeSeconds": 43200
      }
    }
    ```

#### 4.3.4.2 API Thống kê tỷ lệ chính xác theo từng Part TOEIC (Get Part Stats)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/statistics/parts`
*   **Mô tả:** Tính toán tỷ lệ làm đúng trên tổng số câu hỏi đã làm cho từng Part (từ Part 1 đến Part 7) của kỳ thi TOEIC.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "Part 1": 0.85,
        "Part 2": 0.72,
        "Part 3": 0.65,
        "Part 4": 0.58,
        "Part 5": 0.82,
        "Part 6": 0.60,
        "Part 7": 0.45
      }
    }
    ```

#### 4.3.4.3 API Thống kê tiến độ chính xác theo thời gian (Get Accuracy Over Time)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/statistics/accuracy-over-time`
*   **Mô tả:** Trả về mảng dữ liệu phân tích tỷ lệ làm bài chính xác theo từng ngày để vẽ biểu đồ đường (Line Chart).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `days` | Integer | Không | Query Param - Số lượng ngày muốn lấy thống kê (mặc định: 30) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        { "date": "2026-06-20", "accuracy": 0.65 },
        { "date": "2026-06-21", "accuracy": 0.70 },
        { "date": "2026-06-22", "accuracy": 0.74 }
      ]
    }
    ```

#### 4.3.4.4 API Lấy lịch sử tiến trình thi chi tiết (Get Detailed History Stats)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/statistics/user-test-history`
*   **Mô tả:** Danh sách phân trang đầy đủ toàn bộ lịch sử thi kèm điểm số, thời gian cụ thể của người dùng.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        {
          "attemptId": 58,
          "testTitle": "ETS 2023 Test 1",
          "score": 620,
          "correctCount": 65,
          "totalQuestions": 100,
          "durationSeconds": 3600,
          "date": "2026-06-22T20:45:00.000Z"
        }
      ]
    }
    ```

---

### 4.3.5 Module Quản lý Tệp tải lên (Media Upload Management)
Module hỗ trợ lưu trữ tệp tin đa phương tiện của đề thi (ảnh câu hỏi, file âm thanh nghe) thông qua dịch vụ đám mây Cloudinary.

#### 4.3.5.1 API Upload hình ảnh lên Cloudinary (Upload Image)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/uploads/images`
*   **Mô tả:** Tải lên tệp ảnh minh họa cho câu hỏi trắc nghiệm.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `file` | File Binary | Có | Tệp hình ảnh cần upload (gửi dưới dạng Multipart Form-Data) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "url": "https://res.cloudinary.com/demo/image/upload/v12345/toeic_img.jpg",
        "publicId": "toeic_img"
      }
    }
    ```

#### 4.3.5.2 API Upload âm thanh lên Cloudinary (Upload Audio)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/uploads/audio`
*   **Mô tả:** Tải lên tệp âm thanh định dạng `.mp3`/`.wav` phục vụ phần thi Listening.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `file` | File Binary | Có | Tệp audio cần upload (gửi dưới dạng Multipart Form-Data) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "url": "https://res.cloudinary.com/demo/video/upload/v12345/toeic_audio.mp3",
        "publicId": "toeic_audio"
      }
    }
    ```

#### 4.3.5.3 API Xóa file đã upload trên Cloudinary (Delete Uploaded File)
*   **HTTP Method:** `DELETE`
*   **Endpoint:** `/api/v1/uploads/:publicId`
*   **Mô tả:** Xóa một file ảnh hoặc âm thanh khỏi lưu trữ đám mây Cloudinary.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `publicId` | String | Có | Path Param - ID công khai của tệp trên Cloudinary |
    | `resourceType`| String | Có | Query Param - Định dạng tài nguyên (`image` hoặc `video`) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "File deleted successfully"
    }
    ```

#### 4.3.5.4 API Upload hàng loạt từ Local Path (Batch Upload)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/uploads/batch`
*   **Mô tả:** Cho phép quản trị viên tải tệp hàng loạt lên từ thư mục cục bộ của máy chủ *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `localFolderPath`| String | Có | Đường dẫn thư mục cục bộ chứa các tệp trên máy chủ |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Batch upload completed",
      "data": {
        "successCount": 15,
        "failedCount": 0
      }
    }
    ```

#### 4.3.5.5 API Kiểm tra đường dẫn thư mục local (Validate Local Paths)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/uploads/validate-paths`
*   **Mô tả:** Kiểm tra các tệp tin trong thư mục có tồn tại hợp lệ hay không trước khi thực hiện batch upload *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `paths` | Array | Có | Mảng chứa danh sách đường dẫn các tệp cần kiểm tra |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "valid": true,
        "missingPaths": []
      }
    }
    ```

---

### 4.3.6 Module Gợi ý học tập & Máy học (Machine Learning Recommendation)
Module kết nối với thuật toán Python ML ở backend để phân tích điểm yếu học tập và gợi ý đề thi.

#### 4.3.6.1 API Gợi ý ID câu hỏi dựa trên phân tích kỹ năng (Get ML Recommendations)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/ml/recommend/:userId`
*   **Mô tả:** Phân tích lịch sử làm bài để gợi ý các ID câu hỏi có kỹ năng người dùng còn yếu.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `userId` | Integer | Có | Path Param - ID của người dùng cần được gợi ý bài |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "weakSkills": ["Gerunds", "Relative Clauses"],
        "recommendedQuestionIds": [105, 203, 114]
      }
    }
    ```

#### 4.3.6.2 API Gợi ý chi tiết câu hỏi (Get Recommendation Details)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/ml/recommend/details/:userId`
*   **Mô tả:** Gọi thuật toán ML gợi ý đồng thời kết xuất đầy đủ chi tiết nội dung các câu hỏi tương ứng để hiển thị thẳng lên UI.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `userId` | Integer | Có | Path Param - ID của người dùng |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "userId": 15,
        "recommendations": [
          {
            "id": 105,
            "questionText": "By the time the manager arrived, the employees ______ the report.",
            "optionA": "finish",
            "optionB": "finished",
            "optionC": "had finished",
            "optionD": "has finished",
            "correctAnswer": "C",
            "partId": 5
          }
        ]
      }
    }
    ```

#### 4.3.6.3 API Huấn luyện lại mô hình gợi ý (Retrain ML Models)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/ml/retrain`
*   **Mô tả:** Yêu cầu mô hình Python ML cập nhật tập huấn luyện và chạy lại thuật toán nâng cấp chất lượng gợi ý *(Chỉ dành cho Admin)*.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Model retraining initialized successfully"
    }
    ```

---

### 4.3.7 Module Từ vựng (Vocabulary Management)
Module hỗ trợ tra cứu từ vựng và lưu trữ bộ từ vựng luyện thi.

#### 4.3.7.1 API Lấy danh sách từ vựng (Get Vocabulary List)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/vocabulary`
*   **Mô tả:** Lấy danh sách các từ vựng phục vụ thi TOEIC đang lưu trên hệ thống.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | Không có | - | - | - |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        { "id": 1, "word": "Collaborate", "pos": "v", "meaning": "Hợp tác" },
        { "id": 2, "word": "Innovative", "pos": "adj", "meaning": "Mang tính sáng tạo" }
      ]
    }
    ```

#### 4.3.7.2 API Lấy chi tiết từ vựng theo ID (Get Vocabulary Details)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/vocabulary/:id`
*   **Mô tả:** Lấy chi tiết định nghĩa, phiên âm, ví dụ của từ vựng chỉ định theo ID.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Có | Path Param - ID của từ vựng |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "id": 1,
        "word": "Collaborate",
        "pos": "verb",
        "phonetic": "/kəˈlæb.ə.reɪt/",
        "meaning": "Hợp tác, cộng tác làm việc",
        "example": "Researchers are collaborating to develop the software."
      }
    }
    ```

#### 4.3.7.3 API Tìm kiếm hoặc tra cứu từ vựng (Find/Fetch Vocabulary)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/vocabulary/word/:word`
*   **Mô tả:** Tìm kiếm từ vựng chỉ định bằng text, nếu chưa có trong DB hệ thống sẽ tiến hành tự động lấy (crawl) định nghĩa từ API ngoài và lưu lại.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `word` | String | Có | Path Param - Từ vựng cần tìm kiếm |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": {
        "word": "Dynamic",
        "pos": "adjective",
        "meaning": "Năng động, sôi nổi"
      }
    }
    ```

---

### 4.3.8 Module Quản trị Metadata (Admin Metadata)
Hỗ trợ quản trị viên quản lý danh mục cấu trúc đề thi TOEIC.

#### 4.3.8.1 API Quản lý danh mục Part (GET/POST/PUT/DELETE Parts)
*   **HTTP Method:** `GET`, `POST`, `PUT`, `DELETE`
*   **Endpoints:**
    *   `GET /api/adminMetadata/parts`: Xem tất cả Parts.
    *   `POST /api/adminMetadata/parts`: Tạo Part mới.
    *   `PUT /api/adminMetadata/parts/:id`: Cập nhật Part.
    *   `DELETE /api/adminMetadata/parts/:id`: Xóa Part.
*   **Mô tả:** Quản lý cấu trúc các Phần (Parts 1-7) trong đề thi TOEIC.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Không | Path Param - ID của Part (Yêu cầu đối với các phương thức PUT, DELETE) |
    | `name` | String | Không | Tên Part mới cần cập nhật hoặc tạo mới (Ví dụ: "Part 1: Photographs") |
    | `description`| String | Không | Nội dung mô tả chi tiết của Part |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Part action successfully executed",
      "data": []
    }
    ```

#### 4.3.8.2 API Quản lý dạng câu hỏi - Question Type (GET/POST/PUT/DELETE Types)
*   **HTTP Method:** `GET`, `POST`, `PUT`, `DELETE`
*   **Endpoints:**
    *   `GET /api/adminMetadata/types`: Xem các dạng câu hỏi.
    *   `POST /api/adminMetadata/types`: Tạo mới dạng câu hỏi.
    *   `PUT /api/adminMetadata/types/:id`: Cập nhật dạng câu hỏi.
    *   `DELETE /api/adminMetadata/types/:id`: Xóa dạng câu hỏi.
*   **Mô tả:** Quản lý các dạng câu hỏi cụ thể (ví dụ: Tìm lỗi sai, Điền từ).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Không | Path Param - ID của Question Type (Cần cho PUT, DELETE) |
    | `typeName` | String | Không | Tên dạng câu hỏi mới (Cần cho POST, PUT) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Question Type action successfully executed"
    }
    ```

#### 4.3.8.3 API Quản lý kỹ năng - Skill (GET/POST/PUT/DELETE Skills)
*   **HTTP Method:** `GET`, `POST`, `PUT`, `DELETE`
*   **Endpoints:**
    *   `GET /api/adminMetadata/skills`: Xem danh sách Kỹ năng.
    *   `POST /api/adminMetadata/skills`: Tạo mới Kỹ năng.
    *   `PUT /api/adminMetadata/skills/:id`: Cập nhật Kỹ năng.
    *   `DELETE /api/adminMetadata/skills/:id`: Xóa Kỹ năng.
*   **Mô tả:** Quản lý các kỹ năng thi tiếng Anh (Listening, Reading, Grammar, Vocabulary).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `id` | Integer | Không | Path Param - ID kỹ năng (Cần cho PUT, DELETE) |
    | `skillName` | String | Không | Tên kỹ năng mới (Cần cho POST, PUT) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Skill action successfully executed"
    }
    ```

---

### 4.3.9 Module Quản trị Người dùng (Admin User Management)
Module hỗ trợ quản lý phân quyền và kiểm soát tài khoản người học.

#### 4.3.9.1 API Lấy danh sách tất cả người dùng (Get All Users)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/admin-users`
*   **Mô tả:** Lấy danh sách toàn bộ các tài khoản người dùng trong hệ thống.
*   **Tham số yêu cầu:** Không có.
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "data": [
        { "id": 1, "username": "admin", "email": "admin@toeic.com", "role_id": 2 },
        { "id": 15, "username": "tuanhung", "email": "hung@example.com", "role_id": 1 }
      ]
    }
    ```

#### 4.3.9.2 API Cập nhật/Chỉnh sửa thông tin người dùng (Update User - Role/Lock/General Info)
*   **HTTP Method:** `PATCH`
*   **Endpoint:** `/api/admin-users/{userId}`
*   **Mô tả:** Cập nhật thông tin chi tiết của người dùng theo ID, bao gồm thay đổi vai trò (role), khóa/mở khóa tài khoản (lock status), hoặc thay đổi thông tin chung (username, email).
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `username` | String | Không | Tên tài khoản mới |
    | `email` | String | Không | Địa chỉ email mới |
    | `role_id` | Integer | Không | ID vai trò mới (1: Student/User, 2: Admin) |
    | `status` | Boolean | Không | Trạng thái hoạt động tài khoản (`true` để kích hoạt, `false` để khóa) |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Cập nhật thông tin người dùng thành công",
      "user": {
        "id": 15,
        "username": "tuanhung",
        "email": "hung@example.com",
        "role_id": 1,
        "status": true
      }
    }
    ```

#### 4.3.9.3 API Xóa tài khoản người dùng (Delete User)
*   **HTTP Method:** `DELETE`
*   **Endpoint:** `/api/admin-users/{userId}`
*   **Mô tả:** Xóa vĩnh viễn tài khoản người dùng chỉ định ra khỏi hệ thống.
*   **Tham số yêu cầu (Path Parameter):**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `userId` | Integer | Có | ID của người dùng cần xóa bỏ |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Xoá người dùng thành công"
    }
    ```

---

### 4.3.10 Module Thanh toán và Gói cước VIP (Payment & VIP Subscription)
Cung cấp các API phục vụ tích hợp cổng thanh toán (ZaloPay, MoMo) để nâng cấp tài khoản VIP của người dùng.

#### 4.3.10.1 API Lấy danh sách gói cước VIP (Get VIP Subscriptions)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/payments/subscriptions`
*   **Mô tả:** Lấy toàn bộ danh sách các gói cước VIP hiện có hỗ trợ trong hệ thống.
*   **Tham số yêu cầu:** Không có.
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Lấy danh sách gói cước thành công",
      "data": [
        {
          "id": 1,
          "name": "Gói VIP 1 Tháng",
          "price": "99000.00",
          "durationDays": 30,
          "description": "Thời hạn sử dụng 30 ngày"
        }
      ]
    }
    ```

#### 4.3.10.2 API Lấy trạng thái VIP hiện tại (Get VIP Status)
*   **HTTP Method:** `GET`
*   **Endpoint:** `/api/v1/payments/vip-status`
*   **Mô tả:** Lấy thông tin trạng thái VIP, ngày hết hạn và số lượt chat còn lại trong ngày của tài khoản hiện tại.
*   **Yêu cầu xác thực:** Đính kèm Access Token trong Authorization header.
*   **Tham số yêu cầu:** Không có.
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Lấy trạng thái tài khoản thành công",
      "data": {
        "userId": 6,
        "isVip": true,
        "vipExpireAt": "2026-07-23T18:14:15.175Z",
        "chatLimitToday": -1,
        "chatCountToday": 5,
        "remainingChatsToday": -1
      }
    }
    ```

#### 4.3.10.3 API Khởi tạo giao dịch thanh toán (Create Payment Order)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/payments/create`
*   **Mô tả:** Tạo đơn hàng thanh toán nâng cấp VIP và sinh link thanh toán/mã QR của cổng thanh toán tương ứng.
*   **Yêu cầu xác thực:** Đính kèm Access Token trong Authorization header.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `subscriptionId` | Integer | Có | ID của gói cước VIP người dùng chọn |
    | `paymentGateway` | String | Có | Cổng thanh toán muốn sử dụng (`zalopay` hoặc `momo`) |
    | `returnUrl` | String | Không | URL để chuyển hướng người dùng sau khi giao dịch hoàn tất trên giao diện Web |
*   **Phản hồi thành công (200 OK):**
    ```json
    {
      "status": "success",
      "message": "Khởi tạo thanh toán thành công",
      "data": {
        "transactionId": 12,
        "orderId": "260623_VIP_6_1782213227183",
        "amount": 99000,
        "paymentGateway": "zalopay",
        "paymentUrl": "https://sb-openapi.zalopay.vn/v2/checkout?order=..."
      }
    }
    ```

#### 4.3.10.4 Webhook nhận kết quả thanh toán từ ZaloPay (ZaloPay Callback)
*   **HTTP Method:** `POST`
*   **Endpoint:** `/api/v1/payments/zalopay-callback`
*   **Mô tả:** Webhook nhận kết quả thanh toán bất đồng bộ (callback) từ hệ thống máy chủ ZaloPay. Sử dụng chữ ký MAC xác thực tính toàn vẹn dữ liệu và tự động kích hoạt tài khoản VIP của người dùng.
*   **Tham số yêu cầu:**
    | Tham số | Kiểu dữ liệu | Bắt buộc | Mô tả |
    | :--- | :--- | :--- | :--- |
    | `data` | String | Có | Chuỗi JSON chứa thông tin chi tiết giao dịch từ ZaloPay |
    | `mac` | String | Có | Chữ ký điện tử bảo mật đi kèm để đối chiếu kiểm tra |
*   **Phản hồi thành công (200 OK - Trả về ZaloPay):**
    ```json
    {
      "return_code": 1,
      "return_message": "success"
    }
    ```

---

# 5. Đặc Tả Cơ Chế Phân Quyền & Bảo Mật Hệ Thống (Authorization & Security)

Hệ thống chatbot TOEIC áp dụng các tiêu chuẩn bảo mật hiện đại nhằm ngăn chặn các lỗ hổng bảo mật nghiêm trọng thường gặp (OWASP Top 10):

## 5.1 Cơ chế Xác thực (Authentication)
*   Sử dụng **JWT (JSON Web Token) Access Token** đính kèm qua tiêu đề HTTP `Authorization: Bearer <token>` hoặc lưu trữ qua `HTTP-only Cookie` để bảo mật tối đa.
*   Thời gian hết hạn của Access Token ngắn giúp giảm thiểu rủi ro khi token bị đánh cắp.

## 5.2 Cơ chế Phân quyền vai trò (Role-based Access Control - RBAC)
*   Hệ thống xác định vai trò thông qua trường dữ liệu `role_id` từ Token đã xác thực:
    *   `role_id: 1` — **Student/User** (Người dùng thông thường): Có quyền làm đề thi, xem thống kê bản thân, trò chuyện với Chatbot, thanh toán VIP.
    *   `role_id: 2` — **Admin** (Quản trị viên): Toàn quyền quản trị hệ thống, quản lý người dùng, quản lý đề thi/câu hỏi/khóa học và huấn luyện mô hình AI.
*   **Vá lỗ hổng Phân quyền theo chức năng (Broken Function Level Authorization - BFLA):**
    *   Tất cả các API chỉnh sửa dữ liệu liên quan tới quản trị đề thi, khóa học, dữ liệu cấu trúc đề (Part, Skill, Type) và API kích hoạt train lại mô hình AI (`POST /api/ml/retrain`) đều được bảo vệ nghiêm ngặt bằng lớp middleware kép `authMiddleware` và `adminMiddleware`.
    *   Học sinh thường gửi gói tin giả mạo quyền Admin lên các route này sẽ nhận về mã lỗi **`403 Forbidden`**.

## 5.3 Ngăn chặn lỗ hổng Truy cập Đối tượng Trực tiếp (Broken Object Level Authorization - IDOR)
Hệ thống thực hiện kiểm tra quyền sở hữu đối tượng ở cấp ứng dụng nhằm ngăn chặn việc người dùng này sửa hoặc đọc thông tin của người dùng khác:
1.  **Thông tin cá nhân (Profile detail & Update):** API `/api/account/detail/:id` và `/api/account/update/:id` đối chiếu `id` trong URL với `req.user.id` từ Token. Người dùng chỉ có quyền đọc/ghi dữ liệu của chính mình (hoặc Admin).
2.  **Lịch sử hội thoại (Chat History & Chatbot ask):** Tất cả các API đọc tin nhắn, gửi tin nhắn, hoặc truy vấn lịch sử hội thoại của Chatbot đều thực hiện kiểm tra quyền sở hữu: chỉ có chủ nhân của `conversationId` mới được tương tác với cuộc trò chuyện đó.
3.  **Kết quả bài thi (Test Attempt Result detail):** Khi người dùng gọi API lấy kết quả chi tiết của lượt làm bài thi (`/api/v1/test-attempts/:attemptId/result` hoặc `/api/questionTest/DetailResult/:userTestId`), hệ thống sẽ kiểm tra xem `userId` trong bản ghi bài thi có khớp với `req.user.id` của người gửi yêu cầu hay không. Nếu không khớp và không phải Admin, yêu cầu sẽ bị từ chối với lỗi **`403 Forbidden`**.


