-- Create Views for ChatbotToeic_Chatbot
USE ChatbotToeic_Chatbot;
GO
-- 1. Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Users', 'V') IS NOT NULL DROP VIEW dbo.Users;
EXEC('CREATE VIEW dbo.Users AS SELECT * FROM ChatbotToeic_Auth.dbo.Users');

-- 2. Logs
IF OBJECT_ID('dbo.Logs', 'U') IS NOT NULL DROP TABLE dbo.Logs;
IF OBJECT_ID('dbo.Logs', 'V') IS NOT NULL DROP VIEW dbo.Logs;
EXEC('CREATE VIEW dbo.Logs AS SELECT * FROM ChatbotToeic_Auth.dbo.Logs');

-- 3. Quiz database tables
IF OBJECT_ID('dbo.Tests', 'U') IS NOT NULL DROP TABLE dbo.Tests;
IF OBJECT_ID('dbo.Tests', 'V') IS NOT NULL DROP VIEW dbo.Tests;
EXEC('CREATE VIEW dbo.Tests AS SELECT * FROM ChatbotToeic_Quiz.dbo.Tests');

IF OBJECT_ID('dbo.Questions', 'U') IS NOT NULL DROP TABLE dbo.Questions;
IF OBJECT_ID('dbo.Questions', 'V') IS NOT NULL DROP VIEW dbo.Questions;
EXEC('CREATE VIEW dbo.Questions AS SELECT * FROM ChatbotToeic_Quiz.dbo.Questions');

IF OBJECT_ID('dbo.TestQuestions', 'U') IS NOT NULL DROP TABLE dbo.TestQuestions;
IF OBJECT_ID('dbo.TestQuestions', 'V') IS NOT NULL DROP VIEW dbo.TestQuestions;
EXEC('CREATE VIEW dbo.TestQuestions AS SELECT * FROM ChatbotToeic_Quiz.dbo.TestQuestions');

IF OBJECT_ID('dbo.Part', 'U') IS NOT NULL DROP TABLE dbo.Part;
IF OBJECT_ID('dbo.Part', 'V') IS NOT NULL DROP VIEW dbo.Part;
EXEC('CREATE VIEW dbo.Part AS SELECT * FROM ChatbotToeic_Quiz.dbo.Part');

IF OBJECT_ID('dbo.QuestionType', 'U') IS NOT NULL DROP TABLE dbo.QuestionType;
IF OBJECT_ID('dbo.QuestionType', 'V') IS NOT NULL DROP VIEW dbo.QuestionType;
EXEC('CREATE VIEW dbo.QuestionType AS SELECT * FROM ChatbotToeic_Quiz.dbo.QuestionType');

IF OBJECT_ID('dbo.Skills', 'U') IS NOT NULL DROP TABLE dbo.Skills;
IF OBJECT_ID('dbo.Skills', 'V') IS NOT NULL DROP VIEW dbo.Skills;
EXEC('CREATE VIEW dbo.Skills AS SELECT * FROM ChatbotToeic_Quiz.dbo.Skills');

IF OBJECT_ID('dbo.QuestionSkills', 'U') IS NOT NULL DROP TABLE dbo.QuestionSkills;
IF OBJECT_ID('dbo.QuestionSkills', 'V') IS NOT NULL DROP VIEW dbo.QuestionSkills;
EXEC('CREATE VIEW dbo.QuestionSkills AS SELECT * FROM ChatbotToeic_Quiz.dbo.QuestionSkills');

IF OBJECT_ID('dbo.QuestionStats', 'U') IS NOT NULL DROP TABLE dbo.QuestionStats;
IF OBJECT_ID('dbo.QuestionStats', 'V') IS NOT NULL DROP VIEW dbo.QuestionStats;
EXEC('CREATE VIEW dbo.QuestionStats AS SELECT * FROM ChatbotToeic_Quiz.dbo.QuestionStats');

IF OBJECT_ID('dbo.QuestionEmbeddings', 'U') IS NOT NULL DROP TABLE dbo.QuestionEmbeddings;
IF OBJECT_ID('dbo.QuestionEmbeddings', 'V') IS NOT NULL DROP VIEW dbo.QuestionEmbeddings;
EXEC('CREATE VIEW dbo.QuestionEmbeddings AS SELECT * FROM ChatbotToeic_Quiz.dbo.QuestionEmbeddings');

IF OBJECT_ID('dbo.MediaFiles', 'U') IS NOT NULL DROP TABLE dbo.MediaFiles;
IF OBJECT_ID('dbo.MediaFiles', 'V') IS NOT NULL DROP VIEW dbo.MediaFiles;
EXEC('CREATE VIEW dbo.MediaFiles AS SELECT * FROM ChatbotToeic_Quiz.dbo.MediaFiles');

