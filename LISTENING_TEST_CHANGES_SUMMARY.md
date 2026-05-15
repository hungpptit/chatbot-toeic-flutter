# Listening Test Update - Summary of Changes

## What Changed?

Your listening test implementation has been completely redesigned to support **continuous audio playback with automatic question switching based on audio timing**.

## Code Files Modified

### 1. **TestController** (`lib/features/test/test_controller.dart`)

#### New Properties
```dart
var audioPath = ''.obs;                    // Stores unified audio file URL
var currentAudioPosition = 0.0.obs;        // Real-time audio playback position in seconds
late StreamSubscription<Duration> _audioPositionSubscription;
```

#### New Methods
- **`_startListeningMode()`** - Loads unified audio and starts playback
- **`_setupAudioPositionListener()`** - Monitors audio playback position and auto-switches questions
- **`_autoSwitchToNextQuestion()`** - Updates current question index without seeking audio

#### Modified Methods
- **`nextQuestion()`, `previousQuestion()`, `goToQuestion()`** - Now disabled during listening test
- **`fetchQuestions()`** - Now extracts and stores `audioPath` from API response
- **`onInit()`** - Sets up listener for `testStarted` observable

#### Removed Logic
- ❌ Per-question audio playback (`playAudio()` with mediaMappings)
- ❌ Auto-advance on audio completion (now timeline-based)
- ❌ Manual navigation support in listening mode

### 2. **TestDetailView** (`lib/features/test/test_detail_view.dart`)

#### Updated UI Footer
- **Before**: Shows only question number
- **After**: Shows audio position alongside question number
  ```
  Câu 1/20
  Âm thanh: 12.5s / 15.5s
  ```

#### Navigation Changes
- Previous/Next buttons: Hidden during listening tests
- Question menu: Still available (read-only)
- All navigation is controlled by audio timeline

## How It Works

### 1. Test Flow
```
User clicks START
   ↓
testStarted = true
   ↓
_startListeningMode() loads unified audio
   ↓
Audio plays continuously from 0:00
   ↓
Position listener monitors playback time
   ↓
When audio reaches endSecond of current question
   ↓
currentQuestionIndex auto-increments
   ↓
UI rebuilds (Obx) showing next question
   ↓
Repeat until audio ends
```

### 2. Key Principle: No Seeking
- The audio file plays **continuously** without pause
- When a question ends, the UI updates but audio **keeps playing**
- This ensures seamless audio like a real test

### 3. Data Structure
Each test API response now needs:

```json
{
  "audioPath": "https://cdn.example.com/test-1-audio.mp3",
  "questions": [
    {
      "question": "What is the man doing?",
      "startSecond": 0.0,
      "endSecond": 15.5,
      // ... other fields
    }
  ]
}
```

## What You Need to Do (Backend)

✅ **Required Changes to Your API**

Your `/v1/tests/{testId}/questions` endpoint must return a response that includes:

1. **`audioPath`** field - URL to the unified audio file
   ```json
   "audioPath": "https://your-cdn.com/path/to/audio.mp3"
   ```

2. **`startSecond` and `endSecond`** fields for each question
   ```json
   "questions": [
     {
       "startSecond": 0.0,
       "endSecond": 15.5,
       // ...
     }
   ]
   ```

3. Ensure **audio timing is accurate** - if you say a question ends at 15.5s, the audio content must actually match

### Example Response Format

```json
{
  "data": {
    "title": "TOEIC Listening Part 1",
    "partId": 1,
    "audioPath": "https://cdn.example.com/audio/test-1-unified.mp3",
    "questions": [
      {
        "id": 1,
        "question": "What is the man doing?",
        "imagePath": "https://example.com/image1.jpg",
        "startSecond": 0.0,
        "endSecond": 15.5,
        "optionA": "He is walking",
        "optionB": "He is sitting",
        "optionC": "He is reading",
        "optionD": "He is talking",
        "correctAnswer": "A",
        "partId": 1
      },
      {
        "id": 2,
        "question": "Where are the people?",
        "imagePath": "https://example.com/image2.jpg",
        "startSecond": 20.0,
        "endSecond": 38.3,
        // ...
      }
    ]
  }
}
```

## Example Audio Timing Structure

For a test with 3 questions:

```
Time →
0:00────────────15:50  (Q1: 0-15.5s)
        15:50──────20:00  [Silence]
        20:00────────────38:30  (Q2: 20-38.3s)
                       38:30───40:00  [Silence]
                       40:00──────────57:20  (Q3: 40-57.2s)
```

## Real-Time Display

During listening test, the footer shows:
- **Current Question**: "Câu 1/20"
- **Audio Position**: "Âm thanh: 5.2s / 15.5s"
  - Left number: current playback position
  - Right number: end time of current question

## Testing the Implementation

1. Update your backend API to return `audioPath`
2. Prepare a unified audio file with all questions
3. Set accurate `startSecond` and `endSecond` times
4. Run the app and tap a listening test
5. Check console logs for debug output
6. Verify:
   - Audio plays continuously
   - Questions auto-switch at correct times
   - No manual navigation works
   - Last question auto-submits

## Console Debug Output

The implementation includes extensive logging. Watch for:
```
🎬 Listening test started
✅ Audio loaded
✅ Playback started
⏱️  Position X >= endSecond Y
➡️  Auto-switching to next question
```

## Migration Checklist

- [ ] Backend returns `audioPath` in API response
- [ ] Backend includes `startSecond` and `endSecond` for each question
- [ ] Audio file is prepared with correct timing
- [ ] Audio file is hosted and accessible via URL
- [ ] CORS headers are configured on audio CDN
- [ ] Test data includes `partId: 1-4` for listening tests
- [ ] Run app and verify listening test flow
- [ ] Adjust audio timings if needed
- [ ] Check console logs for any errors

## Need Help Adapting Your Backend?

Refer to [LISTENING_TEST_IMPLEMENTATION.md](./LISTENING_TEST_IMPLEMENTATION.md) for:
- Complete API specification
- Detailed flow diagrams
- Data structure examples
- Debugging guide
- Common issues and solutions

---

**Summary**: The app now plays a single unified audio file and automatically advances questions based on the audio timeline, without allowing manual navigation. This creates a realistic testing experience.
