import db from '../models/index.js';

const Part = db.Part;
const QuestionType = db.QuestionType;
const Skill = db.Skill;

// === Part Controllers ===
export const getAllParts = async (req, res) => {
    try {
        const parts = await Part.findAll({ order: [['id', 'ASC']] });
        res.status(200).json(parts);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching parts', error: error.message });
    }
};

export const createPart = async (req, res) => {
    try {
        const { name } = req.body;
        const newPart = await Part.create({ name });
        res.status(201).json(newPart);
    } catch (error) {
        res.status(500).json({ message: 'Error creating part', error: error.message });
    }
};

export const updatePart = async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;
        const part = await Part.findByPk(id);
        if (!part) return res.status(404).json({ message: 'Part not found' });
        
        part.name = name;
        await part.save();
        res.status(200).json(part);
    } catch (error) {
        res.status(500).json({ message: 'Error updating part', error: error.message });
    }
};

export const deletePart = async (req, res) => {
    try {
        const { id } = req.params;
        const part = await Part.findByPk(id);
        if (!part) return res.status(404).json({ message: 'Part not found' });
        
        await part.destroy();
        res.status(200).json({ message: 'Part deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting part', error: error.message });
    }
};

// === QuestionType Controllers ===
export const getAllTypes = async (req, res) => {
    try {
        const types = await QuestionType.findAll({ order: [['id', 'ASC']] });
        res.status(200).json(types);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching types', error: error.message });
    }
};

export const createType = async (req, res) => {
    try {
        const { name, description } = req.body;
        const newType = await QuestionType.create({ name, description });
        res.status(201).json(newType);
    } catch (error) {
        res.status(500).json({ message: 'Error creating type', error: error.message });
    }
};

export const updateType = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description } = req.body;
        const type = await QuestionType.findByPk(id);
        if (!type) return res.status(404).json({ message: 'Type not found' });
        
        type.name = name;
        type.description = description;
        await type.save();
        res.status(200).json(type);
    } catch (error) {
        res.status(500).json({ message: 'Error updating type', error: error.message });
    }
};

export const deleteType = async (req, res) => {
    try {
        const { id } = req.params;
        const type = await QuestionType.findByPk(id);
        if (!type) return res.status(404).json({ message: 'Type not found' });
        
        await type.destroy();
        res.status(200).json({ message: 'Type deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting type', error: error.message });
    }
};

// === Skill Controllers ===
export const getAllSkills = async (req, res) => {
    try {
        const skills = await Skill.findAll({ 
            order: [['id', 'ASC']],
            include: [{ model: Skill, as: 'children' }]
        });
        res.status(200).json(skills);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching skills', error: error.message });
    }
};

export const createSkill = async (req, res) => {
    try {
        const { name, description, parentId } = req.body;
        const newSkill = await Skill.create({ name, description, parentId });
        res.status(201).json(newSkill);
    } catch (error) {
        res.status(500).json({ message: 'Error creating skill', error: error.message });
    }
};

export const updateSkill = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, parentId } = req.body;
        const skill = await Skill.findByPk(id);
        if (!skill) return res.status(404).json({ message: 'Skill not found' });
        
        skill.name = name;
        skill.description = description;
        skill.parentId = parentId;
        await skill.save();
        res.status(200).json(skill);
    } catch (error) {
        res.status(500).json({ message: 'Error updating skill', error: error.message });
    }
};

export const deleteSkill = async (req, res) => {
    try {
        const { id } = req.params;
        const skill = await Skill.findByPk(id);
        if (!skill) return res.status(404).json({ message: 'Skill not found' });
        
        await skill.destroy();
        res.status(200).json({ message: 'Skill deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting skill', error: error.message });
    }
};
