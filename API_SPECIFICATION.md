# API Specification — Chatbot TOEIC Backend

**Version:** 2.0.0
**Base URL:** `http://localhost:8080/api`
**Interactive Docs:** `http://localhost:8080/api/docs` (Swagger UI — requires backend running)
**Last Updated:** August 2026

---

## Overview

This document provides the complete REST API specification for the Chatbot TOEIC backend system. All endpoints are exposed through the **Nginx API Gateway** on port `8080`.

### Authentication

All protected endpoints require a Bearer token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

Access tokens are obtained from the `/api/v1/auth/login` or `/api/v1/auth/google` endpoints.

### Standard Response Format

All API responses follow this envelope structure:

```json
{
  "code": 200,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "code": 400,
  "message": "Error description",
  "details": ["specific error detail"]
}
```

### HTTP Status Codes

| Code | Meaning |
|---|---|
| `200` | Success |
| `201` | Resource created |
| `400` | Bad request / validation error |
| `401` | Unauthorized (missing or invalid token) |
| `403` | Forbidden (insufficient permissions) |
| `404` | Resource not found |
| `409` | Conflict (e.g., email already exists) |
| `429` | Too many requests (rate limited) |
| `500` | Internal server error |

---

## Table of Contents

1. [Authentication API](#1-authentication-api)
2. [Account API](#2-account-api)
3. [Test API](#3-test-api)
4. [Course API](#4-course-api)
5. [Statistics API](#5-statistics-api)
6. [Media Upload API](#6-media-upload-api)
7. [Chatbot API](#7-chatbot-api)
8. [Payment API](#8-payment-api)
9. [ML Recommendation API](#9-ml-recommendation-api)
10. [Admin - User Management API](#10-admin---user-management-api)
11. [Admin - Test Management API](#11-admin---test-management-api)
12. [Admin - Metadata API](#12-admin---metadata-api)
13. [Internal API](#13-internal-api)

---

## 1. Authentication API

**Service:** auth-service | **Base:** `/api/v1/auth`

---

### POST /api/v1/auth/register/send-otp

Send a registration OTP to the user's email before creating an account.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "OTP sent successfully",
  "data": null
}
```

---

### POST /api/v1/auth/register/verify-otp

Verify OTP before finalizing registration.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "OTP verified successfully",
  "data": null
}
```

---

### POST /api/v1/auth/register

Register a new user account.

**Auth Required:** No

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "Password@123"
}
```

**Validation Rules:**
- `username`: Required, 3-50 characters
- `email`: Required, valid email format, unique
- `password`: Required, minimum 8 characters

**Response 201:**
```json
{
  "code": 201,
  "message": "User registered successfully",
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

**Error 409:** Email already exists

---

### POST /api/v1/auth/login

Authenticate user and receive JWT tokens.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "Password@123"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "role_id": 2,
      "isVip": false,
      "vipExpireAt": null
    }
  }
}
```

**Error 401:** Invalid credentials or account locked

---

### POST /api/v1/auth/google

Sign in or register via Google OAuth 2.0.

**Auth Required:** No

**Request Body:**
```json
{
  "idToken": "google_id_token_string"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Google login successful",
  "data": {
    "accessToken": "...",
    "refreshToken": "...",
    "user": { ... }
  }
}
```

---

### POST /api/v1/auth/refresh

Refresh an expired access token using a valid refresh token.

**Auth Required:** No

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error 401:** Invalid or expired refresh token

---

### POST /api/v1/auth/logout

Invalidate refresh token and log out.

**Auth Required:** No (optional token)

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Logged out successfully",
  "data": null
}
```

---

### GET /api/v1/auth/me

Get current logged-in user information.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "User info retrieved",
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "avatar": "https://res.cloudinary.com/...",
    "role_id": 2,
    "isVip": true,
    "vipExpireAt": "2026-09-23T00:00:00.000Z"
  }
}
```

---

### PUT /api/v1/auth/password

Change current user's password.

**Auth Required:** Yes

**Request Body:**
```json
{
  "currentPassword": "OldPassword@123",
  "newPassword": "NewPassword@456"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Password changed successfully",
  "data": null
}
```

**Error 400:** Current password incorrect

---

### POST /api/v1/auth/password/forgot

Request an OTP for password reset via email.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "OTP sent to email",
  "data": null
}
```

**Error 404:** Email not found

---

### POST /api/v1/auth/password/reset

Reset password using OTP received by email.

**Auth Required:** No

**Request Body:**
```json
{
  "email": "john@example.com",
  "otp": "123456",
  "newPassword": "NewPassword@456"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Password reset successfully",
  "data": null
}
```

**Error 400:** Invalid or expired OTP

---

## 2. Account API

**Service:** auth-service | **Base:** `/api/account`

---

### GET /api/account/detail/:id

Get user profile by ID.

**Auth Required:** Yes

**Path Parameters:**
- `id` (integer): User ID

**Response 200:**
```json
{
  "code": 200,
  "message": "User retrieved",
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "avatar": "https://res.cloudinary.com/...",
    "role_id": 2,
    "status": true
  }
}
```

---

### PUT /api/account/update/:id

Update user profile information.

**Auth Required:** Yes

**Path Parameters:**
- `id` (integer): User ID

**Request Body (multipart/form-data or JSON):**
```json
{
  "username": "johndoe_updated",
  "avatar": "https://cloudinary-url/image.jpg"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Profile updated successfully",
  "data": { ... }
}
```

---

### POST /api/account/verify-email-otp

Verify OTP for email change.

**Auth Required:** Yes

**Request Body:**
```json
{
  "otp": "123456",
  "newEmail": "newemail@example.com"
}
```

---

## 3. Test API

**Service:** quiz-service | **Base:** `/api/v1`

---

### GET /api/v1/tests

Get paginated list of available TOEIC tests.

**Auth Required:** Yes

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | integer | 1 | Current page number |
| `limit` | integer | 10 | Items per page |
| `courseId` | integer | - | Filter by course ID |
| `type` | string | - | Filter by test type (`listening`, `reading`, `mixed`) |

**Response 200:**
```json
{
  "code": 200,
  "message": "Tests retrieved",
  "data": {
    "tests": [
      {
        "id": 1,
        "title": "TOEIC Practice Test #1",
        "type": "mixed",
        "duration": "120 minutes",
        "questionCount": 200,
        "courseId": 1,
        "createdAt": "2025-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "totalItems": 25,
      "totalPages": 3,
      "currentPage": 1,
      "limit": 10
    }
  }
}
```

---

### GET /api/v1/tests/:testId/questions

Get all questions for a specific test.

**Auth Required:** Yes

**Path Parameters:**
- `testId` (integer): Test ID

**Response 200:**
```json
{
  "code": 200,
  "message": "Questions retrieved",
  "data": {
    "testId": 1,
    "title": "TOEIC Practice Test #1",
    "questions": [
      {
        "id": 101,
        "content": "What are the people doing?",
        "imageUrl": "https://res.cloudinary.com/...",
        "audioUrl": "https://res.cloudinary.com/...",
        "partId": 1,
        "questionType": "Photographs",
        "options": {
          "A": "They are reading books.",
          "B": "They are working in an office.",
          "C": "They are eating lunch.",
          "D": "They are walking outside."
        },
        "orderIndex": 1
      }
    ]
  }
}
```

---

### POST /api/v1/tests/:testId/questions

Add a question to a test (Admin only).

**Auth Required:** Yes (Admin)

**Request Body:**
```json
{
  "content": "What is the main topic of the conversation?",
  "partId": 3,
  "correctAnswer": "B",
  "options": {
    "A": "A job interview",
    "B": "A business meeting",
    "C": "A lunch break",
    "D": "A phone call"
  },
  "explanation": "The speakers discuss agenda items for a meeting."
}
```

**Response 201:**
```json
{
  "code": 201,
  "message": "Question created",
  "data": { "id": 201, ... }
}
```

---

### POST /api/v1/tests/:testId/attempts

Start a new test attempt.

**Auth Required:** Yes

**Path Parameters:**
- `testId` (integer): Test ID

**Response 200:**
```json
{
  "code": 200,
  "message": "Attempt started",
  "data": {
    "attemptId": 55,
    "testId": 1,
    "status": "in_progress",
    "startedAt": "2026-08-23T09:00:00.000Z"
  }
}
```

---

### PATCH /api/v1/tests/:testId/attempts/:attemptId

Submit or cancel a test attempt.

**Auth Required:** Yes

**Path Parameters:**
- `testId` (integer): Test ID
- `attemptId` (integer): Attempt ID

**Request Body — Submit:**
```json
{
  "status": "completed",
  "answers": {
    "101": "B",
    "102": "A",
    "103": "C"
  },
  "timeSpent": 3600
}
```

**Request Body — Cancel:**
```json
{
  "status": "cancelled"
}
```

**Response 200 (Submit):**
```json
{
  "code": 200,
  "message": "Test submitted successfully",
  "data": {
    "attemptId": 55,
    "score": 785,
    "listeningScore": 395,
    "readingScore": 390,
    "totalCorrect": 157,
    "totalQuestions": 200,
    "timeSpent": 3600,
    "partResults": [
      { "partId": 1, "correct": 6, "total": 6 },
      { "partId": 2, "correct": 25, "total": 30 }
    ]
  }
}
```

---

### GET /api/v1/tests/:testId/attempts/latest

Check the status of the user's most recent attempt for a test.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Latest attempt retrieved",
  "data": {
    "attemptId": 55,
    "status": "in_progress",
    "startedAt": "2026-08-23T09:00:00.000Z"
  }
}
```

---

### GET /api/v1/tests/:testId/attempts/history

Get all past attempts for a specific test.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "History retrieved",
  "data": [
    {
      "attemptId": 55,
      "score": 785,
      "status": "completed",
      "timeSpent": 3600,
      "submittedAt": "2026-08-20T10:30:00.000Z"
    }
  ]
}
```

---

### GET /api/v1/test-attempts/:attemptId/result

Get detailed result of a specific attempt (with answers and explanations).

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Result retrieved",
  "data": {
    "attemptId": 55,
    "score": 785,
    "questions": [
      {
        "questionId": 101,
        "userAnswer": "B",
        "correctAnswer": "B",
        "isCorrect": true,
        "explanation": "The image shows two people shaking hands in an office."
      }
    ]
  }
}
```

---

### POST /api/v1/practice-attempts

Submit a single-question practice answer.

**Auth Required:** Yes

**Request Body:**
```json
{
  "questionId": 101,
  "selectedAnswer": "B"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Practice answer recorded",
  "data": {
    "isCorrect": true,
    "correctAnswer": "B",
    "explanation": "..."
  }
}
```

---

### PATCH /api/v1/questions/:id

Update a question (Admin only).

**Auth Required:** Yes (Admin)

**Request Body:**
```json
{
  "content": "Updated question text",
  "correctAnswer": "C",
  "explanation": "Updated explanation"
}
```

---

### PATCH /api/v1/tests/:id

Update test metadata (Admin only).

**Auth Required:** Yes (Admin)

**Request Body:**
```json
{
  "title": "Updated Test Title",
  "duration": "90 minutes"
}
```

---

## 4. Course API

**Service:** quiz-service | **Base:** `/api/v1/courses`

---

### GET /api/v1/courses

Get all available courses.

**Auth Required:** Yes

**Query Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `include` | string | `tests` — include test list per course |

**Response 200:**
```json
{
  "code": 200,
  "message": "Courses retrieved",
  "data": [
    {
      "id": 1,
      "name": "TOEIC 600+",
      "tests": [ ... ]
    }
  ]
}
```

---

### GET /api/v1/courses/:id/tests

Get all tests within a specific course.

**Auth Required:** Yes

---

### POST /api/v1/courses

Create a new course (Admin only).

**Auth Required:** Yes (Admin)

**Request Body:**
```json
{
  "name": "TOEIC 990 VIP"
}
```

**Response 201:**
```json
{
  "code": 201,
  "message": "Course created",
  "data": { "id": 5, "name": "TOEIC 990 VIP" }
}
```

---

### PATCH /api/v1/courses/:id

Update course information (Admin only).

**Auth Required:** Yes (Admin)

---

### DELETE /api/v1/courses/:id

Delete a course (Admin only).

**Auth Required:** Yes (Admin)

---

## 5. Statistics API

**Service:** quiz-service | **Base:** `/api/v1/statistics`

---

### GET /api/v1/statistics/user-tests

Get overall learning statistics for the current user.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Statistics retrieved",
  "data": {
    "totalTests": 12,
    "totalCompleted": 10,
    "averageScore": 712,
    "highestScore": 810,
    "totalTimeSpent": 86400,
    "lastTestDate": "2026-08-20T10:30:00.000Z"
  }
}
```

---

### GET /api/v1/statistics/parts

Get accuracy breakdown per TOEIC part.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Part stats retrieved",
  "data": [
    { "partId": 1, "partName": "Photographs", "correct": 58, "total": 60, "accuracy": 96.7 },
    { "partId": 2, "partName": "Question-Response", "correct": 210, "total": 250, "accuracy": 84.0 },
    { "partId": 3, "partName": "Conversations", "correct": 145, "total": 190, "accuracy": 76.3 }
  ]
}
```

---

### GET /api/v1/statistics/accuracy-over-time

Get accuracy trend over time.

**Auth Required:** Yes

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `days` | integer | 30 | Number of past days to include |

**Response 200:**
```json
{
  "code": 200,
  "message": "Accuracy trend retrieved",
  "data": [
    { "date": "2026-07-23", "accuracy": 72.5, "testsCount": 2 },
    { "date": "2026-07-30", "accuracy": 78.0, "testsCount": 3 }
  ]
}
```

---

### GET /api/v1/statistics/user-test-history

Get full test history for the current user.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "History retrieved",
  "data": [
    {
      "attemptId": 55,
      "testTitle": "TOEIC Practice Test #1",
      "score": 785,
      "timeSpent": 3600,
      "completedAt": "2026-08-20T10:30:00.000Z"
    }
  ]
}
```

---

## 6. Media Upload API

**Service:** quiz-service | **Base:** `/api/v1/uploads`

---

### POST /api/v1/uploads/images

Upload an image file to Cloudinary.

**Auth Required:** Yes
**Content-Type:** `multipart/form-data`

**Form Fields:**
| Field | Type | Required | Description |
|---|---|---|---|
| `file` | binary | Yes | Image file (JPEG, PNG, WebP; max 50MB) |

**Response 200:**
```json
{
  "code": 200,
  "message": "Image uploaded successfully",
  "data": {
    "url": "https://res.cloudinary.com/degzfp5hs/image/upload/v1234/question_images/img_abc.jpg",
    "publicId": "question_images/img_abc",
    "width": 800,
    "height": 600
  }
}
```

---

### POST /api/v1/uploads/audio

Upload an audio file to Cloudinary.

**Auth Required:** Yes
**Content-Type:** `multipart/form-data`

**Form Fields:**
| Field | Type | Required | Description |
|---|---|---|---|
| `file` | binary | Yes | Audio file (MP3, WAV; max 50MB) |

**Response 200:**
```json
{
  "code": 200,
  "message": "Audio uploaded successfully",
  "data": {
    "url": "https://res.cloudinary.com/degzfp5hs/video/upload/v1234/audio/track_abc.mp3",
    "publicId": "audio/track_abc",
    "duration": 45.2
  }
}
```

---

### DELETE /api/v1/uploads/:publicId

Delete a media file from Cloudinary.

**Auth Required:** Yes

**Path Parameters:**
- `publicId` (string, URL-encoded): Cloudinary public ID

**Query Parameters:**
| Parameter | Type | Values | Description |
|---|---|---|---|
| `resourceType` | string | `image`, `video` | Media type (`video` for audio files) |

**Response 200:**
```json
{
  "code": 200,
  "message": "File deleted successfully",
  "data": null
}
```

---

### POST /api/v1/uploads/batch

Batch upload from local file paths (Admin tool).

**Auth Required:** Yes

**Request Body:**
```json
{
  "files": [
    { "path": "D:/audio/part1_q1.mp3", "type": "audio" },
    { "path": "D:/images/part1_q1.jpg", "type": "image" }
  ]
}
```

---

### POST /api/v1/uploads/validate-paths

Validate that local file paths exist before batch upload.

**Auth Required:** Yes

**Request Body:**
```json
{
  "paths": [
    "D:/audio/part1_q1.mp3",
    "D:/images/part1_q1.jpg"
  ]
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Validation complete",
  "data": {
    "valid": ["D:/audio/part1_q1.mp3"],
    "invalid": ["D:/images/part1_q1.jpg"]
  }
}
```

---

## 7. Chatbot API

**Service:** chatbot-service | **Base:** `/api/v1`

**VIP Note:** Free users are limited to **15 messages per day**. VIP users have unlimited access.

---

### GET /api/v1/users/me/conversations

Get all conversations for the current user.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Conversations retrieved",
  "data": [
    {
      "id": 1,
      "title": "Grammar Questions",
      "createdAt": "2026-08-01T10:00:00.000Z",
      "updatedAt": "2026-08-20T15:30:00.000Z"
    }
  ]
}
```

---

### POST /api/v1/conversations

Create a new conversation.

**Auth Required:** Yes

**Request Body:**
```json
{
  "title": "My TOEIC Questions"
}
```

**Response 201:**
```json
{
  "code": 201,
  "message": "Conversation created",
  "data": {
    "id": 5,
    "title": "My TOEIC Questions",
    "userId": 1
  }
}
```

---

### GET /api/v1/conversations/:id

Get conversation details.

**Auth Required:** Yes

---

### PATCH /api/v1/conversations/:id

Rename a conversation.

**Auth Required:** Yes

**Request Body:**
```json
{
  "title": "Updated Title"
}
```

---

### DELETE /api/v1/conversations/:id

Delete a conversation and all its messages.

**Auth Required:** Yes

---

### GET /api/v1/conversations/:conversationId/messages

Get all messages in a conversation.

**Auth Required:** Yes

**Query Parameters:**
| Parameter | Type | Values | Description |
|---|---|---|---|
| `format` | string | `gemini` | Return messages in Gemini history format |

**Response 200:**
```json
{
  "code": 200,
  "message": "Messages retrieved",
  "data": [
    { "id": 1, "role": "user", "content": "What is past tense?", "createdAt": "..." },
    { "id": 2, "role": "model", "content": "Past tense describes...", "createdAt": "..." }
  ]
}
```

---

### POST /api/v1/conversations/:conversationId/messages

Send a message. If `rawText` is provided, triggers the AI chatbot.

**Auth Required:** Yes
**VIP Check:** Applied when `rawText` is provided

**Request Body — Ask AI:**
```json
{
  "rawText": "Explain the difference between present perfect and simple past."
}
```

**Request Body — Save manual message:**
```json
{
  "role": "user",
  "content": "This is a manually saved message."
}
```

**Response 200 (AI response):**
```json
{
  "code": 200,
  "message": "Chatbot response generated",
  "data": {
    "id": 10,
    "role": "model",
    "content": "The present perfect tense is used when...",
    "createdAt": "2026-08-23T09:00:00.000Z"
  }
}
```

**Error 429 (VIP limit exceeded):**
```json
{
  "code": 429,
  "message": "Daily message limit reached. Upgrade to VIP for unlimited access.",
  "data": { "messagesUsed": 15, "limit": 15 }
}
```

---

### POST /api/v1/conversations/:conversationId/ask

Dedicated endpoint for asking the AI chatbot.

**Auth Required:** Yes + VIP Check

**Request Body:**
```json
{
  "rawText": "What grammar rules should I focus on for TOEIC Part 5?"
}
```

---

## 8. Payment API

**Service:** payment-service | **Base:** `/api/v1/payments`

---

### GET /api/v1/payments/subscriptions

Get all available VIP subscription plans.

**Auth Required:** No

**Response 200:**
```json
{
  "code": 200,
  "message": "Subscriptions retrieved",
  "data": [
    {
      "id": 1,
      "name": "VIP 1 Month",
      "price": 50000,
      "duration": 30,
      "description": "Unlimited AI chatbot access for 1 month"
    },
    {
      "id": 2,
      "name": "VIP 3 Months",
      "price": 120000,
      "duration": 90,
      "description": "Unlimited AI chatbot access for 3 months"
    }
  ]
}
```

---

### GET /api/v1/payments/vip-status

Check the current VIP status of the authenticated user.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "VIP status retrieved",
  "data": {
    "isVip": true,
    "vipExpireAt": "2026-09-23T00:00:00.000Z",
    "daysRemaining": 31
  }
}
```

---

### POST /api/v1/payments/create

Initialize a ZaloPay payment transaction.

**Auth Required:** Yes

**Request Body:**
```json
{
  "subscriptionId": 1,
  "paymentGateway": "zalopay",
  "returnUrl": "https://your-app.com/payment-result"
}
```

**Response 200:**
```json
{
  "code": 200,
  "message": "Payment initialized",
  "data": {
    "orderUrl": "https://sb-openapi.zalopay.vn/v2/...",
    "appTransId": "240823_user1_sub1",
    "amount": 50000,
    "subscriptionId": 1
  }
}
```

---

### POST /api/v1/payments/zalopay-callback

Webhook endpoint for receiving ZaloPay payment results.

**Auth Required:** No (validated by HMAC-SHA256 signature)

**Request Body (from ZaloPay):**
```json
{
  "data": "{\"app_trans_id\":\"240823_user1_sub1\",\"amount\":50000}",
  "mac": "hmac_sha256_signature"
}
```

**Response 200:**
```json
{
  "return_code": 1,
  "return_message": "Success"
}
```

**Response 200 (Signature Invalid):**
```json
{
  "return_code": -1,
  "return_message": "MAC validation failed"
}
```

---

## 9. ML Recommendation API

**Service:** quiz-service (proxies to ml-service) | **Base:** `/api/ml`

---

### GET /api/ml/recommend/:userId

Get TOEIC score prediction and weak skill recommendations for a user.

**Auth Required:** Yes

**Path Parameters:**
- `userId` (integer): Target user ID

**Response 200:**
```json
{
  "code": 200,
  "message": "Recommendations generated",
  "data": {
    "predictedScore": 720,
    "listeningScore": 360,
    "readingScore": 360,
    "weakSkills": ["Conversations (Part 3)", "Text Completion (Part 6)"],
    "recommendedQuestionIds": [101, 205, 318, 422]
  }
}
```

---

### GET /api/ml/recommend/details/:userId

Get ML recommendations with full question details.

**Auth Required:** Yes

**Response 200:**
```json
{
  "code": 200,
  "message": "Detailed recommendations retrieved",
  "data": {
    "predictedScore": 720,
    "weakSkills": ["Part 3", "Part 6"],
    "recommendedQuestions": [
      {
        "id": 101,
        "content": "What are the speakers mainly discussing?",
        "partId": 3,
        "options": { "A": "...", "B": "...", "C": "...", "D": "..." }
      }
    ]
  }
}
```

---

### POST /api/ml/retrain

Manually trigger ML model retraining (Admin only).

**Auth Required:** Yes (Admin)

**Response 200:**
```json
{
  "code": 200,
  "message": "Model retrain triggered",
  "data": null
}
```

---

## 10. Admin - User Management API

**Service:** auth-service | **Base:** `/api/admin-users`
**Auth Required:** Yes (Admin role)

---

### GET /api/admin-users

Get all users in the system.

**Response 200:**
```json
{
  "code": 200,
  "message": "Users retrieved",
  "data": [
    {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "role_id": 2,
      "status": true,
      "isVip": false,
      "createdAt": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### PATCH /api/admin-users/:userId

Update user information (role, status, etc.).

**Request Body:**
```json
{
  "role_id": 1,
  "status": false,
  "username": "johndoe_new"
}
```

**Fields:**
| Field | Type | Description |
|---|---|---|
| `role_id` | integer | `1` = Admin, `2` = User |
| `status` | boolean | `true` = active, `false` = locked |
| `username` | string | New username |
| `email` | string | New email |

---

### DELETE /api/admin-users/:userId

Delete a user account.

---

## 11. Admin - Test Management API

**Service:** quiz-service | **Base:** `/api/admin-tests`
**Auth Required:** Yes (Admin role)

---

### GET /api/admin-tests

Get all tests with course information.

---

### POST /api/admin-tests

Create a new TOEIC test with questions.

**Request Body (Flat format):**
```json
{
  "title": "TOEIC Practice Test #10",
  "courseId": 1,
  "duration": "120 minutes",
  "questions": [
    {
      "content": "Look at the photograph marked number 1.",
      "partId": 1,
      "correctAnswer": "A",
      "options": {
        "A": "The woman is reading a book.",
        "B": "The man is working at a desk.",
        "C": "They are having lunch.",
        "D": "The child is playing."
      },
      "imagePath": "D:/images/p1_q1.jpg",
      "explanation": "The image shows a woman with a book."
    }
  ]
}
```

**Request Body (Mixed format — separate Listening and Reading):**
```json
{
  "title": "TOEIC Full Test #5",
  "courseId": 1,
  "duration": "120 minutes",
  "listeningQuestions": [ ... ],
  "readingQuestions": [ ... ]
}
```

**Auto Features:**
- If `imagePath` or `audioPath` (local paths) are provided, the server auto-uploads to Cloudinary
- Mixed format auto-assigns `skillId` (1 = Listening, 2 = Reading)
- AI embeddings are auto-generated for all questions

**Response 201:**
```json
{
  "code": 201,
  "message": "Test created successfully",
  "data": {
    "testId": 10,
    "title": "TOEIC Practice Test #10",
    "questionCount": 100
  }
}
```

---

### DELETE /api/admin-tests/:testId

Delete a test and all related data (UserTest records, question links).

**Response 200:**
```json
{
  "code": 200,
  "message": "Test deleted successfully",
  "data": null
}
```

---

### GET /api/admin-tests/parts

Get all TOEIC parts.

---

### POST /api/admin-tests/parts

Create a new part.

---

### PATCH /api/admin-tests/parts/:id

Update a part name.

---

### DELETE /api/admin-tests/parts/:id

Delete a part.

---

### GET /api/admin-tests/question-types

Get all question types.

---

### GET /api/admin-tests/skills

Get all skills.

---

### POST /api/admin-tests/skills

Create a new skill.

---

## 12. Admin - Metadata API

**Service:** quiz-service | **Base:** `/api/admin-metadata`
**Auth Required:** Yes (Admin role)

### Parts

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin-metadata/parts` | List all parts |
| `POST` | `/api/admin-metadata/parts` | Create part (`{ "name": "Part 1" }`) |
| `PUT` | `/api/admin-metadata/parts/:id` | Update part |
| `DELETE` | `/api/admin-metadata/parts/:id` | Delete part |

### Question Types

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin-metadata/types` | List all question types |
| `POST` | `/api/admin-metadata/types` | Create type (`{ "name": "Photographs", "description": "..." }`) |
| `PUT` | `/api/admin-metadata/types/:id` | Update type |
| `DELETE` | `/api/admin-metadata/types/:id` | Delete type |

### Skills

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin-metadata/skills` | List all skills |
| `POST` | `/api/admin-metadata/skills` | Create skill (`{ "name": "Listening", "parentId": null }`) |
| `PUT` | `/api/admin-metadata/skills/:id` | Update skill |
| `DELETE` | `/api/admin-metadata/skills/:id` | Delete skill |

---

## 13. Internal API

**Service:** auth-service | **Base:** `/api/v1/internal`
**Note:** These endpoints are used for **inter-service communication only** and are not exposed to external clients.

---

### GET /api/v1/internal/users/:id

Retrieve user data for internal service validation (used by payment-service, chatbot-service).

**Response 200:**
```json
{
  "code": 200,
  "message": "User retrieved",
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role_id": 2,
    "isVip": true,
    "vipExpireAt": "2026-09-23T00:00:00.000Z"
  }
}
```

---

### PATCH /api/v1/internal/users/:id

Update user VIP status (called by payment-service after successful payment).

**Request Body:**
```json
{
  "isVip": true,
  "vipExpireAt": "2026-09-23T00:00:00.000Z"
}
```

---

## Appendix — Common Schemas

### User Object
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "avatar": "https://res.cloudinary.com/...",
  "role_id": 2,
  "status": true,
  "isVip": false,
  "vipExpireAt": null,
  "createdAt": "2025-01-01T00:00:00.000Z"
}
```

### Question Object
```json
{
  "id": 101,
  "content": "What is the woman doing?",
  "imageUrl": "https://res.cloudinary.com/...",
  "audioUrl": "https://res.cloudinary.com/...",
  "partId": 1,
  "skillId": 1,
  "correctAnswer": "B",
  "options": {
    "A": "She is cooking.",
    "B": "She is reading.",
    "C": "She is sleeping.",
    "D": "She is working."
  },
  "explanation": "The image clearly shows a woman with a book."
}
```

### TestAttempt Object
```json
{
  "id": 55,
  "testId": 1,
  "userId": 1,
  "status": "completed",
  "score": 785,
  "listeningScore": 395,
  "readingScore": 390,
  "timeSpent": 3600,
  "startedAt": "2026-08-23T09:00:00.000Z",
  "submittedAt": "2026-08-23T10:00:00.000Z"
}
```

### Subscription Object
```json
{
  "id": 1,
  "name": "VIP 1 Month",
  "price": 50000,
  "duration": 30,
  "description": "Unlimited AI chatbot access for 1 month",
  "isActive": true
}
```

---

**Document Version:** 2.0.0 | **Last Updated:** August 2026
