# Implementation Details - Listening Test Architecture

## Core Concept

The new listening test system replaces **per-question audio files** with a **single unified audio file**. Instead of playing individual audio clips, the system monitors the audio playback position and automatically updates the UI when the audio reaches the end time of each question.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  TestDetailView (UI)                    │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Listens to: currentQuestionIndex (observable)    │ │
│  │  Displays: currentQuestion based on index         │ │
│  │  Shows: currentAudioPosition in footer            │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                        ↑
                    Obx rebuild
                        ↓
┌─────────────────────────────────────────────────────────┐
│              TestController (Logic)                      │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  audioPath = "https://cdn.../unified-audio.mp3" │  │
│  │  questions = [Q1, Q2, Q3, ...]                  │  │
│  │  currentQuestionIndex = 0                       │  │
│  │  currentAudioPosition = 12.5                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  _setupAudioPositionListener():                         │
│    player.positionStream.listen((duration) {            │
│      currentAudioPosition.value = duration_in_seconds   │
│      if (currentAudioPosition >= currentQ.endSecond) {  │
│        currentQuestionIndex++                           │
│      }                                                  │
│    })                                                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
         ↓              ↓              ↓
    player.play()  Receive position  currentQuestionIndex++
                                          triggers Obx
         ↓              ↓              ↓
┌─────────────────────────────────────────────────────────┐
│          AudioPlayer (just_audio plugin)                │
│                                                          │
│  Unified Audio File (MP3/WAV)                           │
│  ─────────────────────────────────────────────────────  │
│  Q1 Audio      │ Silence │ Q2 Audio      │ Silence │... │
│  0:00 - 15:50  │ 15:50 - │ 20:00 - 38:30 │ 38:30 - │    │
│                │ 20:00   │               │ 40:00   │    │
│  ════════════════════════════════════════════════════   │
│  Position: 0:00 → 1:00 → 5:30 → 10:00 → 15:50 → 20:30  │
│                                  ↑                      │
│                          Reached Q1.endSecond           │
│                          Trigger switch to Q2           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Data Flow During Playback

### 1. Test Initialization
```dart
// User taps test
TestDetailView(testId: 123)
  // TestController.onInit() -> _startTimer()
  // TestController.fetchQuestions(123)
  
// API Response:
{
  "audioPath": "https://cdn.../test-123-audio.mp3",
  "questions": [
    {"question": "...", "startSecond": 0, "endSecond": 15.5},
    {"question": "...", "startSecond": 20, "endSecond": 38.3},
    ...
  ]
}

// Controller extracts and stores:
audioPath.value = "https://cdn.../test-123-audio.mp3"
isListeningTest.value = true (detected from partId)
```

### 2. User Starts Listening Test
```dart
// User sees listening intro screen
// Clicks "BẮT ĐẦU" button

onPressed: () {
  controller.testStarted.value = true;
}

// Controller listener responds:
ever(testStarted, (started) {
  if (started && isListeningTest.value) {
    _startListeningMode();
  }
});
```

### 3. _startListeningMode() Execution Sequence
```dart
Future<void> _startListeningMode() async {
  // 1. Load unified audio
  await player.setUrl(audioPath.value);
  // At this point: Audio is loaded but not playing
  
  // 2. Set up position listener
  _setupAudioPositionListener();
  // Listener is now activated and ready to receive position updates
  
  // 3. Start playback
  await player.play();
  // Audio starts playing from 0:00
  isAudioPlaying.value = true;
}
```

### 4. _setupAudioPositionListener() Overview
```dart
void _setupAudioPositionListener() {
  // Subscribe to audio position stream
  _audioPositionSubscription = player.positionStream.listen((position) {
    final currentSeconds = position.inMilliseconds / 1000.0;
    currentAudioPosition.value = currentSeconds;
    // ↑ UI updates footer "Âm thanh: 5.2s / 15.5s"
    
    final currentQ = currentQuestion;
    final endSecond = currentQ['endSecond'] as double?;
    
    // Check if we've reached the end of current question
    if (currentSeconds >= endSecond) {
      _autoSwitchToNextQuestion();
      // ↑ This increments currentQuestionIndex
      // ↑ Obx triggers rebuild
      // ↑ UI shows next question
    }
  });
}
```