IF OBJECT_ID('dbo.QuestionMediaMap', 'U') IS NOT NULL DROP TABLE dbo.QuestionMediaMap;
IF OBJECT_ID('dbo.QuestionMediaMap', 'V') IS NOT NULL DROP VIEW dbo.QuestionMediaMap;
EXEC('CREATE VIEW dbo.QuestionMediaMap AS SELECT * FROM ChatbotToeic_Quiz.dbo.QuestionMediaMap');

IF OBJECT_ID('dbo.Courses', 'U') IS NOT NULL DROP TABLE dbo.Courses;
IF OBJECT_ID('dbo.Courses', 'V') IS NOT NULL DROP VIEW dbo.Courses;
EXEC('CREATE VIEW dbo.Courses AS SELECT * FROM ChatbotToeic_Quiz.dbo.Courses');

IF OBJECT_ID('dbo.Test_Courses', 'U') IS NOT NULL DROP TABLE dbo.Test_Courses;
IF OBJECT_ID('dbo.Test_Courses', 'V') IS NOT NULL DROP VIEW dbo.Test_Courses;
EXEC('CREATE VIEW dbo.Test_Courses AS SELECT * FROM ChatbotToeic_Quiz.dbo.Test_Courses');

IF OBJECT_ID('dbo.UserTests', 'U') IS NOT NULL DROP TABLE dbo.UserTests;
IF OBJECT_ID('dbo.UserTests', 'V') IS NOT NULL DROP VIEW dbo.UserTests;
EXEC('CREATE VIEW dbo.UserTests AS SELECT * FROM ChatbotToeic_Quiz.dbo.UserTests');

IF OBJECT_ID('dbo.UserResults', 'U') IS NOT NULL DROP TABLE dbo.UserResults;
IF OBJECT_ID('dbo.UserResults', 'V') IS NOT NULL DROP VIEW dbo.UserResults;
EXEC('CREATE VIEW dbo.UserResults AS SELECT * FROM ChatbotToeic_Quiz.dbo.UserResults');

IF OBJECT_ID('dbo.Vocabulary', 'U') IS NOT NULL DROP TABLE dbo.Vocabulary;
IF OBJECT_ID('dbo.Vocabulary', 'V') IS NOT NULL DROP VIEW dbo.Vocabulary;
EXEC('CREATE VIEW dbo.Vocabulary AS SELECT * FROM ChatbotToeic_Quiz.dbo.Vocabulary');

IF OBJECT_ID('dbo.UserVocabulary', 'U') IS NOT NULL DROP TABLE dbo.UserVocabulary;
IF OBJECT_ID('dbo.UserVocabulary', 'V') IS NOT NULL DROP VIEW dbo.UserVocabulary;
EXEC('CREATE VIEW dbo.UserVocabulary AS SELECT * FROM ChatbotToeic_Quiz.dbo.UserVocabulary');

IF OBJECT_ID('dbo.Pronunciations', 'U') IS NOT NULL DROP TABLE dbo.Pronunciations;
IF OBJECT_ID('dbo.Pronunciations', 'V') IS NOT NULL DROP VIEW dbo.Pronunciations;
EXEC('CREATE VIEW dbo.Pronunciations AS SELECT * FROM ChatbotToeic_Quiz.dbo.Pronunciations');

IF OBJECT_ID('dbo.Meanings', 'U') IS NOT NULL DROP TABLE dbo.Meanings;
IF OBJECT_ID('dbo.Meanings', 'V') IS NOT NULL DROP VIEW dbo.Meanings;
EXEC('CREATE VIEW dbo.Meanings AS SELECT * FROM ChatbotToeic_Quiz.dbo.Meanings');

IF OBJECT_ID('dbo.Synonyms', 'U') IS NOT NULL DROP TABLE dbo.Synonyms;
IF OBJECT_ID('dbo.Synonyms', 'V') IS NOT NULL DROP VIEW dbo.Synonyms;
EXEC('CREATE VIEW dbo.Synonyms AS SELECT * FROM ChatbotToeic_Quiz.dbo.Synonyms');

IF OBJECT_ID('dbo.Antonyms', 'U') IS NOT NULL DROP TABLE dbo.Antonyms;
IF OBJECT_ID('dbo.Antonyms', 'V') IS NOT NULL DROP VIEW dbo.Antonyms;
EXEC('CREATE VIEW dbo.Antonyms AS SELECT * FROM ChatbotToeic_Quiz.dbo.Antonyms');

-- ML database tables
IF OBJECT_ID('dbo.MLPredictions', 'U') IS NOT NULL DROP TABLE dbo.MLPredictions;
IF OBJECT_ID('dbo.MLPredictions', 'V') IS NOT NULL DROP VIEW dbo.MLPredictions;
EXEC('CREATE VIEW dbo.MLPredictions AS SELECT * FROM ChatbotToeic_ML.dbo.MLPredictions');

IF OBJECT_ID('dbo.MLPredictionHistory', 'U') IS NOT NULL DROP TABLE dbo.MLPredictionHistory;
IF OBJECT_ID('dbo.MLPredictionHistory', 'V') IS NOT NULL DROP VIEW dbo.MLPredictionHistory;
EXEC('CREATE VIEW dbo.MLPredictionHistory AS SELECT * FROM ChatbotToeic_ML.dbo.MLPredictionHistory');

