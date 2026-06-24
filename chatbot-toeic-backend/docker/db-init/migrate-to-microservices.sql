USE master;
GO

PRINT '==================================================';
PRINT 'STARTING DATABASE MIGRATION TO MICROSERVICES';
PRINT '==================================================';

-- 1. Create separate databases if they do not exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChatbotToeic_Auth')
BEGIN
    CREATE DATABASE ChatbotToeic_Auth;
    PRINT 'Created database: ChatbotToeic_Auth';
END
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChatbotToeic_Quiz')
BEGIN
    CREATE DATABASE ChatbotToeic_Quiz;
    PRINT 'Created database: ChatbotToeic_Quiz';
END
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChatbotToeic_Payment')
BEGIN
    CREATE DATABASE ChatbotToeic_Payment;
    PRINT 'Created database: ChatbotToeic_Payment';
END
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChatbotToeic_Chatbot')
BEGIN
    CREATE DATABASE ChatbotToeic_Chatbot;
    PRINT 'Created database: ChatbotToeic_Chatbot';
END
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ChatbotToeic_ML')
BEGIN
    CREATE DATABASE ChatbotToeic_ML;
    PRINT 'Created database: ChatbotToeic_ML';
END
GO

-- 2. Migrate Auth & User Service Tables (Users, Logs)
PRINT 'Migrating Auth & User Service Tables...';
USE ChatbotToeic_Auth;
GO
if OBJECT_ID('ChatbotToeic_Auth.dbo.Users') IS NULL
BEGIN
    SELECT * INTO ChatbotToeic_Auth.dbo.Users FROM ChatbotToeic.dbo.Users;
    ALTER TABLE ChatbotToeic_Auth.dbo.Users ADD CONSTRAINT PK_Users PRIMARY KEY (id);
    PRINT 'Migrated Users table.';
END
if OBJECT_ID('ChatbotToeic_Auth.dbo.Logs') IS NULL
BEGIN
    SELECT * INTO ChatbotToeic_Auth.dbo.Logs FROM ChatbotToeic.dbo.Logs;
    ALTER TABLE ChatbotToeic_Auth.dbo.Logs ADD CONSTRAINT PK_Logs PRIMARY KEY (id);
    PRINT 'Migrated Logs table.';
END
GO

-- 3. Migrate Quiz & Learning Service Tables (including Vocabulary)
PRINT 'Migrating Quiz, Learning & Vocabulary Tables...';
USE ChatbotToeic_Quiz;
GO
-- Core Learning / Test Tables
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Tests') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Tests FROM ChatbotToeic.dbo.Tests;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Tests ADD CONSTRAINT PK_Tests PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Questions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Questions FROM ChatbotToeic.dbo.Questions;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Questions ADD CONSTRAINT PK_Questions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.TestQuestions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.TestQuestions FROM ChatbotToeic.dbo.TestQuestions;
    ALTER TABLE ChatbotToeic_Quiz.dbo.TestQuestions ADD CONSTRAINT PK_TestQuestions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Part') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Part FROM ChatbotToeic.dbo.Part;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Part ADD CONSTRAINT PK_Part PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionType') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionType FROM ChatbotToeic.dbo.QuestionType;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionType ADD CONSTRAINT PK_QuestionType PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Skills') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Skills FROM ChatbotToeic.dbo.Skills;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Skills ADD CONSTRAINT PK_Skills PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionSkills') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionSkills FROM ChatbotToeic.dbo.QuestionSkills;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionSkills ADD CONSTRAINT PK_QuestionSkills PRIMARY KEY (questionId, skillId);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionStats') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionStats FROM ChatbotToeic.dbo.QuestionStats;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionStats ADD CONSTRAINT PK_QuestionStats PRIMARY KEY (questionId);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionEmbeddings') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionEmbeddings FROM ChatbotToeic.dbo.QuestionEmbeddings;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionEmbeddings ADD CONSTRAINT PK_QuestionEmbeddings PRIMARY KEY (questionId);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.MediaFiles') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.MediaFiles FROM ChatbotToeic.dbo.MediaFiles;
    ALTER TABLE ChatbotToeic_Quiz.dbo.MediaFiles ADD CONSTRAINT PK_MediaFiles PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionMediaMap') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionMediaMap FROM ChatbotToeic.dbo.QuestionMediaMap;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionMediaMap ADD CONSTRAINT PK_QuestionMediaMap PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Courses') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Courses FROM ChatbotToeic.dbo.Courses;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Courses ADD CONSTRAINT PK_Courses PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Test_Courses') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Test_Courses FROM ChatbotToeic.dbo.Test_Courses;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Test_Courses ADD CONSTRAINT PK_Test_Courses PRIMARY KEY (testId, courseId);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.UserTests') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.UserTests FROM ChatbotToeic.dbo.UserTests;
    ALTER TABLE ChatbotToeic_Quiz.dbo.UserTests ADD CONSTRAINT PK_UserTests PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.UserResults') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.UserResults FROM ChatbotToeic.dbo.UserResults;
    ALTER TABLE ChatbotToeic_Quiz.dbo.UserResults ADD CONSTRAINT PK_UserResults PRIMARY KEY (id);
