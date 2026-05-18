import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class TestController extends GetxController {
  // === Audio Player ===
  final player = AudioPlayer();

  // === Questions Management ===
  var questions = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var currentQuestionIndex = 0.obs;
  
  // === User Answers ===
  var userAnswers = <int, int>{}.obs; // Key: question index, Value: answer index

  // === Timer Management ===
  var timeRemaining = 2700.obs; // 45 minutes in seconds (45 * 60)
  var isTestActive = true.obs;
  late Timer _timer;
  
  // === Audio State ===
  var isAudioPlaying = false.obs;
  late StreamSubscription<Duration> _audioPositionSubscription;
  var currentAudioPosition = 0.0.obs; // Current playback time in seconds

  // === Listening Test Mode ===
  var isListeningTest = false.obs;
  var hasListeningQuestions = false.obs;
  var hasReadingQuestions = false.obs;
  var testStarted = false.obs; // Track if user clicked START button
  var audioPath = ''.obs; // Full audio file path for listening test
  var isPracticeMode = false.obs; // true when preloaded practice questions (no server testId)

  // === Test Metadata ===
  var testId = 0.obs;
  var testTitle = ''.obs;
  var totalQuestions = 0.obs;
  var attemptId = ''.obs; // ID of current test attempt
  var isCancelling = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    _startTimer();
    
    // Initialize empty position subscription (will be replaced in _setupAudioPositionListener)
    _audioPositionSubscription = player.positionStream.listen((_) {});
    
    // For listening tests: trigger auto-play when testStarted becomes true
    ever(testStarted, (started) {
      if (started && isListeningTest.value) {
        print('🎬 Listening test started - loading unified audio');
        _startListeningMode();
      }
    });

    ever(currentQuestionIndex, (_) {
      _syncListeningModeForCurrentQuestion();
    });

    // Auto-initialize test attempt when questions are loaded (for reading tests only)
    // Listening tests will initialize when user clicks START button
    ever(questions, (list) {
      if (!isTestActive.value || isCancelling.value) {
        return;
      }

      if (list.isNotEmpty && attemptId.value.isEmpty && testId.value > 0) {
        // Only auto-init for non-listening tests
        // Listening test detection happens after questions load
        Future.delayed(Duration.zero, () {
          if (!isListeningTest.value && !isCancelling.value && isTestActive.value) {
            print('📌 Reading test detected, auto-initializing attempt');
            startTestAttempt(testId.value);
          }
        });
      }
    });
  }

  @override
  void onClose() {
    _stopTimer();
    _stopAudio();
    _audioPositionSubscription.cancel();
    player.dispose();
    
    // Reset orientation when test closes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    super.onClose();
  }

  /// Set the attempt ID (should be called when test starts, after creating attempt in backend)
  /// Example: After user clicks START button, call backend to create attempt, then set this
  void setAttemptId(String id) {
    attemptId.value = id;
  }

  /// ========== TEST ATTEMPT MANAGEMENT ==========

  /// Create a new test attempt and get attemptId
  Future<void> startTestAttempt(int id) async {
    try {
      testId.value = id;
      print('🎬 Starting test attempt for testId=$id');
      
      final response = await DioClient.dio.post('/v1/tests/$id/attempts');
      
      print('📥 Create attempt response:');
      print('  Status: ${response.statusCode}');
      print('  Data: ${jsonEncode(response.data)}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('  data keys: ${data.keys}');
        print('  data[data]: ${data['data']}');
        print('  data[data][userTestId]: ${data['data']?['userTestId']}');
        
        // Backend returns userTestId, not id
        final newAttemptId = data['data']?['userTestId']?.toString() ?? data['userTestId']?.toString();
        
        print('  Extracted attemptId: $newAttemptId (type: ${newAttemptId.runtimeType})');
        
        if (newAttemptId != null && newAttemptId.isNotEmpty && newAttemptId != 'null') {
          setAttemptId(newAttemptId);
          print('✅ Test attempt created: attemptId=$newAttemptId');
        } else {
          throw Exception('No userTestId in response (extracted: $newAttemptId)');
        }
      } else {
        throw Exception('Failed to create attempt: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error starting test attempt: $e');
      print('Không thể bắt đầu bài thi: $e');
      isTestActive.value = false;
    }
  }

  /// ========== TIMER METHODS ==========

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        _stopTimer();
        isTestActive.value = false;
        print('⏰ Thời gian làm bài đã hết. Bài thi sẽ được nộp tự động.');
        Future.delayed(const Duration(seconds: 1), () {
          if (Get.context != null) {
            submitTest(Get.context!);
          }
        });
      }
    });
  }

  void _stopTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  /// Định dạng thời gian thành chuỗi mm:ss
  String get timeString {
    final minutes = timeRemaining.value ~/ 60;
    final seconds = timeRemaining.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// ========== FETCHING QUESTIONS ==========

  Future<void> fetchQuestions(int id) async {
    testId.value = id;
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/tests/$id/questions');
      
      if (response.statusCode == 200) {
        // Backend returns array directly or wrapped in 'data' object
        final rawData = response.data['data'] ?? response.data;
        
        // If wrapped in an object with 'questions' key, extract it
        List<dynamic> data;
        String? retrievedAudioPath;
        
        if (rawData is Map<String, dynamic> && rawData.containsKey('questions')) {
          data = rawData['questions'] as List<dynamic>;
          retrievedAudioPath = rawData['audioPath'] as String?;
        } else if (rawData is List<dynamic>) {
          data = rawData;
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Use questions directly without transformation
        questions.assignAll(
          data.cast<Map<String, dynamic>>(),
        );
        
        totalQuestions.value = questions.length;
        
        // Initialize userAnswers map
        userAnswers.clear();
        
        // Detect listening/reading composition for pure listening vs mixed tests.
        if (questions.isNotEmpty) {
          hasListeningQuestions.value = questions.any(_isListeningQuestion);
          hasReadingQuestions.value = questions.any((q) => !_isListeningQuestion(q));
          isListeningTest.value = hasListeningQuestions.value && !hasReadingQuestions.value;
          
          if (hasListeningQuestions.value) {
            // Primary: unified audio path from response.
            if (retrievedAudioPath != null && retrievedAudioPath.isNotEmpty) {
              audioPath.value = retrievedAudioPath;
            } else {
              // Fallback: extract first available audio URL from listening questions.
              for (final q in questions) {
                final extracted = _extractAudioUrlFromQuestion(q);
                if (extracted.isNotEmpty) {
                  audioPath.value = extracted;
                  break;
                }
              }
            }
          }
          
          // Lock orientation only for pure listening test intro flow.
          if (isListeningTest.value) {
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }

          _syncListeningModeForCurrentQuestion();
        }
        
        print('✅ Tải ${questions.length} câu hỏi thành công');
      }
    } catch (e) {
      print('❌ Error fetching questions: $e');
      print('Không thể tải câu hỏi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ========== QUESTION NAVIGATION ==========
  /// NOTE: In listening test mode (isTestActive=true), these are effectively disabled

  /// Lấy câu hỏi hiện tại
  Map<String, dynamic> get currentQuestion {
    if (currentQuestionIndex.value >= 0 && 
        currentQuestionIndex.value < questions.length) {
      return questions[currentQuestionIndex.value];
    }
    return {};
  }

  /// Kiểm tra xem có câu hỏi tiếp theo không
  bool get hasNextQuestion {
    return currentQuestionIndex.value < questions.length - 1;
  }

  /// Kiểm tra xem có câu hỏi trước không
  bool get hasPreviousQuestion {
    return currentQuestionIndex.value > 0;
  }

  /// Chuyển đến câu hỏi tiếp theo
  /// DISABLED in listening test mode - only called via auto-switch logic
  Future<void> nextQuestion() async {
    if (isManualNavigationLocked) {
      print('⛔ Cannot manually navigate in listening test mode');
      return;
    }
    if (hasNextQuestion) {
      await _stopAudio();
      currentQuestionIndex.value++;
    }
  }

  /// Chuyển đến câu hỏi trước
  /// DISABLED in listening test mode
  Future<void> previousQuestion() async {
    if (isManualNavigationLocked) {
      print('⛔ Cannot manually navigate in listening test mode');
      return;
    }
    if (hasPreviousQuestion) {
      await _stopAudio();
      currentQuestionIndex.value--;
    }
  }

  /// Nhảy đến câu hỏi cụ thể
  /// DISABLED in listening test mode
  Future<void> goToQuestion(int index) async {
    if (isManualNavigationLocked) {
      print('⛔ Cannot manually navigate in listening test mode');
      return;
    }
    if (index >= 0 && index < questions.length) {
      await _stopAudio();
      currentQuestionIndex.value = index;
    } else {
      print('Lỗi: Chỉ số câu hỏi không hợp lệ');
    }
  }

  /// ========== ANSWER SELECTION ==========

  /// Chọn đáp án và tự động chuyển sang câu tiếp theo sau 500ms
  void selectAnswer(int answerIndex) {
    if (currentQuestionIndex.value >= 0 && 
        currentQuestionIndex.value < questions.length) {
      // Lưu đáp án (map từ index câu hỏi -> index đáp án A/B/C/D)
      userAnswers[currentQuestionIndex.value] = answerIndex;
      
      print('💾 Đã lưu đáp án cho câu ${currentQuestionIndex.value + 1}');
         }
  }

  /// Lấy đáp án đã chọn cho câu hỏi hiện tại (-1 nếu chưa chọn)
  int get selectedAnswerForCurrentQuestion {
    return userAnswers[currentQuestionIndex.value] ?? -1;
  }

  /// Kiểm tra xem câu hỏi này đã được trả lời chưa
  bool isQuestionAnswered(int index) {
    return userAnswers.containsKey(index);
  }

  /// ========== AUDIO METHODS FOR LISTENING TEST ==========

  int _safeExtractInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is Map) {
      if (v.containsKey('id')) return _safeExtractInt(v['id']);
      if (v.isNotEmpty) return _safeExtractInt(v.values.first);
    }
    return 0;
  }

  double? _safeExtractDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _isListeningPartId(int partId) {
    return partId >= 1 && partId <= 4;
  }

  bool _isListeningQuestion(Map<String, dynamic> question) {
    final dynamic part = question['part'];
    final int partId = _safeExtractInt(part ?? question['partId']);
    if (_isListeningPartId(partId)) {
      return true;
    }

    final hasTiming = _extractStartSecond(question) != null || _extractEndSecond(question) != null;
    final hasAudio = _extractAudioUrlFromQuestion(question).isNotEmpty;
    return hasTiming || hasAudio;
  }

  String _extractAudioUrlFromQuestion(Map<String, dynamic> question) {
    if (question['mediaMappings'] is! List) {
      return '';
    }

    final mappings = question['mediaMappings'] as List;
    for (final mapping in mappings) {
      if (mapping is! Map<String, dynamic> || mapping['media'] == null) {
        continue;
      }

      final media = mapping['media'];
      final String type = (media['type'] ?? media['mediaType'] ?? '').toString().toLowerCase();
      final String url = (media['url'] ?? media['mediaUrl'] ?? '').toString();
      if (type == 'audio' && url.isNotEmpty) {
        return url;
      }
    }

    return '';
  }

  double? _extractStartSecond(Map<String, dynamic> question) {
    if (question['mediaMappings'] is List) {
      for (final mapping in (question['mediaMappings'] as List)) {
        if (mapping is Map<String, dynamic>) {
          final parsed = _safeExtractDouble(mapping['startSecond']);
          if (parsed != null) return parsed;
        }
      }
    }
    return _safeExtractDouble(question['startSecond']);
  }

  double? _extractEndSecond(Map<String, dynamic> question) {
    if (question['mediaMappings'] is List) {
      for (final mapping in (question['mediaMappings'] as List)) {
        if (mapping is Map<String, dynamic>) {
          final parsed = _safeExtractDouble(mapping['endSecond']);
          if (parsed != null) return parsed;
        }
      }
    }
    return _safeExtractDouble(question['endSecond']);
  }

  bool get isCurrentQuestionListening {
    final current = currentQuestion;
    if (current.isEmpty) {
      return false;
    }
    return _isListeningQuestion(current);
  }

  bool get isManualNavigationLocked {
    if (!isTestActive.value) {
      return false;
    }

    if (isListeningTest.value) {
      return true;
    }

    return isCurrentQuestionListening && isAudioPlaying.value;
  }

  bool get shouldUseListeningNavigationUi {
    if (isListeningTest.value) {
      return true;
    }
    return isCurrentQuestionListening && isAudioPlaying.value;
  }

  Future<void> _syncListeningModeForCurrentQuestion() async {
    if (!isTestActive.value || questions.isEmpty || !hasListeningQuestions.value) {
      return;
    }

    // Pure listening mode waits for START from intro.
    if (isListeningTest.value && !testStarted.value) {
      return;
    }

    if (isCurrentQuestionListening) {
      if (audioPath.value.isEmpty) {
        final extracted = _extractAudioUrlFromQuestion(currentQuestion);
        if (extracted.isNotEmpty) {
          audioPath.value = extracted;
        }
      }

      if (!isAudioPlaying.value && audioPath.value.isNotEmpty) {
        await _startListeningMode(seekToCurrentQuestionStart: !isListeningTest.value);
      }
      return;
    }

    if (isAudioPlaying.value) {
      await _stopAudio();
    }
  }

  /// Fallback: Extract audio URL from question's mediaMappings (OLD FORMAT)
  /// This bridges support for existing data format until backend is updated
  void _extractAudioFromMappings(Map<String, dynamic> question) {
    final extracted = _extractAudioUrlFromQuestion(question);
    if (extracted.isNotEmpty) {
      audioPath.value = extracted;
    }
  }

  /// ========== AUDIO METHODS FOR LISTENING TEST ==========

  /// Start listening mode: Load unified audio and set up auto-switch logic
  Future<void> _startListeningMode({bool seekToCurrentQuestionStart = false}) async {
    if (audioPath.value.isEmpty) {
      print('Lỗi: Không tìm thấy đường dẫn âm thanh. Vui lòng kiểm tra cấu hình backend.');
      isTestActive.value = false;
      return;
    }

    try {
      // Load the unified audio file
      await player.setUrl(audioPath.value);
      
      // Set up position listener BEFORE playing
      _setupAudioPositionListener();

      if (seekToCurrentQuestionStart) {
        final start = _extractStartSecond(currentQuestion);
        if (start != null && start >= 0) {
          await player.seek(Duration(milliseconds: (start * 1000).round()));
        }
      }
      
      // Start playback
      await player.play();
      isAudioPlaying.value = true;
      print('🎬 Bài thi listening đã bắt đầu');
    } on Exception catch (e) {
      print('Lỗi Âm thanh: Không thể phát: $e');
      isAudioPlaying.value = false;
      isTestActive.value = false;
    }
  }

  /// Set up continuous listener on audio position
  /// When currentTime >= endSecond of current question, auto-switch to next
  void _setupAudioPositionListener() {
    _audioPositionSubscription = player.positionStream.listen((position) {
      final currentSeconds = position.inMilliseconds / 1000.0;
      currentAudioPosition.value = currentSeconds;
      
      if (!isTestActive.value || questions.isEmpty) {
        return;
      }

      final currentQ = currentQuestion;
      if (currentQ.isEmpty) {
        return;
      }

      if (!_isListeningQuestion(currentQ)) {
        return;
      }

      // Extract timing from current question
      final double? endSecond = _extractEndSecond(currentQ);
      
      // PRIMARY: Check if reached endSecond of current question
      if (endSecond != null && currentSeconds >= endSecond) {
        if (hasNextQuestion) {
          final nextQ = questions[currentQuestionIndex.value + 1] as Map<String, dynamic>;
          _autoSwitchToNextQuestion();
          if (!_isListeningQuestion(nextQ)) {
            _stopAudio();
          }
        }
        return;
      }
      
      // FALLBACK: If no endSecond, check startSecond of next question
      if (endSecond == null && hasNextQuestion) {
        final nextQ = questions[currentQuestionIndex.value + 1] as Map<String, dynamic>;
        final double? nextStartSecond = _extractStartSecond(nextQ);
        
        if (nextStartSecond != null && currentSeconds >= nextStartSecond) {
          _autoSwitchToNextQuestion();
          if (!_isListeningQuestion(nextQ)) {
            _stopAudio();
          }
          return;
        }
      }
    });
  }

  /// Auto-switch to next question WITHOUT seeking audio
  void _autoSwitchToNextQuestion() {
    if (hasNextQuestion) {
      currentQuestionIndex.value++;
    }
  }

  /// Play audio (used only for non-listening mode)
  Future<void> playAudio(String url) async {
    print('🎵 playAudio called with URL: ${url.substring(0, 50)}...');
    
    if (url.isEmpty) {
      print('   - ⚠️ URL is empty, skipping playback');
      return;
    }
    
    // Skip if in listening test mode
    if (isListeningTest.value) {
      print('   - ⚠️ In listening test mode, ignoring individual audio play');
      return;
    }

    try {
      isAudioPlaying.value = true;
      print('   - ✅ Setting audio URL...');
      await player.setUrl(url);
      print('   - ✅ Playing...');
      await player.play();
      print('   - ✅ Audio playback started');
    } catch (e) {
      print('   - ❌ Error: $e');
      isAudioPlaying.value = false;
      print('Lỗi Audio: Không thể phát âm thanh: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await player.pause();
      isAudioPlaying.value = false;
    } catch (e) {
      print('Lỗi: Không thể tạm dừng âm thanh: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await player.stop();
      isAudioPlaying.value = false;
    } catch (e) {
      print('Lỗi: Không thể dừng âm thanh: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      if (player.playing) {
        await player.stop();
      }
      isAudioPlaying.value = false;
    } catch (e) {
      // Silent catch
    }
  }

  /// ========== TEST SUBMISSION ==========

  /// Nộp bài thi - with confirmation dialog and API submission
  Future<void> submitTest(BuildContext context) async {
    // If practice mode, allow submission without attemptId
    if (!isPracticeMode.value) {
      // Validate attemptId first
      if (attemptId.value.isEmpty) {
        print('❌ Cannot submit: attemptId is empty!');
        print('Bài thi chưa được khởi tạo. Vui lòng nhấn BẮT ĐẦU trước.');
        return;
      }
    }
    
    _stopTimer();
    isTestActive.value = false;
    
    // Calculate unanswered questions
    final unansweredCount = totalQuestions.value - userAnswers.length;
    
    // Show confirmation dialog (with warning if there are unanswered questions)
    final confirmed = await _showSubmitConfirmationDialog(context, unansweredCount);
    if (!confirmed) {
      // Resume test if cancelled
      isTestActive.value = true;
      _startTimer();
      return;
    }
    
    // Send answers to appropriate API
    if (isPracticeMode.value) {
      await _submitPracticeAnswersToAPI(unansweredCount);
    } else {
      await _submitAnswersToAPI(unansweredCount);
    }
  }

  /// Submit answers for practice mode (no testId/attemptId on server)
  Future<void> _submitPracticeAnswersToAPI(int unansweredCount) async {
    try {
      // Build answers array [{questionId, selectedAnswer}, ...]
      final answersArray = <Map<String, dynamic>>[];
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final questionId = question['id'];
        final answerIndex = userAnswers[i];
        final answerLetter = answerIndex != null ? ['A', 'B', 'C', 'D'][answerIndex] : null;

        // Send every question so the backend can score unanswered items as skipped/wrong.
        answersArray.add({
          'questionId': questionId,
          'selectedAnswer': answerLetter,
        });
      }

      final requestData = {
        'answers': answersArray,
        'timeSpent': 2700 - timeRemaining.value,
      };

      final url = '/v1/tests/practice-attempts/submit';
      print('📤 Submitting practice answers to $url with ${answersArray.length} answers');
      final response = await DioClient.dio.post(url, data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data;
        print('✅ Practice submitted');

        final dynamic dataWrapper = result is Map ? result['data'] : null;
        final practiceAttemptId = dataWrapper is Map
            ? (dataWrapper['userTestId'] ?? dataWrapper['attemptId'] ?? dataWrapper['id'])
            : null;

        // Navigate to result screen with result data
        await Future.delayed(const Duration(seconds: 1));
        Get.offNamed(
          '/test-result',
          arguments: {
            'testId': 0,
            'attemptId': practiceAttemptId?.toString() ?? '',
            'result': result,
          },
        );
      } else {
        print('Không thể nộp bài luyện tập (${response.statusCode})');
      }
    } catch (e) {
      print('Không thể nộp bài luyện tập: ${e.toString()}');
    }
  }

  /// Show confirmation dialog before submitting (with warning if unanswered questions)
  Future<bool> _showSubmitConfirmationDialog(BuildContext context, int unansweredCount) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Xác nhận nộp bài',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            unansweredCount > 0
                ? 'Bạn còn $unansweredCount câu chưa làm. Bạn có chắc chắn muốn nộp?'
                : 'Bạn có chắc chắn muốn nộp bài thi?',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Quay lại',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Nộp bài',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Submit answers to API and handle result
  Future<void> _submitAnswersToAPI(int unansweredCount) async {
    try {
      // Prepare answer data
      // Convert answers map: {questionIndex: answerIndex} to {questionId: answerValue}
      final answersData = <String, dynamic>{};
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final questionId = question['id'];
        final answerIndex = userAnswers[i];
        
        if (answerIndex != null) {
          // Convert index to answer letter (0->A, 1->B, 2->C, 3->D)
          final answerLetter = ['A', 'B', 'C', 'D'][answerIndex];
          answersData[questionId.toString()] = answerLetter;
        }
      }

      final url = '/v1/tests/${testId.value}/attempts/${attemptId.value}/submit';
      final requestData = {
        'answers': answersData,
        'timeSpent': 2700 - timeRemaining.value,
      };
      
      print('📤 === SUBMIT REQUEST ===');
      print('  URL: $url');
      print('  testId: ${testId.value}');
      print('  attemptId: ${attemptId.value}');
      print('  answers count: ${answersData.length}');
      print('  timeSpent: ${2700 - timeRemaining.value}');
      print('  Full data: ${jsonEncode(requestData)}');

      // Send POST request
      final response = await DioClient.dio.post(url, data: requestData);

      print('✅ === RESPONSE ===');
      print('  Status: ${response.statusCode}');
      print('  Data: ${jsonEncode(response.data)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data;
        print('✅ Bài thi đã được ghi nhận');

        // Navigate to result screen with result data
        await Future.delayed(const Duration(seconds: 1));
        Get.offNamed(
          '/test-result',
          arguments: {
            'testId': testId.value,
            'attemptId': attemptId.value,
            'result': result,
          },
        );
      } else {
        print('Không thể nộp bài thi (${response.statusCode})');
      }
    } catch (e) {
      print('Không thể nộp bài thi: ${e.toString()}');
    }
  }

  /// Hủy bỏ bài thi (chưa hoàn thành) và báo backend để lưu status cancelled.
  Future<void> cancelTest() async {
    isCancelling.value = true;

    try {
      if (attemptId.value.isNotEmpty && testId.value > 0) {
        await DioClient.dio.post(
          '/v1/tests/${testId.value}/attempts/${attemptId.value}/cancel',
        );
      }
    } catch (e) {
      print('⚠️ Không thể lưu trạng thái hủy bài lên backend: $e');
    }

    _stopTimer();
    isTestActive.value = false;
    userAnswers.clear();
    currentQuestionIndex.value = 0;
    questions.clear();
    audioPath.value = '';
    attemptId.value = '';
    print('🛑 Bài thi đã bị hủy bỏ');
  }
}
