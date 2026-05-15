# Listening Test Implementation Guide

## Overview

The listening test feature has been redesigned to support **continuous audio playback** with automatic UI switching based on audio timing. The system now plays a single unified audio file and tracks the audio position to automatically advance questions.

## Key Features

✅ **Unified Audio Playback**: Single audio file contains all questions (no pause/reload between questions)  
✅ **Seamless Audio**: No seeking or time manipulation - audio plays continuously  
✅ **Auto-Switch Logic**: Questions auto-advance when audio reaches `endSecond` of current question  
✅ **No Manual Navigation**: Users cannot manually jump/go back during listening test  
✅ **Real-time Timing Display**: Shows current audio position vs. question end time  

## Data Structure Required

Each listening test API response **MUST** include:

```json
{
  "title": "TOEIC Listening Part 1",
  "courseId": 1,
  "partId": 1,
  "audioPath": "https://example.com/path/to/unified-audio.mp3",
  "questions": [
    {
      "id": 1,
      "question": "What is the man doing?",
      "imagePath": "https://example.com/image.jpg",
      "startSecond": 0.0,
      "endSecond": 15.5,
      "optionA": "He is walking",
      "optionB": "He is sitting",
      "optionC": "He is reading",
      "optionD": "He is talking",
      "correctAnswer": "A",
      "partId": 1,
      "typeId": 1,
      "skillId": 6,
      "explanation": "The man is walking..."
    },
    {
      "id": 2,
      "question": "Where are the people?",
      "imagePath": "https://example.com/image2.jpg",
      "startSecond": 20.0,
      "endSecond": 38.3,
      "optionA": "In a restaurant",
      "optionB": "In an office",
      "optionC": "In a park",
      "optionD": "In a library",
      "correctAnswer": "C",
      "partId": 1,
      "typeId": 1,
      "skillId": 6,
      "explanation": "The picture shows people in a park..."
    }
  ]
}
```

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `audioPath` | string | Full URL/path to unified audio file | `"https://cdn.example.com/audio/test-1-unified.mp3"` |
| `startSecond` | number | Audio start time for question (informational) | `0.0` |
| `endSecond` | number | Audio end time - triggers auto-switch to next question | `15.5` |
| `partId` | number | Part number (1-4 = Listening, 5+ = Reading) | `1` |

## Controller Changes

### New Properties in `TestController`

```dart
var audioPath = ''.obs;                                    // Full audio file path
var currentAudioPosition = 0.0.obs;                        // Current playback position (seconds)
late StreamSubscription<Duration> _audioPositionSubscription;
```

### New Methods

#### `_startListeningMode()`
- Called when `testStarted = true`
- Loads the unified audio file from `audioPath`
- Sets up position listener
- Starts playback from beginning

#### `_setupAudioPositionListener()`
- Monitors `player.positionStream`
- Compares `currentAudioPosition` with `endSecond` of current question
- Calls `_autoSwitchToNextQuestion()` when threshold is reached
- **Does NOT use `player.seek()`** - maintains seamless playback

#### `_autoSwitchToNextQuestion()`
- Simply increments `currentQuestionIndex`
- UI automatically rebuilds to show new question
- No audio manipulation

### Modified Methods

#### `nextQuestion()`, `previousQuestion()`, `goToQuestion()`
- **DISABLED** when `isListeningTest.value && isTestActive.value`
- Returns early with warning message
- Prevents user navigation during listening test

#### `fetchQuestions(int id)`
- Now extracts `audioPath` from API response
- Stores it in `audioPath` observable
- Detects listening test type (partId 1-4)
- Locks device orientation to portrait

## API Integration

### Expected Endpoint Response Format

```http
GET /v1/tests/{testId}/questions

Response 200:
{
  "data": {
    "title": "TOEIC Listening Part 1",
    "courseId": 1,
    "partId": 1,
    "audioPath": "https://cdn.example.com/audio/test-1-unified.mp3",
    "questions": [
      { /* question objects */ }
    ]
  }
}
```

Or direct array format:

```http
GET /v1/tests/{testId}/questions

Response 200:
{
  "title": "...",
  "audioPath": "...",
  "questions": [ /* ... */ ]
}
```

## UI Changes

### Footer Display (Listening Test Mode)

**Before:**
```
Câu 1/20 [Danh sách câu]
```

**After:**
```
Câu 1/20
Âm thanh: 12.5s / 15.5s [Danh sách câu]
```

Shows real-time audio position vs. end time of current question.

### Navigation Controls (Listening Test Mode)

- **Previous/Next Buttons**: Hidden during listening test
- **Question Menu**: Still accessible (read-only reference)
- **Manual Jump**: Disabled
- **Start Button**: Keeps existing logic (sets `testStarted = true`)

## Flow Diagram

```
User clicks START button
        ↓
controller.testStarted.value = true
        ↓
_startListeningMode() called
        ↓
Load unified audio from audioPath
        ↓
_setupAudioPositionListener() activated
        ↓
Start playback
        ↓
Listen to position stream continuously
        ↓
When currentTime >= endSecond:
  - currentQuestionIndex++
  - UI rebuilds (Obx trigger)
  - New question displayed
        ↓
When currentTime >= endSecond of LAST question:
  - Continue playing until audio completes
  - Then auto-submit test
```