### 5. Auto-Switch Mechanism
```
Time: 0:00 ─────────── 5:00 ─────────── 10:00 ─────────── 15:50
Q1 Playing...                                               ↑
Audio Position Updates: [0.5, 1.0, 2.5, 5.0, 8.3, 10.2, 15.0, 15.5, 16.0]
                                                            ↑
                                              TRIGGER: 15.5 >= 15.5
                                              Action: currentQuestionIndex++
                                              Result: UI shows Q2

Q2 starts displaying:  
Question: "Where are the people?"
Audio Position: 15.5s / 38.3s (Q1.endSecond is now ignored)

Time: 15:50 ─────── 20:00 ─────────── 30:00 ─────────── 38:30
Q2 Playing (audio continues naturally - NO SEEK)
Audio Position Updates: [16.0, 18.5, 20.0, 25.0, 35.0, 38.3, 38.5]
                                                      ↑
                                        TRIGGER: 38.3 >= 38.3
                                        Action: currentQuestionIndex++
                                        Result: UI shows Q3
```

## Key Design Decisions

### 1. No Seeking
```dart
// ❌ NOT used (would break seamlessness)
await player.seek(Duration(seconds: 20));

// ✅ Let audio continue naturally
// UI just updates based on position stream
```

**Why?** A real listening test plays continuously. Seeking would:
- Reset the natural flow
- Cause audio artifacts/clicks
- Make experience unrealistic
- Waste API calls

### 2. Timeline-Based Switching (Not Audio Events)
```dart
// ❌ Old approach (triggered per audio)
player.playerStateStream.listen((playerState) {
  if (playerState.processingState == ProcessingState.completed) {
    nextQuestion();
  }
});

// ✅ New approach (based on time windows)
player.positionStream.listen((position) {
  if (position >= Duration(seconds: endSecond)) {
    currentQuestionIndex++;
  }
});
```

**Why?** 
- Handles silence/gaps between questions
- No dependency on audio stream completion
- Precise control via JSON data
- Works with concatenated audio

### 3. UI Updates via Observable
```dart
// ❌ Manual UI updates
void _autoSwitchToNextQuestion() {
  currentQuestionIndex++;
  setState(() {}); // ← Manual rebuild
}

// ✅ Reactive updates
void _autoSwitchToNextQuestion() {
  currentQuestionIndex++;
  // ↑ currentQuestionIndex is .obs (observable)
  // ↑ Obx widgets rebuild automatically
}
```

**Why?**
- No manual state management
- Reactive and efficient
- Less error-prone
- Integrates with GetX pattern

### 4. Navigation Disabled During Test
```dart
Future<void> nextQuestion() async {
  // During listening test:
  if (isListeningTest.value && isTestActive.value) {
    return; // ← Silently ignore manual nav
  }
  // Otherwise (reading test): allow manual nav
}
```

**Why?**
- Prevents user manipulating audio timeline
- Enforces realistic test conditions
- Consistent with TOEIC format

## Property Lifecycle

### Current Audio Position
```
┌─────────────────────────────────────┐
│ var currentAudioPosition = 0.0.obs; │
└─────────────────────────────────────┘
         ↑                   ↓
    Initialized         Updated every
    to 0.0              ~100-200ms
                        from positionStream
                             ↓
                        Used in UI footer
                        "Âm thanh: X.Xs / Y.Ys"
                             ↓
                        Compared with endSecond
                        to trigger switch
```

