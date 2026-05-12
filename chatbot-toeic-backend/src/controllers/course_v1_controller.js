import { 
    getAllCourseNames, 
    getAllCoursesWithTests,
    updateCourseName,
    deleteCourseById,
    insertCourse
} from "../services/test_course_service.js";
import { sendSuccess, sendError } from "../utils/response.js";

/**
 * GET /api/v1/courses
 * Lấy danh sách tất cả các khóa học
 */
export const getCourses = async (req, res) => {
    try {
        const includeTests = req.query.include === 'tests';
        let courses;
        
        if (includeTests) {
            courses = await getAllCoursesWithTests();
        } else {
            courses = await getAllCourseNames();
        }
        
        return sendSuccess(res, courses, "Fetched courses successfully");
    } catch (error) {
        console.error("[COURSE V1] getCourses error:", error);
        return sendError(res, 500, "Error fetching courses", [error.message]);
    }
};

/**
 * POST /api/v1/courses
 * Tạo khóa học mới
 */
export const createCourse = async (req, res) => {
    try {
        const { name } = req.body;
        if (!name) {
            return sendError(res, 400, "Course name is required");
        }
        
        const newCourse = await insertCourse(name);
        return sendSuccess(res, newCourse, "Course created successfully", 201);
    } catch (error) {
        console.error("[COURSE V1] createCourse error:", error);
        return sendError(res, 500, "Error creating course", [error.message]);
    }
};

/**
 * PATCH /api/v1/courses/:id
 * Cập nhật tên khóa học
 */
export const updateCourse = async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;
        
        if (!name) {
            return sendError(res, 400, "New course name is required");
        }
        
        const updatedCourse = await updateCourseName(id, name);
        return sendSuccess(res, updatedCourse, "Course updated successfully");
    } catch (error) {
        console.error("[COURSE V1] updateCourse error:", error);
        return sendError(res, 500, "Error updating course", [error.message]);
    }
};

/**
 * DELETE /api/v1/courses/:id
 * Xóa khóa học
 */
export const deleteCourse = async (req, res) => {
    try {
        const { id } = req.params;
        await deleteCourseById(id);
        return sendSuccess(res, null, `Course with ID ${id} deleted successfully`);
    } catch (error) {
        console.error("[COURSE V1] deleteCourse error:", error);
        return sendError(res, 500, "Error deleting course", [error.message]);
    }
};
