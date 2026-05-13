// chatbot-toeic-backend\src\controllers\AdminTest_xontroller.js

import Part from '../models/Part.js';
import {getAllTestsWithCourses,
  getAllQuestionTypes,
  getAllParts,
  createPart,
  createQuestionType,
  deletePart,
  deleteQuestionType,
  createNewTest,
  updatePartName,
  updateQuestionType,
  deleteTestById,
  createSkill,
  getAllSkills,
  getSkillById,
  updateSkill,
  deleteSkill,
 } from '../services/AdminTest_service.js';

 import embeddingService from '../services/embeddingService.js';

const getTestList = async (req, res) => {
  try {
    const data = await getAllTestsWithCourses();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching test list:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getQuestionTypes = async (req, res) => {
  try {
    const data = await getAllQuestionTypes();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching question types:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

const getParts = async (req, res) => {
  try {
    const data = await getAllParts();
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching parts:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};



// Create Part
const createPartController = async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ message: "Part name is required" });

    const newPart = await createPart(name);
    res.status(201).json(newPart);
  } catch (err) {
    console.error('Error creating part:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Delete Part
const deletePartController = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await deletePart(id);

    if (!deleted) return res.status(404).json({ message: "Part not found" });

    res.status(200).json({ message: "Part deleted successfully" });
  } catch (err) {
    console.error('Error deleting part:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Create QuestionType
const createQuestionTypeController = async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name) return res.status(400).json({ message: "Question type name is required" });

    const newType = await createQuestionType(name, description);
    res.status(201).json(newType);
  } catch (err) {
    console.error('Error creating question type:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Delete QuestionType
const deleteQuestionTypeController = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await deleteQuestionType(id);

    if (!deleted) return res.status(404).json({ message: "Question type not found" });

    res.status(200).json({ message: "Question type deleted successfully" });
  } catch (err) {
    console.error('Error deleting question type:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
};


// Create Test new
const createNewTestController = async (req, res) => {
  try {
    let testData = req.body;
    const { title, courseId } = testData;

    // 1. Kiểm tra định dạng dữ liệu (Hỗ trợ cả flat questions và mixed)
    const hasFlatQuestions = Array.isArray(testData.questions) && testData.questions.length > 0;
    const hasMixedQuestions = Array.isArray(testData.listeningQuestions) || Array.isArray(testData.readingQuestions);

    if (!hasFlatQuestions && !hasMixedQuestions) {
      return res.status(400).json({
        message: 'Questions array (flat or mixed) is required and must contain at least one question',
      });
    }

    // 2. Kiểm tra xem có cần upload media từ local path không
    // (Dấu hiệu: có trường imagePath hoặc audioPath trong bất kỳ câu hỏi nào)
    const needsUpload = (questions) => {
      if (!Array.isArray(questions)) return false;
      return questions.some(q => q.imagePath || q.audioPath || (q.media && q.media.some(m => m.localPath)));
    };

    const shouldProcessUpload = needsUpload(testData.questions) || 
                               needsUpload(testData.listeningQuestions) || 
                               needsUpload(testData.readingQuestions) ||
                               testData.audioPath;

    if (shouldProcessUpload) {
      console.log("📤 Local paths detected. Starting batch upload to Cloudinary...");
      // Import động service để tránh vòng lặp phụ thuộc nếu có
      const { batchUploadFromPaths } = await import('../services/batchUploadService.js');
      testData = await batchUploadFromPaths(testData);
      console.log("✅ Batch upload completed. Proceeding to database save.");
    }

    // 3. Chuẩn hóa dữ liệu media (Chuyển imageUrl/audioUrl thành mảng media chuẩn nếu cần)
    const normalizeMedia = (questions) => {
      if (!Array.isArray(questions)) return;
      questions.forEach(q => {
        if (!q.media) q.media = [];
        if (q.imageUrl) {
          q.media.push({ type: 'image', url: q.imageUrl });
          delete q.imageUrl;
        }
        if (q.audioUrl) {
          q.media.push({ type: 'audio', url: q.audioUrl });
          delete q.audioUrl;
        }
      });
    };

    normalizeMedia(testData.questions);
    normalizeMedia(testData.listeningQuestions);
    normalizeMedia(testData.readingQuestions);

    // 4. Gọi service để lưu bài thi
    const { createNewTest } = await import('../services/AdminTest_service.js');
    const result = await createNewTest(testData);

    res.status(201).json({
      message: 'Test created and saved successfully',
      data: result,
    });
  } catch (error) {
    console.error('❌ Error in createNewTestController (Unified):', error);
    res.status(500).json({ 
      message: 'Internal server error',
      error: error.message
    });
  }
};


const deleteTestByIdController = async (req, res) => {
  const {testId} = req.params;
  console.log(`🗑️ [deleteTestByIdController] Deleting test with ID: `, testId);

  try {
    const result = await deleteTestById(testId);

    console.log(`✅ [deleteTestByIdController] Deleted test ID ${testId}`);
    res.status(200).json(result);
  } catch (error) {
    console.error(`❌ [deleteTestByIdController] Failed to delete test ID ${testId}:`, error.message);
    res.status(404).json({ message: error.message });
  }
};

const updatePartNameController = async (req, res) => {
  try {
    const { partId, name } = req.body;

    if (!name || typeof name !== "string") {
      return res.status(400).json({ message: "Tên khóa học không hợp lệ." });
    }

    const updatedPart = await updatePartName(partId, name.trim());

    res.status(200).json({
      message: "Cập nhật tên khóa học thành công.",
      part: {
        id: updatedPart.id,
        name: updatedPart.name,
      },
    });
  } catch (error) {
    console.error("❌ Error in updateCourseNameController:", error);
    res.status(500).json({ message: "Cập nhật khóa học thất bại." });
  }
};
const updateQuestionTypeController = async (req, res) => {
  try {
    const { typeId, name, description } = req.body;

    if (!name || typeof name !== "string") {
      return res.status(400).json({ message: "Tên loại câu hỏi không hợp lệ." });
    }

    const updatedType = await updateQuestionType(typeId, name.trim(), description ?? null);

    res.status(200).json({
      message: "Cập nhật question type thành công.",
      questionType: {
        id: updatedType.id,
        name: updatedType.name,
        description: updatedType.description,
      },
    });
  } catch (error) {
    console.error("❌ Error in updateQuestionTypeController:", error);
    res.status(500).json({ message: "Cập nhật question type thất bại." });
  }
};

// ✅ Generate missing embeddings (safety net)
const generateMissingEmbeddingsController = async (req, res) => {
  try {
    await embeddingService.generateMissingEmbeddings();
    res.status(200).json({
      message: "Generated embeddings for all missing questions"
    });
  } catch (error) {
    console.error("❌ Error in generateMissingEmbeddingsController:", error);
    res.status(500).json({
      message: "Failed to generate missing embeddings"
    });
  }
};

// Lấy tất cả skill
const getSkillsController = async (req, res) => {
  try {
    const skills = await getAllSkills();
    res.status(200).json(skills);
  } catch (err) {
    console.error("❌ Error fetching skills:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Lấy skill theo ID
const getSkillByIdController = async (req, res) => {
  try {
    const { id } = req.params;
    const skill = await getSkillById(id);

    if (!skill) {
      return res.status(404).json({ message: "Skill not found" });
    }

    res.status(200).json(skill);
  } catch (err) {
    console.error("❌ Error fetching skill by id:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Tạo skill mới
const createSkillController = async (req, res) => {
  try {
    const { name, description, parentId } = req.body;
    if (!name) {
      return res.status(400).json({ message: "Skill name is required" });
    }

    const newSkill = await createSkill({ name, description, parentId });
    res.status(201).json(newSkill);
  } catch (err) {
    console.error("❌ Error creating skill:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Cập nhật skill
const updateSkillController = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const updatedSkill = await updateSkill(id, updates);
    res.status(200).json({
      message: "Skill updated successfully",
      skill: updatedSkill,
    });
  } catch (err) {
    console.error("❌ Error updating skill:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Xóa skill
const deleteSkillController = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await deleteSkill(id);
    res.status(200).json(result);
  } catch (err) {
    console.error("❌ Error deleting skill:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};



export {
  getTestList,
  getQuestionTypes,
  getParts,
  createPartController,
  deletePartController,
  createQuestionTypeController,
  deleteQuestionTypeController,
  createNewTestController,
  updatePartNameController,
  updateQuestionTypeController,
  deleteTestByIdController,
  generateMissingEmbeddingsController,
  getSkillsController,
  getSkillByIdController,
  createSkillController,
  updateSkillController,
  deleteSkillController,
};