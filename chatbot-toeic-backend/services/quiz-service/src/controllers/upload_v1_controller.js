import cloudinary from "../config/cloudinary.js";
import ffprobe from "ffprobe";
import ffprobeStatic from "ffprobe-static";
import { 
    batchUploadFromPaths, 
    validatePaths 
} from '../services/batchUploadService.js';
import { sendSuccess, sendError } from "../utils/response.js";

/**
 * POST /api/v1/uploads/images
 */
export const uploadImageV1 = async (req, res) => {
    try {
        if (!req.file) {
            return sendError(res, 400, "No file uploaded");
        }

        const data = {
            type: "image",
            url: req.file.path,
            publicId: req.file.filename,
            size: req.file.size,
            format: req.file.format,
        };

        return sendSuccess(res, data, "Image uploaded successfully");
    } catch (err) {
        console.error("[UPLOAD V1] uploadImageV1 error:", err);
        return sendError(res, 500, "Upload failed", [err.message]);
    }
};

/**
 * POST /api/v1/uploads/audio
 */
export const uploadAudioV1 = async (req, res) => {
    try {
        if (!req.file) {
            return sendError(res, 400, "No file uploaded");
        }

        let duration = null;
        try {
            const cloudinaryResult = await cloudinary.api.resource(req.file.filename, {
                resource_type: "video"
            });
            duration = cloudinaryResult.duration || null;
        } catch (metadataError) {
            console.warn("⚠️ Could not fetch audio metadata from Cloudinary:", metadataError.message);
        }

        if (!duration) {
            try {
                const probeData = await ffprobe(req.file.path, { path: ffprobeStatic.path });
                duration = probeData?.streams?.[0]?.duration || null;
            } catch (urlProbeError) {
                console.warn("⚠️ Could not probe audio from URL:", urlProbeError.message);
            }
        }

        const data = {
            type: "audio",
            url: req.file.path,
            publicId: req.file.filename,
            size: req.file.size,
            format: req.file.format,
            duration: duration ? parseFloat(duration) : null,
        };

        return sendSuccess(res, data, "Audio uploaded successfully");
    } catch (err) {
        console.error("[UPLOAD V1] uploadAudioV1 error:", err);
        return sendError(res, 500, "Upload failed", [err.message]);
    }
};

/**
 * DELETE /api/v1/uploads/:publicId
 */
export const deleteUploadV1 = async (req, res) => {
    try {
        const { publicId } = req.params;
        const { resourceType } = req.query; // 'image' or 'video'

        if (!publicId) return sendError(res, 400, "Public ID is required");

        const result = await cloudinary.uploader.destroy(publicId, {
            resource_type: resourceType || "image",
        });

        if (result.result === "ok") {
            return sendSuccess(res, { publicId }, "File deleted successfully");
        } else {
            return sendError(res, 404, "File not found or already deleted");
        }
    } catch (err) {
        console.error("[UPLOAD V1] deleteUploadV1 error:", err);
        return sendError(res, 500, "Delete failed", [err.message]);
    }
};

/**
 * POST /api/v1/uploads/batch
 */
export const batchUploadV1 = async (req, res) => {
    try {
        const testData = req.body;
        if (!testData) return sendError(res, 400, "No data provided");

        const invalidPaths = await validatePaths(testData);
        if (invalidPaths.length > 0) {
            return sendError(res, 400, "Some file paths are invalid", invalidPaths);
        }

        const uploadedTestData = await batchUploadFromPaths(testData);
        return sendSuccess(res, uploadedTestData, "Batch upload completed successfully");
    } catch (error) {
        console.error("[UPLOAD V1] batchUploadV1 error:", error);
        return sendError(res, 500, "Batch upload failed", [error.message]);
    }
};

/**
 * POST /api/v1/uploads/validate-paths
 */
export const validatePathsV1 = async (req, res) => {
    try {
        const testData = req.body;
        if (!testData) return sendError(res, 400, "No data provided");

        const invalidPaths = await validatePaths(testData);
        if (invalidPaths.length > 0) {
            return sendError(res, 400, "Some paths are invalid", invalidPaths);
        }

        return sendSuccess(res, null, "All paths are valid");
    } catch (error) {
        console.error("[UPLOAD V1] validatePathsV1 error:", error);
        return sendError(res, 500, "Validation failed", [error.message]);
    }
};