## Example Usage Walkthrough

### 1. User Navigation to Test
```dart
// TestDetailView receives testId
TestDetailView(testId: 1, key: Key('test_1'))

// Controller fetches questions
await testController.fetchQuestions(1);

// Response includes:
// - audioPath: "https://cdn.example.com/test-1-audio.mp3"
// - questions: [Q1, Q2, Q3, ...] with startSecond/endSecond
// - Detects: isListeningTest = true (partId = 1)
// - Locks orientation to portrait
```

### 2. User Starts Listening Test
```dart
// User sees listening intro screen (Part 1 explanation)
// Clicks "BẮT ĐẦU" button

// Button calls:
controller.testStarted.value = true;

// TestController listener triggers:
ever(testStarted, (started) {
  if (started && isListeningTest.value) {
    _startListeningMode();
  }
});

// _startListeningMode():
// 1. Loads audio from audioPath
// 2. Sets up positionListener
// 3. Calls player.play()
// 4. Audio starts from 0:00
```

### 3. Audio Playback and Auto-Switch
```dart
// Audio is at: 0:00 to 15:50
// Question 1: startSecond: 0.0, endSecond: 15.5

// positionStream emits:
// Position 0:05 -> compare 5.0 with 15.5 -> no action
// Position 10:00 -> compare 10.0 with 15.5 -> no action
// Position 15:50 -> compare 15.5 with 15.5 -> ACTION!

// _autoSwitchToNextQuestion() called:
currentQuestionIndex.value++; // 0 -> 1
// Obx rebuilds UI with Q2

// UI now shows Question 2:
// "Where are the people?"
// startSecond: 20.0, endSecond: 38.3
// Real-time display: "Âm thanh: 15.5s / 38.3s"

// Audio continues (NO SEEK) from 15:50 to 38:30...
// When reaches 38:30 -> Q3 is shown
// And so on...
```

### 4. Test End
```dart
// Last question reached, audio continues naturally
// When audio.playerState == completed:
// - Listen stream ends
// - Auto-submit is triggered
// - User navigates to results page
```

## Important: Audio File Preparation

### Audio File Requirements

1. **Format**: MP3, WAV, or any format supported by `just_audio`
2. **Timing**: Each question's audio must fit within its `startSecond` to `endSecond` range
3. **Silence**: Can have silence/breaks between questions (within time windows)
4. **Example Timing**:
   ```
   Question 1: 0:00 - 15:50 (15.5s duration, includes instructions read-aloud)
   [Silence: 15:50 - 20:00]
   Question 2: 20:00 - 38:30 (18.3s)
   [Silence: 38:30 - 40:00]
   Question 3: 40:00 - 57:20 (17.2s)
   ...
   ```

## Backend API Implementation Checklist

- [ ] `/v1/tests/{testId}/questions` endpoint returns `audioPath`
- [ ] `audioPath` is a direct URL to unified audio file (not API endpoint)
- [ ] Each question has accurate `startSecond` and `endSecond`
- [ ] All questions for same test have `partId` consistency
- [ ] Audio file is hosted on CDN with CORS headers enabled
- [ ] Audio durations match test specifications

## Debugging

### Enable Console Logging

All key events are logged:
- `🎬` = Test state changes
- `🎵` = Audio playback events
- `⏱️` = Position updates
- `➡️` = Auto-switch events
- `❌` = Errors

Example console output:
```
🎬 Listening test started - loading unified audio
🔊 Setting up audio position listener...
🎵 Starting listening mode...
   - Audio path: https://cdn.example.com/audio/test-1.mp3
   ✅ Audio loaded
   ✅ Position listener setup complete
   ✅ Playback started
⏱️  Position 15.5 >= endSecond 15.5
   ➡️  Auto-switching to next question
   ✅ Question index updated to: 1
```

### Common Issues

**Issue**: Questions not auto-switching
- Check: `audioPath` is not empty
- Check: `startSecond` and `endSecond` are accurate
- Check: Audio file actually has content at those times
- Verify: Console shows position updates

**Issue**: Audio plays but questions don't show
- Check: `isListeningTest` is true
- Check: `currentQuestionIndex` is updating in logs
- Verify: `testStarted = true` before audio starts

**Issue**: Audio sounds choppy/interrupted
- **This should NOT happen** - verify no `player.seek()` calls
- Check: Network connection for audio streaming
- Verify: Audio file format is compatible with `just_audio`

## Testing Checklist

- [ ] Audio plays from start to end
- [ ] Questions auto-switch at correct times
- [ ] No manual navigation (buttons disabled)
- [ ] Timer-related display shows correct times
- [ ] User can reply to all questions during playback
- [ ] Last question auto-submits when audio completes
- [ ] Cancel button still works (stops test)
- [ ] Orientation locked to portrait
- [ ] Audio position display updates in real-time

---

**Last Updated**: 2026-05-13  
**Version**: 1.0 - Listening Test with Unified Audio
