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
if OBJECT_ID('ChatbotToeic_Quiz.dbo.TestQuestion') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.TestQuestion FROM ChatbotToeic.dbo.TestQuestion;
    ALTER TABLE ChatbotToeic_Quiz.dbo.TestQuestion ADD CONSTRAINT PK_TestQuestion PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.Part') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.Part FROM ChatbotToeic.dbo.Part;
    ALTER TABLE ChatbotToeic_Quiz.dbo.Part ADD CONSTRAINT PK_Part PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionType') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionType FROM ChatbotToeic.dbo.QuestionType;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionType ADD CONSTRAINT PK_QuestionType PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.skill') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.skill FROM ChatbotToeic.dbo.skill;
    ALTER TABLE ChatbotToeic_Quiz.dbo.skill ADD CONSTRAINT PK_skill PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionSkills') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionSkills FROM ChatbotToeic.dbo.QuestionSkills;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionSkills ADD CONSTRAINT PK_QuestionSkills PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionStats') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionStats FROM ChatbotToeic.dbo.QuestionStats;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionStats ADD CONSTRAINT PK_QuestionStats PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.QuestionEmbeddings') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.QuestionEmbeddings FROM ChatbotToeic.dbo.QuestionEmbeddings;
    ALTER TABLE ChatbotToeic_Quiz.dbo.QuestionEmbeddings ADD CONSTRAINT PK_QuestionEmbeddings PRIMARY KEY (id);
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
if OBJECT_ID('ChatbotToeic_Quiz.dbo.TestCourse') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.TestCourse FROM ChatbotToeic.dbo.TestCourse;
    ALTER TABLE ChatbotToeic_Quiz.dbo.TestCourse ADD CONSTRAINT PK_TestCourse PRIMARY KEY (id);
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
if OBJECT_ID('ChatbotToeic_Quiz.dbo.meaning') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.meaning FROM ChatbotToeic.dbo.meaning;
    ALTER TABLE ChatbotToeic_Quiz.dbo.meaning ADD CONSTRAINT PK_meaning PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.synonym') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.synonym FROM ChatbotToeic.dbo.synonym;
    ALTER TABLE ChatbotToeic_Quiz.dbo.synonym ADD CONSTRAINT PK_synonym PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Quiz.dbo.antonym') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Quiz.dbo.antonym FROM ChatbotToeic.dbo.antonym;
    ALTER TABLE ChatbotToeic_Quiz.dbo.antonym ADD CONSTRAINT PK_antonym PRIMARY KEY (id);
END
PRINT 'Migrated Quiz & Vocabulary tables.';
GO

-- 4. Migrate Payment Service Tables (Subscription, UserSubscription, Transaction)
PRINT 'Migrating Payment Service Tables...';
USE ChatbotToeic_Payment;
GO
if OBJECT_ID('ChatbotToeic_Payment.dbo.Subscription') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.Subscription FROM ChatbotToeic.dbo.Subscription;
    ALTER TABLE ChatbotToeic_Payment.dbo.Subscription ADD CONSTRAINT PK_Subscription PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Payment.dbo.UserSubscription') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.UserSubscription FROM ChatbotToeic.dbo.UserSubscription;
    ALTER TABLE ChatbotToeic_Payment.dbo.UserSubscription ADD CONSTRAINT PK_UserSubscription PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Payment.dbo.Transaction') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Payment.dbo.Transaction FROM ChatbotToeic.dbo.Transaction;
    ALTER TABLE ChatbotToeic_Payment.dbo.Transaction ADD CONSTRAINT PK_Transaction PRIMARY KEY (id);
END
PRINT 'Migrated Payment tables.';
GO

-- 5. Migrate Chatbot Service Tables (Conversation, Message)
PRINT 'Migrating Chatbot Service Tables...';
USE ChatbotToeic_Chatbot;
GO
if OBJECT_ID('ChatbotToeic_Chatbot.dbo.Conversation') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Chatbot.dbo.Conversation FROM ChatbotToeic.dbo.Conversation;
    ALTER TABLE ChatbotToeic_Chatbot.dbo.Conversation ADD CONSTRAINT PK_Conversation PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_Chatbot.dbo.Message') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_Chatbot.dbo.Message FROM ChatbotToeic.dbo.Message;
    ALTER TABLE ChatbotToeic_Chatbot.dbo.Message ADD CONSTRAINT PK_Message PRIMARY KEY (id);
END
PRINT 'Migrated Chatbot tables.';
GO

-- 6. Migrate ML Service Tables (MLPrediction, MLPredictionHistory)
PRINT 'Migrating ML Service Tables...';
USE ChatbotToeic_ML;
GO
if OBJECT_ID('ChatbotToeic_ML.dbo.MLPrediction') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_ML.dbo.MLPrediction FROM ChatbotToeic.dbo.MLPrediction;
    ALTER TABLE ChatbotToeic_ML.dbo.MLPrediction ADD CONSTRAINT PK_MLPrediction PRIMARY KEY (id);
END
if OBJECT_ID('ChatbotToeic_ML.dbo.MLPredictionHistory') IS NULL BEGIN
    SELECT * INTO ChatbotToeic_ML.dbo.MLPredictionHistory FROM ChatbotToeic.dbo.MLPredictionHistory;
    ALTER TABLE ChatbotToeic_ML.dbo.MLPredictionHistory ADD CONSTRAINT PK_MLPredictionHistory PRIMARY KEY (id);
END
PRINT 'Migrated ML tables.';
GO

PRINT '==================================================';
PRINT 'DATABASE MIGRATION COMPLETED SUCCESSFULLY!';
PRINT '==================================================';
