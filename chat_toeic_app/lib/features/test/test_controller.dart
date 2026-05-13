import 'dart:async';
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

  // === Test Metadata ===
  var testId = 0.obs;
  var testTitle = ''.obs;
  var totalQuestions = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
    
    // Auto-play audio when question changes
    ever(currentQuestionIndex, (_) {
      _autoPlayAudio();
    });
  }

  @override
  void onClose() {
    _stopTimer();
    _stopAudio();
    player.dispose();
    super.onClose();
  }

  /// ========== TIMER METHODS ==========

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        _stopTimer();
        isTestActive.value = false;
        Get.snackbar(
          'Hết giờ',
          'Thời gian làm bài đã hết. Bài thi sẽ được nộp tự động.',
          duration: const Duration(seconds: 3),
        );
        Future.delayed(const Duration(seconds: 1), () {
          submitTest();
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
        List<dynamic> data = response.data['data'] ?? response.data as List<dynamic>;
        
        // Use questions directly without transformation
        questions.assignAll(
          data.cast<Map<String, dynamic>>(),
        );
        totalQuestions.value = questions.length;
        
        // Initialize userAnswers map
        userAnswers.clear();
        
        // DEBUG: Print first question structure
        if (questions.isNotEmpty) {
          print('════════════════════════════════');
          print('🔍 FIRST QUESTION:');
          final q = questions[0];
          print('Keys: ${q.keys.toList()}');
          print('question: "${q['question']}"');
          print('optionA: "${q['optionA']}"');
          print('optionB: "${q['optionB']}"');
          print('optionC: "${q['optionC']}"');
          print('optionD: "${q['optionD']}"');
          print('mediaMappings: ${q['mediaMappings']}');
          print('════════════════════════════════');
        }
        
        Get.snackbar(
          'Thành công',
          'Tải ${questions.length} câu hỏi thành công',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      print('❌ Error fetching questions: $e');
      Get.snackbar('Lỗi', 'Không thể tải câu hỏi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ========== QUESTION NAVIGATION ==========

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
  Future<void> nextQuestion() async {
    if (hasNextQuestion) {
      await _stopAudio();
      currentQuestionIndex.value++;
    }
  }

  /// Chuyển đến câu hỏi trước
  Future<void> previousQuestion() async {
    if (hasPreviousQuestion) {
      await _stopAudio();
      currentQuestionIndex.value--;
    }
  }

  /// Nhảy đến câu hỏi cụ thể
  Future<void> goToQuestion(int index) async {
    if (index >= 0 && index < questions.length) {
      await _stopAudio();
      currentQuestionIndex.value = index;
    } else {
      Get.snackbar('Lỗi', 'Chỉ số câu hỏi không hợp lệ');
    }
  }

  /// ========== ANSWER SELECTION ==========

  /// Chọn đáp án và tự động chuyển sang câu tiếp theo sau 500ms
  void selectAnswer(int answerIndex) {
    if (currentQuestionIndex.value >= 0 && 
        currentQuestionIndex.value < questions.length) {
      // Lưu đáp án (map từ index câu hỏi -> index đáp án A/B/C/D)
      userAnswers[currentQuestionIndex.value] = answerIndex;
      
      Get.snackbar(
        'Đã lưu',
        'Đáp án đã được lưu',
        duration: const Duration(milliseconds: 500),
      );
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

  /// ========== AUDIO METHODS ==========

  Future<void> playAudio(String url) async {
    if (url.isEmpty) {
      Get.snackbar('Thông báo', 'Câu hỏi này không có audio');
      return;
    }
    
    try {
      isAudioPlaying.value = true;
      await player.setUrl(url);
      await player.play();
      
      // Listen to player state changes
      player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          isAudioPlaying.value = false;
        }
      });
    } catch (e) {
      isAudioPlaying.value = false;
      Get.snackbar('Lỗi Audio', 'Không thể phát âm thanh: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await player.pause();
      isAudioPlaying.value = false;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạm dừng âm thanh: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await player.stop();
      isAudioPlaying.value = false;
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể dừng âm thanh: $e');
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

  /// Extract audio URL from current question
  String? _getAudioUrlFromQuestion() {
    final question = currentQuestion;
    if (question.isEmpty) return null;
    
    if (question['mediaMappings'] is List && (question['mediaMappings'] as List).isNotEmpty) {
      final firstMapping = (question['mediaMappings'] as List).first as Map<String, dynamic>?;
      if (firstMapping != null && firstMapping['media'] != null) {
        return firstMapping['media']['url'] as String?;
      }
    }
    return null;
  }

  /// Auto-play audio for current question (if available)
  Future<void> _autoPlayAudio() async {
    await _stopAudio();
    final audioUrl = _getAudioUrlFromQuestion();
    if (audioUrl != null && audioUrl.isNotEmpty && isTestActive.value) {
      await Future.delayed(const Duration(milliseconds: 300));
      await playAudio(audioUrl);
    }
  }

  /// ========== TEST SUBMISSION ==========

  /// Nộp bài thi
  Future<void> submitTest() async {
    _stopTimer();
    isTestActive.value = false;
    
    // Tổng hợp thông tin trả lời
    print('═══════════════════════════════════════');
    print('📋 KẾT QUẢ NỘP BÀI THI');
    print('═══════════════════════════════════════');
    print('Test ID: ${testId.value}');
    print('Tổng câu hỏi: ${questions.length}');
    print('Câu đã trả lời: ${userAnswers.length}/${questions.length}');
    print('───────────────────────────────────────');
    print('Chi tiết câu trả lời:');
    for (int i = 0; i < questions.length; i++) {
      final answered = userAnswers.containsKey(i);
      final answer = userAnswers[i] ?? -1;
      print('  Câu $i: ${answered ? 'Đã chọn đáp án $answer' : 'Chưa trả lời'}');
    }
    print('═══════════════════════════════════════');
    
    // TODO: Gọi API để submit bài thi
    // try {
    //   final response = await DioClient.dio.post(
    //     '/v1/tests/${testId.value}/attempts/${attemptId}/submit',
    //     data: {
    //       'answers': userAnswers,
    //       'timeSpent': 2700 - timeRemaining.value,
    //     },
    //   );
    //   if (response.statusCode == 200) {
    //     Get.snackbar('Thành công', 'Bài thi đã được nộp');
    //     // Navigate to result screen
    //   }
    // } catch (e) {
    //   Get.snackbar('Lỗi', 'Không thể nộp bài thi: $e');
    // }
    
    Get.snackbar(
      'Nộp bài thành công',
      'Bài thi của bạn đã được nộp',
      duration: const Duration(seconds: 2),
    );
  }

  /// Hủy bỏ bài thi (chưa hoàn thành)
  void cancelTest() {
    _stopTimer();
    isTestActive.value = false;
    userAnswers.clear();
    currentQuestionIndex.value = 0;
    questions.clear();
    Get.snackbar('Đã hủy', 'Bài thi đã bị hủy bỏ');
  }
}
