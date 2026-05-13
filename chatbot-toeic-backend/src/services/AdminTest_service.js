// =============================================================
// tạo câu hỏi ở đây nha và tạo test luôn
// =============================================================
import db from "../models/index.js";
import embeddingService from "./embeddingService.js";


const Test = db.Test;
const Course = db.Course;
const Question = db.Question;
const Part = db.Part;
const QuestionType = db.QuestionType;
const TestQuestion = db.TestQuestion;
const Test_Courses = db.TestCourse;
const Skill = db.Skill;
const QuestionSkill = db.QuestionSkill;
const MediaFiles = db.MediaFiles;
const QuestionMediaMap = db.QuestionMediaMap;

const getAllTestsWithCourses = async () => {
  try {
    const testList = await Test.findAll({
    order: [["id", "ASC"]],
    attributes: ["id", "title", "duration", "participants"],
    include: [
      {
        model: Course,
        attributes: ["name"],
        through: { attributes: [] },
      },
      {
        model: Question,
        as: "questions",
        attributes: ["id"], // chỉ cần id
        through: { attributes: [] },
      },
    ],
  });

  const formattedTests = testList.map((test) => ({
    id: test.id,
    title: test.title,
    duration: test.duration,
    participants: test.participants,
    questions: test.questions.length, // đếm từ bảng trung gian TestQuestions
    courses: test.Courses.map((course) => course.name),
  }));


    return formattedTests;
  } catch (error) {
    console.error("❌ Error fetching tests with Courses:", error);
    throw error;
  }
};

const getAllQuestionTypes = async () => {
  try {
    const questionTypes = await QuestionType.findAll({
      attributes: ['id', 'name', 'description'],
      order: [['id', 'ASC']],
    });
    return questionTypes;
  } catch (error) {
    console.error("❌ Error fetching Question Types:", error);
    throw error;
  }
};


const getAllParts = async () => {
  try {
    const parts = await Part.findAll({
      attributes: ['id', 'name'],
      order: [['id', 'ASC']],
    });
    return parts;
  } catch (error) {
    console.error("❌ Error fetching Parts:", error);
    throw error;
  }
};

// Create Part
const createPart = async (name) => {
  try {
    const newPart = await Part.create({ name });
    return newPart;
  } catch (error) {
    console.error("❌ Error creating Part:", error);
    throw error;
  }
};

// Create QuestionType
const createQuestionType = async (name, description) => {
  try {
    const newType = await QuestionType.create({ name, description });
    return newType;
  } catch (error) {
    console.error("❌ Error creating QuestionType:", error);
    throw error;
  }
};

// Delete Part by ID
const deletePart = async (id) => {
  try {
    const deleted = await Part.destroy({ where: { id } });
    return deleted > 0; // true if deleted
  } catch (error) {
    console.error("❌ Error deleting Part:", error);
    throw error;
  }
};

// Delete QuestionType by ID
const deleteQuestionType = async (id) => {
  try {
    const deleted = await QuestionType.destroy({ where: { id } });
    return deleted > 0;
  } catch (error) {
    console.error("❌ Error deleting QuestionType:", error);
    throw error;
  }
};

// update part name
const updatePartName = async (PartId, newName) => { 
  try {
    const part = await Part.findByPk(PartId);
    if (!part) {
      throw new Error(`Part with ID ${PartId} not found`);
    }
    part.name = newName;
    await part.save();
    return part;
  } catch (error) {
    console.error("❌ Error updating course name:", error);
    throw error;
  }
};

// update course questionType
const updateQuestionType = async (typeId, newName, newDescription = null) => {
  try {
    const questionType = await QuestionType.findByPk(typeId);
    if (!questionType) {      
      throw new Error(`QuestionType with ID ${typeId} not found`);
    }
    questionType.name = newName;
    questionType.description = newDescription;
    await questionType.save();
    return questionType;
  } catch (error) {
    console.error("❌ Error updating question type:", error);
    throw error;  
  }
};
// =============================================================
// tạo câu hỏi ở đây nha và tạo test luôn
// =============================================================