END

-- Vocabulary Tables
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Vocabulary') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Vocabulary FROM ChatbotToeic.dbo.Vocabulary;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Vocabulary ADD CONSTRAINT PK_Vocabulary PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.UserVocabulary') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.UserVocabulary FROM ChatbotToeic.dbo.UserVocabulary;
    ALTER TABLE ChatbotToeic_Quiz.dbo.UserVocabulary ADD CONSTRAINT PK_UserVocabulary PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Pronunciations') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Pronunciations FROM ChatbotToeic.dbo.Pronunciations;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Pronunciations ADD CONSTRAINT PK_Pronunciations PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Meanings') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Meanings FROM ChatbotToeic.dbo.Meanings;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Meanings ADD CONSTRAINT PK_Meanings PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Synonyms') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Synonyms FROM ChatbotToeic.dbo.Synonyms;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Synonyms ADD CONSTRAINT PK_Synonyms PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Antonyms') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Antonyms FROM ChatbotToeic.dbo.Antonyms;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Antonyms ADD CONSTRAINT PK_Antonyms PRIMARY KEY (id);
END
PRINT 'Migrated Quiz & Vocabulary tables.';
GO

-- 4. Migrate Payment Service Tables (Subscription, UserSubscription, Transaction)
PRINT 'Migrating Payment Service Tables...';
USE ChatbotToeic_Payment;
GO
if OBJECT_ID('ChatbotToeic_Payment.dbo.Subscriptions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.Subscriptions FROM ChatbotToeic.dbo.Subscriptions;
    ALTER TABLE ChatbotToeic_Payment.dbo.Subscriptions ADD CONSTRAINT PK_Subscriptions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Payment.dbo.UserSubscriptions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.UserSubscriptions FROM ChatbotToeic.dbo.UserSubscriptions;
    ALTER TABLE ChatbotToeic_Payment.dbo.UserSubscriptions ADD CONSTRAINT PK_UserSubscriptions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Payment.dbo.Transactions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.Transactions FROM ChatbotToeic.dbo.Transactions;
    ALTER TABLE ChatbotToeic_Payment.dbo.Transactions ADD CONSTRAINT PK_Transactions PRIMARY KEY (id);
END
PRINT 'Migrated Payment tables.';
GO

-- 5. Migrate Chatbot Service Tables (Conversation, Message)
PRINT 'Migrating Chatbot Service Tables...';
USE ChatbotToeic_Chatbot;
GO
if OBJECT_ID('ChatbotToeic_Chatbot.dbo.Conversations') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Chatbot.dbo.Conversations FROM ChatbotToeic.dbo.Conversations;
    ALTER TABLE ChatbotToeic_Chatbot.dbo.Conversations ADD CONSTRAINT PK_Conversations PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Chatbot.dbo.Messages') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Chatbot.dbo.Messages FROM ChatbotToeic.dbo.Messages;
    ALTER TABLE ChatbotToeic_Chatbot.dbo.Messages ADD CONSTRAINT PK_Messages PRIMARY KEY (id);
END
PRINT 'Migrated Chatbot tables.';
GO

-- 6. Migrate ML Service Tables (MLPrediction, MLPredictionHistory)
PRINT 'Migrating ML Service Tables...';
USE ChatbotToeic_ML;
GO
if OBJECT_ID('ChatbotToeic_ML.dbo.MLPredictions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_ML.dbo.MLPredictions FROM ChatbotToeic.dbo.MLPredictions;
    ALTER TABLE ChatbotToeic_ML.dbo.MLPredictions ADD CONSTRAINT PK_MLPredictions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_ML.dbo.MLPredictionHistory') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_ML.dbo.MLPredictionHistory FROM ChatbotToeic.dbo.MLPredictionHistory;
    ALTER TABLE ChatbotToeic_ML.dbo.MLPredictionHistory ADD CONSTRAINT PK_MLPredictionHistory PRIMARY KEY (id);
END
PRINT 'Migrated ML tables to ChatbotToeic_ML.';
GO

-- 7. Sync ML Tables to ChatbotToeic_Quiz (since quiz-service manages ML queries directly)
USE ChatbotToeic_Quiz;
GO
if OBJECT_ID('ChatbotToeic_Quiz.dbo.MLPredictions') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.MLPredictions FROM ChatbotToeic.dbo.MLPredictions;
    ALTER TABLE ChatbotToeic_Quiz.dbo.MLPredictions ADD CONSTRAINT PK_MLPredictions PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.MLPredictionHistory') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.MLPredictionHistory FROM ChatbotToeic.dbo.MLPredictionHistory;
    ALTER TABLE ChatbotToeic_Quiz.dbo.MLPredictionHistory ADD CONSTRAINT PK_MLPredictionHistory PRIMARY KEY (id);
END
PRINT 'Migrated ML tables to ChatbotToeic_Quiz.';
GO

PRINT '==================================================';
PRINT 'DATABASE MIGRATION COMPLETED SUCCESSFULLY!';
PRINT '==================================================';
