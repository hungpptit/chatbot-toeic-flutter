import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import cloudinary from "./cloudinary.js";

// ✅ File size limits
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_AUDIO_SIZE = 50 * 1024 * 1024; // 50MB

// ✅ Allowed file types
export const IMAGE_TYPES = ["image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"];
export const AUDIO_TYPES = ["audio/mpeg", "audio/mp3", "audio/wav", "audio/ogg"];

// Storage cho ảnh
const storageImage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "toeic-media/images",
    resource_type: "image",
    allowed_formats: ["jpg", "jpeg", "png", "gif", "webp"],
    transformation: [{ quality: "auto", fetch_format: "auto" }],
  },
});

// Storage cho audio
const storageAudio = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "toeic-media/audio",
    resource_type: "video",
    allowed_formats: ["mp3", "wav", "ogg"],
  },
});

// ✅ File filters
const imageFileFilter = (req, file, cb) => {
  if (IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`Invalid image type. Allowed: ${IMAGE_TYPES.join(", ")}`), false);
  }
};

const audioFileFilter = (req, file, cb) => {
  if (AUDIO_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`Invalid audio type. Allowed: ${AUDIO_TYPES.join(", ")}`), false);
  }
};

export const uploadImage = multer({
  storage: storageImage,
  limits: { fileSize: MAX_IMAGE_SIZE },
  fileFilter: imageFileFilter,
});

export const uploadAudio = multer({
  storage: storageAudio,
  limits: { fileSize: MAX_AUDIO_SIZE },
  fileFilter: audioFileFilter,
});
