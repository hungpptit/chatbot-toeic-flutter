import express from 'express';
import { getAllTestsWithCoursesController, getAllCourseNamesController, getCoursesNameWithTests,updateCourseNameController,
    deleteCourseByIdController,
    insertCourseController
 } from '../controllers/test_course_controller.js';
import { authMiddleware, adminMiddleware } from '../Middleware/authMiddleware.js';

const router = express.Router();
router.get('/all', getAllTestsWithCoursesController);
router.get('/courses', authMiddleware,getAllCourseNamesController);
router.get('/with-tests', authMiddleware, getCoursesNameWithTests);
router.put('/update/:id', authMiddleware, adminMiddleware, updateCourseNameController);
router.delete('/delete/:id', authMiddleware, adminMiddleware, deleteCourseByIdController);
router.post('/insert', authMiddleware, adminMiddleware, insertCourseController);

export default router;