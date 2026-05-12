/**
 * Utility để chuẩn hóa Response Format cho toàn bộ API
 * Success: { status: "success", data: {...}, meta: {...} }
 * Error: { status: "error", code: 400, message: "...", details: [...] }
 */

/**
 * Trả về response thành công
 * @param {object} res - Express response object
 * @param {*} data - Dữ liệu trả về
 * @param {string} message - Message (optional)
 * @param {number} statusCode - HTTP status code (default: 200)
 * @param {object} meta - Metadata (optional)
 */
export const sendSuccess = (
  res,
  data = null,
  message = 'Success',
  statusCode = 200,
  meta = {}
) => {
  return res.status(statusCode).json({
    status: 'success',
    message,
    data,
    meta: {
      timestamp: new Date().toISOString(),
      ...meta,
    },
  });
};

/**
 * Trả về response lỗi
 * @param {object} res - Express response object
 * @param {number} code - HTTP status code
 * @param {string} message - Error message
 * @param {array} details - Chi tiết lỗi (optional)
 * @param {string} errorCode - Internal error code (optional)
 */
export const sendError = (
  res,
  code = 500,
  message = 'Internal Server Error',
  details = [],
  errorCode = null
) => {
  return res.status(code).json({
    status: 'error',
    code,
    message,
    errorCode,
    details,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Middleware để wrap error handling
 * Sử dụng try-catch trong controller, gọi next(error) để trigger middleware này
 */
export const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  const details = err.details || [];
  const errorCode = err.errorCode || null;

  console.error(`[ERROR] ${statusCode} - ${message}`, err);

  return sendError(res, statusCode, message, details, errorCode);
};

/**
 * Tạo custom error object
 * @param {string} message
 * @param {number} statusCode
 * @param {array} details
 * @param {string} errorCode
 */
export class APIError extends Error {
  constructor(message, statusCode = 500, details = [], errorCode = null) {
    super(message);
    this.statusCode = statusCode;
    this.details = details;
    this.errorCode = errorCode;
  }
}

export default { sendSuccess, sendError, errorHandler, APIError };