const createNewTest = async (testData) => {
  try {
    const { title, courseId, questions: flatQuestions, listeningQuestions, readingQuestions } = testData;

    // 1. Chuẩn bị danh sách câu hỏi tổng hợp
    let finalQuestions = [];

    if (Array.isArray(flatQuestions) && flatQuestions.length > 0) {
      finalQuestions = [...flatQuestions];
    } else {
      // ✅ Cập nhật ID chuẩn theo DB của bạn: Listening = 6, Reading = 4
      if (Array.isArray(listeningQuestions)) {
        finalQuestions = [
          ...finalQuestions,
          ...listeningQuestions.map(q => ({ ...q, skillId: q.skillId || 6 }))
        ];
      }
      if (Array.isArray(readingQuestions)) {
        finalQuestions = [
          ...finalQuestions,
          ...readingQuestions.map(q => ({ ...q, skillId: q.skillId || 4 }))
        ];
      }
    }

    if (finalQuestions.length === 0) {
      throw new Error("No questions provided in any supported format.");
    }

    // ✅ LOG: Check data chuẩn bị lưu
    console.log(`📥 Processing test creation: ${title} with ${finalQuestions.length} questions`);

    // Create test
    const test = await db.Test.create({
      title,
      duration: testData.duration || "45 minutes",
      participants: 0,
      questions: finalQuestions.length,
    });

    // Create test-course relationship
    await db.sequelize.models.Test_Courses.create({
      courseId,
      testId: test.id,
    });

    // Create questions
    const questionRecords = await Promise.all(finalQuestions.map(async (q) => {
      // ✅ Chuẩn bị mảng media (Gộp media riêng của câu hỏi + Audio tổng của bài test nếu có)
      let questionMedia = q.media ? [...q.media] : [];
      
      // Nếu bài test có audio tổng (audioUrl) và câu hỏi chưa có audio nào
      if (testData.audioUrl && !questionMedia.some(m => m.type === 'audio')) {
        questionMedia.push({
          type: 'audio',
          url: testData.audioUrl,
          description: 'Global test audio',
          startSecond: q.startSecond ?? null, // Lấy timestamp riêng của câu hỏi nếu có
          endSecond: q.endSecond ?? null
        });
      }

      const question = await Question.create({
        question: q.question || null,
        optionA: q.optionA || null,
        optionB: q.optionB || null,
        optionC: q.optionC || null,
        optionD: q.optionD || null,
        correctAnswer: q.correctAnswer || null,
        explanation: q.explanation || null,
        typeId: q.typeId || 1,
        partId: q.partId || null,
      });
      
      // ✅ Xử lý gán Skill ID (Hỗ trợ cả mảng skillIds hoặc 1 skillId đơn lẻ)
      let skillsToAssign = [];
      if (Array.isArray(q.skillIds)) {
        skillsToAssign = q.skillIds;
      } else if (q.skillId) {
        skillsToAssign = [q.skillId];
      }

      if (skillsToAssign.length > 0) {
        await Promise.all(skillsToAssign.map(async (sId) => {
          await QuestionSkill.create({
            questionId: question.id,
            skillId: sId,
            weight: 1,
          });
        }));
      }

      // Lưu media
      if (questionMedia.length > 0) {
        await Promise.all(questionMedia.map(async (m, idx) => {
          const mediaFile = await MediaFiles.create({
            mediaType: m.type,
            mediaUrl: m.url,
            description: m.description || null,
          });

          await QuestionMediaMap.create({
            questionId: question.id,
            mediaId: mediaFile.id,
            startSecond: m.startSecond ?? null,
            endSecond: m.endSecond ?? null,
            sortOrder: idx + 1,
          });
        }));
      }

      // Generate embedding cho AI
      if (question.question) {
        try {
          await embeddingService.generateEmbeddingForQuestion(question);
        } catch (err) {
          console.error(`⚠️ Failed to generate embedding for questionId ${question.id}:`, err);
        }
      }

      return question;
    }));

    // Tạo liên kết Test-Question
    const testQuestionRecords = questionRecords.map((q, index) => ({
      testId: test.id,
      questionId: q.id,
      sortOrder: index + 1,
    }));
    await TestQuestion.bulkCreate(testQuestionRecords);

    return {
      testId: test.id,
      questionIds: questionRecords.map(q => q.id),
      totalQuestions: finalQuestions.length
    };
  } catch (err) {
    console.error('❌ Error in createNewTest service:', err);
    throw err;
  }
};


