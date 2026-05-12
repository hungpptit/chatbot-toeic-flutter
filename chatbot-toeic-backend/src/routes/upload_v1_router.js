import express from 'express';
import {
    uploadImageV1,
    uploadAudioV1,
    deleteUploadV1,
    batchUploadV1,
    validatePathsV1
} from '../controllers/upload_v1_controller.js';
import { uploadImage, uploadAudio } from '../config/multer.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * /api/v1/uploads/images:
 *   post:
 *     summary: Upload ảnh lên Cloudinary
 *     tags: [Upload (v1)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/images', authMiddleware, uploadImage.single('file'), uploadImageV1);

/**
 * @swagger
 * /api/v1/uploads/audio:
 *   post:
 *     summary: Upload audio lên Cloudinary
 *     tags: [Upload (v1)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/audio', authMiddleware, uploadAudio.single('file'), uploadAudioV1);

/**
 * @swagger
 * /api/v1/uploads/{publicId}:
 *   delete:
 *     summary: Xóa file từ Cloudinary
 *     tags: [Upload (v1)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: publicId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: resourceType
 *         schema:
 *           type: string
 *           enum: [image, video]
 *         description: image cho ảnh, video cho audio
 *     responses:
 *       200:
 *         description: Thành công
 */
router.delete('/:publicId', authMiddleware, deleteUploadV1);

/**
 * @swagger
 * /api/v1/uploads/batch:
 *   post:
 *     summary: Batch upload từ local paths (Admin use)
 *     tags: [Upload (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/batch', authMiddleware, batchUploadV1);

/**
 * @swagger
 * /api/v1/uploads/validate-paths:
 *   post:
 *     summary: Kiểm tra tính hợp lệ của local paths
 *     tags: [Upload (v1)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Thành công
 */
router.post('/validate-paths', authMiddleware, validatePathsV1);

export default router;
