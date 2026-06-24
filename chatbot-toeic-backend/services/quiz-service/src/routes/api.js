import express from 'express';
import vocabulariesRouter from './vocabularies_router.js';
import courseV1Router from './course_v1_router.js';
import testV1Router from './test_v1_router.js';
import statsV1Router from './stats_v1_router.js';
import uploadV1Router from './upload_v1_router.js';
import adminTestsRouter from './admin-tests_router.js';
import adminMetadataRouter from './admin-metadata_router.js';

const router = express.Router();

// === API v1 (New - RESTful Standard) ===
router.use('/v1/courses', courseV1Router);
router.use('/v1', testV1Router); // Handles /v1/tests and /v1/test-attempts
router.use('/v1/statistics', statsV1Router);
router.use('/v1/uploads', uploadV1Router);

// === Legacy API (Backward Compatibility) ===
router.use('/vocabulary', vocabulariesRouter);
router.use('/vocabularies', vocabulariesRouter); // RESTful Alias
router.use('/adminTest', adminTestsRouter); 
router.use('/admin-tests', adminTestsRouter); // RESTful Alias
router.use('/adminMetadata', adminMetadataRouter);
router.use('/admin-metadata', adminMetadataRouter); // RESTful Alias

export default router;