const deleteTestById = async (testIdRaw) => {
  try {
    // 1. Tìm test
    const testId = +testIdRaw;
    console.log('[deleteTestById] testId:', testId, typeof testId);
    console.log('[DEBUG] db.Test:', db.Test);
    const test = await db.Test.findByPk(testId);
    if (!test) {
      throw new Error(`Test with ID ${testId} not found`);
    }

    // 2. Xóa liên kết trong bảng trung gian (nếu bạn muốn xóa tường minh)
    await db.Test_Courses.destroy({ where: { testId } });
    await db.UserTest.destroy({ where: { testId } });
    await db.TestQuestion.destroy({ where: { testId } });
    // 3. Xóa test chính
    await test.destroy();

    console.log(`🗑️ Test ID ${testId} has been deleted`);
    return { success: true, message: `Test ID ${testId} deleted` };
  } catch (error) {
    console.error('❌ Error deleting test:', error);
    throw error;
  }
};

// =============================================================
// CRUD cho Skills
// =============================================================

// Tạo skill mới
const createSkill = async (skillData) => {
  try {
    const { name, description, parentId } = skillData;
    const newSkill = await Skill.create({ name, description, parentId });
    return newSkill;
  } catch (error) {
    console.error("❌ Error creating Skill:", error);
    throw error;
  }
};

// Lấy tất cả skill
const getAllSkills = async () => {
  try {
    const skills = await Skill.findAll({
      attributes: ["id", "name", "description", "parentId"],
      include: [
        { model: Skill, as: "children", attributes: ["id", "name"] },
        { model: Skill, as: "parent", attributes: ["id", "name"] },
      ],
      order: [["id", "ASC"]],
    });
    return skills;
  } catch (error) {
    console.error("❌ Error fetching Skill:", error);
    throw error;
  }
};

// Lấy skill theo id
const getSkillById = async (id) => {
  try {
    const skill = await Skill.findByPk(id, {
      attributes: ["id", "name", "description", "parentId"],
      include: [
        { model: Skill, as: "children", attributes: ["id", "name"] },
        { model: Skill, as: "parent", attributes: ["id", "name"] },
      ],
    });
    if (!skill) throw new Error(`Skill with ID ${id} not found`);
    return skill;
  } catch (error) {
    console.error("❌ Error fetching Skill by ID:", error);
    throw error;
  }
};

// Cập nhật skill
const updateSkill = async (id, updates) => {
  try {
    const skill = await Skill.findByPk(id);
    if (!skill) throw new Error(`Skill with ID ${id} not found`);

    await skill.update(updates);
    return skill;
  } catch (error) {
    console.error("❌ Error updating Skill:", error);
    throw error;
  }
};

// Xóa skill
const deleteSkill = async (id) => {
  try {
    const skill = await Skill.findByPk(id);
    if (!skill) throw new Error(`Skill with ID ${id} not found`);

    await skill.destroy();
    return { success: true, message: `Skill with ID ${id} deleted` };
  } catch (error) {
    console.error("❌ Error deleting Skill:", error);
    throw error;
  }
};



export { getAllTestsWithCourses,
  getAllQuestionTypes,
  getAllParts,createPart,
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
 };