import 'package:get/get.dart';

class TestResultController extends GetxController {
  // Test metadata
  var testId = 0.obs;
  var attemptId = ''.obs;
  var resultData = <String, dynamic>{}.obs;

  // Calculated values
  var totalQuestions = 0.obs;
  var correctAnswers = 0.obs;
  var scorePercentage = 0.0.obs;
  var scorePoints = 0.0.obs;
  var maxScore = 10.0.obs;
  // Display total (fallback to 50 if backend doesn't provide total)
  var displayTotal = 50.obs;

  @override
  void onInit() {
    super.onInit();
    _parseResult();
  }

 /// Parse result data from API response
  void _parseResult() {
    // 1. Lấy arguments an toàn để tránh lỗi IdentityMap
    final dynamic rawArgs = Get.arguments;
    
    if (rawArgs == null) {
      print('❌ No arguments provided to TestResultController');
      return;
    }

    Map<String, dynamic> args = {};
    int _safeExtractInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      if (v is Map) {
        if (v.containsKey('id')) return _safeExtractInt(v['id']);
        if (v.containsKey('testId')) return _safeExtractInt(v['testId']);
        if (v.isNotEmpty) return _safeExtractInt(v.values.first);
      }
      return 0;
    }

    if (rawArgs is Map) {
      args = Map<String, dynamic>.from(rawArgs);
      testId.value = _safeExtractInt(args['testId'] ?? args['testId']);
      attemptId.value = args['attemptId']?.toString() ?? '';
    } else if (rawArgs is int) {
      testId.value = rawArgs;
    }

    // 2. Lấy dữ liệu kết quả (Biến 'result' chính là Full data từ Response)
    final result = args['result'] as Map<String, dynamic>? ?? {};
    resultData.assignAll(result);

    // 3. Truy xuất vào data Wrapper (theo cấu trúc {"data": {...}})
    final dataWrapper = result['data'] as Map<String, dynamic>?;

    // --- SỬA CÁC KEY TẠI ĐÂY ĐỂ KHỚP VỚI LOG CỦA BẠN ---
    
    // Lấy 'correctCount' thay vì 'correctAnswers'
    // Parse numeric fields defensively (may be int, double, string, etc.)
    dynamic rawCorrect = dataWrapper?['correctCount'] ?? result['correctCount'] ?? 0;
    if (rawCorrect is int) {
      correctAnswers.value = rawCorrect;
    } else {
      correctAnswers.value = int.tryParse(rawCorrect?.toString() ?? '0') ?? 0;
    }

    // Lấy 'total' thay vì 'totalQuestions'
    dynamic rawTotal = dataWrapper?['total'] ?? result['total'] ?? 0;
    if (rawTotal is int) {
      totalQuestions.value = rawTotal;
    } else {
      totalQuestions.value = int.tryParse(rawTotal?.toString() ?? '0') ?? 0;
    }

    // Lấy 'score' và ép kiểu double an toàn
    var rawScore = dataWrapper?['score'] ?? result['score'] ?? 0.0;
    if (rawScore is int) {
      scorePoints.value = rawScore.toDouble();
    } else {
      scorePoints.value = (rawScore as num).toDouble();
    }

    // 4. Tính toán phần trăm (để hiển thị Feedback)
    if (totalQuestions.value > 0) {
      scorePercentage.value = (correctAnswers.value / totalQuestions.value) * 100;
    }

    // Cập nhật tổng số câu hiển thị (mặc định 50 nếu total = 0)
    displayTotal.value = totalQuestions.value > 0 ? totalQuestions.value : 50;

    // Log kiểm tra sau khi đã map đúng Key
    print('📊 [FIXED] Test Result Parsed:');
    print('   correctCount: ${correctAnswers.value}'); // Sẽ hiện 1 theo log của bạn
    print('   total: ${totalQuestions.value}');       // Sẽ hiện 50 theo log của bạn
    print('   score: ${scorePoints.value}');          // Sẽ hiện 0.2 theo log của bạn
  }
  /// Get feedback message based on score
  String get getFeedbackMessage {
    if (scorePercentage.value >= 90) {
      return 'Tuyệt vời! Bạn làm rất tốt!';
    } else if (scorePercentage.value >= 75) {
      return 'Làm tốt lắm! Tiếp tục cố gắng!';
    } else if (scorePercentage.value >= 60) {
      return 'Khá tốt, nhưng cần cố gắng hơn!';
    } else if (scorePercentage.value >= 50) {
      return 'Không tệ, nhưng hãy học thêm!';
    } else {
      return 'Cần cố gắng hơn nữa. Hãy ôn tập lại!';
    }
  }

  /// Get feedback color based on score
  String get getFeedbackColor {
    if (scorePercentage.value >= 90) {
      return '0xFF10B981'; // Green
    } else if (scorePercentage.value >= 75) {
      return '0xFF3B82F6'; // Blue
    } else if (scorePercentage.value >= 60) {
      return '0xFFF59E0B'; // Amber
    } else {
      return '0xFFEF4444'; // Red
    }
  }

  /// Navigate to detailed answers view
  void viewDetailedAnswers() {
    String _resolveAttemptId() {
      final id = attemptId.value.trim();
      if (int.tryParse(id) != null) {
        return id;
      }

      final dynamic rawResult = resultData;
      if (rawResult is Map) {
        final dynamic data = rawResult['data'];
        if (data is Map) {
          final dynamic practiceId = data['userTestId'] ?? data['attemptId'] ?? data['id'];
          if (practiceId != null) return practiceId.toString();
        }

        final dynamic directPracticeId = rawResult['userTestId'] ?? rawResult['attemptId'] ?? rawResult['id'];
        if (directPracticeId != null) return directPracticeId.toString();
      }

      return id;
    }

    Get.toNamed(
      '/test-answer-details',
      arguments: {
        'testId': testId.value,
        'attemptId': _resolveAttemptId(),
        // Pass parsed result data (plain Map) so the details view can render answers
        'result': Map<String, dynamic>.from(resultData),
      },
    );
  }

  /// Retake the test
  void retakeTest() {
    // Clear previous attempt data and navigate back to test detail so user can retake
    attemptId.value = '';
    resultData.clear();
    Get.offNamed(
      '/test-detail',
      arguments: {
        'testId': testId.value,
      },
    );
  }

  /// Return to home
  void goHome() {
    Get.offNamedUntil('/home', (route) => false);
  }
}