### Audio Path
```
┌────────────────────────────────┐
│ var audioPath = ''.obs;        │
└────────────────────────────────┘
         ↓
    Set in fetchQuestions()
    from API response
         ↓
    Used in _startListeningMode()
    to load audio file
         ↓
    Cleared in cancelTest()
```

### Question Index
```
┌─────────────────────────────────┐
│ var currentQuestionIndex = 0    │
└─────────────────────────────────┘
         ↑                    ↓
    Starts at 0          Incremented by
                         _autoSwitchToNextQuestion()
                              ↓
                         currentQuestion getter
                         retrieves Q data
                              ↓
                         UI displays via Obx
```

## Error Handling

### Audio Loading Issues
```dart
try {
  await player.setUrl(audioPath.value);
} catch (e) {
  Get.snackbar('Lỗi', 'Không thể phát âm thanh: $e');
  isAudioPlaying.value = false;
}
```

### Empty Audio Path
```dart
if (audioPath.value.isEmpty) {
  Get.snackbar('Lỗi', 'Không tìm thấy file âm thanh');
  return;
}
```

### Null Question Data
```dart
if (currentQ.isEmpty) {
  return; // Skip processing
}

final endSecond = currentQ['endSecond'] as double?;
if (endSecond == null) {
  return; // Skip if undefined
}
```

## Testing Strategy

### Scenario 1: Normal Flow
```
1. Load test with audio
2. Verify audioPath extracted
3. Tap START
4. Verify audio plays
5. Monitor console for position updates
6. Verify UI updates at correct times
7. Verify no seeking occurs
```

### Scenario 2: Edge Cases
```
1. Audio with silence gaps
   → Verify questions don't switch during silence
2. Rapidly changing questions
   → Verify UI keeps up with audio
3. Long audio file
   → Verify position tracking remains stable
4. Network lag
   → Eventually catch up when audio loads
```

### Scenario 3: User Interaction
```
1. User taps question menu
   → Should show current question highlighted
2. User tries to navigate (prev/next)
   → Should be disabled with error message
3. User tries to go back (back button)
   → Shows confirmation dialog
4. User connects headphones (during test)
   → Audio continues smoothly (handled by just_audio)
```

## Performance Considerations

### Position Stream Updates
- **Frequency**: ~50-100ms updates
- **Resolution**: Millisecond precision
- **Load**: Minimal (1 event per update interval)

### UI Rebuilds
- **Triggered by**: Any observable change
- **Example triggers**: currentAudioPosition update, currentQuestionIndex change
- **Optimization**: Obx widgets only rebuild watched observables

### Memory
- **Single audio player**: ~10-15MB overhead
- **Position stream**: Negligible
- **Questions list**: Linear growth with count

## Known Limitations

1. **Platform Specific**: Just_audio has platform-specific behaviors
   - iOS: May pause on call interruption (user resumes manually)
   - Android: Respects audio focus

2. **Network**: Audio must stream or be downloaded
   - CDN latency affects perceived smoothness
   - Plan for variable network conditions

3. **Precision**: Timing is dependent on system clock
   - Variance: ±50-100ms typical
   - Not suitable for sub-second accuracy

## Migration from Old System

### What Was Removed
- `_getAudioUrlFromQuestion()` - No longer need per-question audio
- `_autoPlayAudio()` - Replaced with _setupAudioPositionListener()
- Per-question audio playback logic

### What Was Added
- Unified audio loading
- Position-based question switching
- Real-time position display
- Audio path storage

### Backward Compatibility
- **Old data format**: Won't work (no audioPath)
- **New data format**: Only new implementation
- **Migration path**: Update backend API response

---

## Debugging Tips

### Enable verbose logging
```bash
flutter run --verbose
```

### Check audio file
```bash
# Verify file exists and is valid
ffprobe unified-audio.mp3
```

### Mock test data
Use `sample-listening-test-response.json` for local testing

### Simulate slow network
```dart
// Add delay in DioClient to simulate slowness
await Future.delayed(Duration(seconds: 2));
return response;
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-05-13