-- 4. Payment database tables
IF OBJECT_ID('dbo.Subscriptions', 'U') IS NOT NULL DROP TABLE dbo.Subscriptions;
IF OBJECT_ID('dbo.Subscriptions', 'V') IS NOT NULL DROP VIEW dbo.Subscriptions;
EXEC('CREATE VIEW dbo.Subscriptions AS SELECT * FROM ChatbotToeic_Payment.dbo.Subscriptions');

IF OBJECT_ID('dbo.UserSubscriptions', 'U') IS NOT NULL DROP TABLE dbo.UserSubscriptions;
IF OBJECT_ID('dbo.UserSubscriptions', 'V') IS NOT NULL DROP VIEW dbo.UserSubscriptions;
EXEC('CREATE VIEW dbo.UserSubscriptions AS SELECT * FROM ChatbotToeic_Payment.dbo.UserSubscriptions');

IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL DROP TABLE dbo.Transactions;
IF OBJECT_ID('dbo.Transactions', 'V') IS NOT NULL DROP VIEW dbo.Transactions;
EXEC('CREATE VIEW dbo.Transactions AS SELECT * FROM ChatbotToeic_Payment.dbo.Transactions');
GO


-- Create Views for ChatbotToeic_Quiz
USE ChatbotToeic_Quiz;
GO
-- 1. Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Users', 'V') IS NOT NULL DROP VIEW dbo.Users;
EXEC('CREATE VIEW dbo.Users AS SELECT * FROM ChatbotToeic_Auth.dbo.Users');

-- 2. Logs
IF OBJECT_ID('dbo.Logs', 'U') IS NOT NULL DROP TABLE dbo.Logs;
IF OBJECT_ID('dbo.Logs', 'V') IS NOT NULL DROP VIEW dbo.Logs;
EXEC('CREATE VIEW dbo.Logs AS SELECT * FROM ChatbotToeic_Auth.dbo.Logs');

-- 3. ML database tables
IF OBJECT_ID('dbo.MLPredictions', 'U') IS NOT NULL DROP TABLE dbo.MLPredictions;
IF OBJECT_ID('dbo.MLPredictions', 'V') IS NOT NULL DROP VIEW dbo.MLPredictions;
EXEC('CREATE VIEW dbo.MLPredictions AS SELECT * FROM ChatbotToeic_ML.dbo.MLPredictions');

IF OBJECT_ID('dbo.MLPredictionHistory', 'U') IS NOT NULL DROP TABLE dbo.MLPredictionHistory;
IF OBJECT_ID('dbo.MLPredictionHistory', 'V') IS NOT NULL DROP VIEW dbo.MLPredictionHistory;
EXEC('CREATE VIEW dbo.MLPredictionHistory AS SELECT * FROM ChatbotToeic_ML.dbo.MLPredictionHistory');

-- 4. Payment database tables
IF OBJECT_ID('dbo.Subscriptions', 'U') IS NOT NULL DROP TABLE dbo.Subscriptions;
IF OBJECT_ID('dbo.Subscriptions', 'V') IS NOT NULL DROP VIEW dbo.Subscriptions;
EXEC('CREATE VIEW dbo.Subscriptions AS SELECT * FROM ChatbotToeic_Payment.dbo.Subscriptions');

IF OBJECT_ID('dbo.UserSubscriptions', 'U') IS NOT NULL DROP TABLE dbo.UserSubscriptions;
IF OBJECT_ID('dbo.UserSubscriptions', 'V') IS NOT NULL DROP VIEW dbo.UserSubscriptions;
EXEC('CREATE VIEW dbo.UserSubscriptions AS SELECT * FROM ChatbotToeic_Payment.dbo.UserSubscriptions');

IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL DROP TABLE dbo.Transactions;
IF OBJECT_ID('dbo.Transactions', 'V') IS NOT NULL DROP VIEW dbo.Transactions;
EXEC('CREATE VIEW dbo.Transactions AS SELECT * FROM ChatbotToeic_Payment.dbo.Transactions');
GO


-- Create Views for ChatbotToeic_Payment
USE ChatbotToeic_Payment;
GO
-- 1. Users
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Users', 'V') IS NOT NULL DROP VIEW dbo.Users;
EXEC('CREATE VIEW dbo.Users AS SELECT * FROM ChatbotToeic_Auth.dbo.Users');

-- 2. Logs
IF OBJECT_ID('dbo.Logs', 'U') IS NOT NULL DROP TABLE dbo.Logs;
IF OBJECT_ID('dbo.Logs', 'V') IS NOT NULL DROP VIEW dbo.Logs;
EXEC('CREATE VIEW dbo.Logs AS SELECT * FROM ChatbotToeic_Auth.dbo.Logs');
GO
