import express from 'express';
import { 
    getAllParts, createPart, updatePart, deletePart,
    getAllTypes, createType, updateType, deleteType,
    getAllSkills, createSkill, updateSkill, deleteSkill
} from '../controllers/AdminMetadata_controller.js';
import { authMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();

/**
 * @swagger
 * tags:
 *   - name: Admin (Metadata)
 *     description: Quản lý Part, Question Type, và Skill (Dành cho Admin)
 */

// === Parts ===
/**
 * @swagger
 * /api/adminMetadata/parts:
 *   get:
 *     summary: Lấy danh sách Part
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về danh sách Part
 */
router.get('/parts', authMiddleware, getAllParts);

/**
 * @swagger
 * /api/adminMetadata/parts:
 *   post:
 *     summary: Thêm mới Part
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tạo thành công
 */
router.post('/parts', authMiddleware, createPart);

/**
 * @swagger
 * /api/adminMetadata/parts/{id}:
 *   put:
 *     summary: Cập nhật Part
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/parts/:id', authMiddleware, updatePart);

/**
 * @swagger
 * /api/adminMetadata/parts/{id}:
 *   delete:
 *     summary: Xóa Part
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Xóa thành công
 */
router.delete('/parts/:id', authMiddleware, deletePart);

// === Types ===
/**
 * @swagger
 * /api/adminMetadata/types:
 *   get:
 *     summary: Lấy danh sách Question Type
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về danh sách Type
 */
router.get('/types', authMiddleware, getAllTypes);

/**
 * @swagger
 * /api/adminMetadata/types:
 *   post:
 *     summary: Thêm mới Question Type
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tạo thành công
 */
router.post('/types', authMiddleware, createType);

/**
 * @swagger
 * /api/adminMetadata/types/{id}:
 *   put:
 *     summary: Cập nhật Question Type
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/types/:id', authMiddleware, updateType);

/**
 * @swagger
 * /api/adminMetadata/types/{id}:
 *   delete:
 *     summary: Xóa Question Type
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Xóa thành công
 */
router.delete('/types/:id', authMiddleware, deleteType);

// === Skills ===
/**
 * @swagger
 * /api/adminMetadata/skills:
 *   get:
 *     summary: Lấy danh sách Skill
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về danh sách Skill
 */
router.get('/skills', authMiddleware, getAllSkills);

/**
 * @swagger
 * /api/adminMetadata/skills:
 *   post:
 *     summary: Thêm mới Skill
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               parentId:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Tạo thành công
 */
router.post('/skills', authMiddleware, createSkill);

/**
 * @swagger
 * /api/adminMetadata/skills/{id}:
 *   put:
 *     summary: Cập nhật Skill
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               parentId:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 */
router.put('/skills/:id', authMiddleware, updateSkill);

/**
 * @swagger
 * /api/adminMetadata/skills/{id}:
 *   delete:
 *     summary: Xóa Skill
 *     tags: [Admin (Metadata)]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Xóa thành công
 */
router.delete('/skills/:id', authMiddleware, deleteSkill);

export default router;
