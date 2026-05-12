import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Chatbot TOEIC API Documentation',
      version: '1.0.0',
      description: `
API documentation cho ứng dụng Chatbot TOEIC (Web + Mobile).
Sử dụng chuẩn RESTful v1.

**Lưu ý cho Mobile Team:**
- Sử dụng package \`swagger_dart_code_generator\` hoặc \`openapi_generator\` để tự động sinh code.
- Mọi Private API đều yêu cầu Header: \`Authorization: Bearer <token>\`.
      `,
      contact: {
        name: 'Development Team',
      },
    },
    servers: [
      {
        url: process.env.API_URL || 'http://localhost:8080',
        description: 'Production Server',
      },
      {
        url: 'http://localhost:8080',
        description: 'Development Server',
      },
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT Access Token',
        },
      },
      responses: {
        SuccessResponse: {
          description: 'Success Response',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  status: { type: 'string', example: 'success' },
                  message: { type: 'string', example: 'Operation successful' },
                  data: { type: 'object', description: 'Dữ liệu trả về' },
                  meta: {
                    type: 'object',
                    properties: {
                      timestamp: { type: 'string', format: 'date-time' },
                    },
                  },
                },
              },
            },
          },
        },
        UnauthorizedError: {
          description: 'Lỗi xác thực (401)',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              },
              example: {
                status: 'error',
                code: 401,
                message: 'Unauthorized - Token is missing or invalid',
                errorCode: 'UNAUTHORIZED'
              }
            },
          },
        },
        BadRequestError: {
          description: 'Lỗi dữ liệu đầu vào (400)',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              },
              example: {
                status: 'error',
                code: 400,
                message: 'Bad Request',
                details: ['"email" is required']
              }
            },
          },
        },
        NotFoundError: {
          description: 'Không tìm thấy tài nguyên (404)',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              },
              example: {
                status: 'error',
                code: 404,
                message: 'Resource not found'
              }
            },
          },
        },
      },
      schemas: {
        ErrorResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'error' },
            code: { type: 'integer', example: 400 },
            message: { type: 'string', example: 'Error message' },
            errorCode: { type: 'string', example: 'ERROR_CODE' },
            details: { 
              type: 'array', 
              items: { type: 'string' },
              example: []
            },
            timestamp: { type: 'string', format: 'date-time' },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            username: { type: 'string', example: 'john_doe' },
            email: { type: 'string', format: 'email', example: 'john@example.com' },
            role_id: { type: 'integer', example: 1 },
            avatar_url: { type: 'string', nullable: true },
          },
          required: ['id', 'username', 'email'],
        },
        Course: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            name: { type: 'string', example: 'TOEIC 750+' },
            description: { type: 'string', nullable: true },
          },
          required: ['id', 'name'],
        },
        Test: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            title: { type: 'string', example: 'TOEIC Reading Test 1' },
            duration: { type: 'string', example: '45:00' },
            participants: { type: 'integer', example: 120 },
            commentsCount: { type: 'integer', example: 5 },
            questionsCount: { type: 'integer', example: 100 },
            tags: { 
              type: 'array', 
              items: { type: 'string' },
              example: ['Grammar', 'Reading']
            },
          },
          required: ['id', 'title'],
        },
        Question: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            question: { type: 'string', example: 'Select the correct option...' },
            optionA: { type: 'string' },
            optionB: { type: 'string' },
            optionC: { type: 'string' },
            optionD: { type: 'string' },
            correctAnswer: { type: 'string', enum: ['A', 'B', 'C', 'D'] },
            explanation: { type: 'string', nullable: true },
            typeId: { type: 'integer' },
            partId: { type: 'integer', example: 5 },
            image_url: { type: 'string', nullable: true },
            audio_url: { type: 'string', nullable: true },
          },
          required: ['id', 'question', 'correctAnswer'],
        },
        Conversation: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            userId: { type: 'integer', example: 1 },
            title: { type: 'string', example: 'Học Part 5 TOEIC' },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
          required: ['id', 'userId', 'title'],
        },
        Message: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            conversationId: { type: 'integer', example: 1 },
            role: { type: 'string', enum: ['user', 'model'] },
            content: { type: 'string', example: 'Giải thích giúp mình câu này...' },
            createdAt: { type: 'string', format: 'date-time' },
          },
          required: ['id', 'conversationId', 'role', 'content'],
        },
        AdminQuestionInput: {
          type: 'object',
          properties: {
            question: { type: 'string', example: 'What is the synonym of "Happy"?' },
            optionA: { type: 'string', example: 'Sad' },
            optionB: { type: 'string', example: 'Joyful' },
            optionC: { type: 'string', example: 'Angry' },
            optionD: { type: 'string', example: 'Fast' },
            correctAnswer: { type: 'string', enum: ['A', 'B', 'C', 'D'], example: 'B' },
            explanation: { type: 'string', example: 'Joyful means the same as Happy.' },
            typeId: { type: 'integer', example: 1 },
            partId: { type: 'integer', example: 5 },
            skillId: { type: 'integer', example: 2, description: "1: Listening, 2: Reading" },
            imagePath: { type: 'string', description: "Đường dẫn cục bộ trên server (để auto-upload)" },
            audioPath: { type: 'string', description: "Đường dẫn cục bộ trên server (để auto-upload)" },
            media: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  type: { type: 'string', enum: ['image', 'audio', 'video'] },
                  url: { type: 'string', example: 'http://res.cloudinary.com/...' },
                  description: { type: 'string' }
                }
              }
            }
          }
        }
      },
    },
    // Global security setting (optional, can be overridden per route)
    security: [
      {
        BearerAuth: [],
      },
    ],
  },
  apis: [
    './src/routes/*.js',
    './src/controllers/*.js',
  ],
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
