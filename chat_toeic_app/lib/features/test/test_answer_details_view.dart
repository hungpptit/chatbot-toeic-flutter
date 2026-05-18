import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestAnswerDetailsView extends StatefulWidget {
  const TestAnswerDetailsView({super.key});

  @override
  State<TestAnswerDetailsView> createState() => _TestAnswerDetailsViewState();
}

class _TestAnswerDetailsViewState extends State<TestAnswerDetailsView> {
  late final int testId;
  late final String attemptId;
  late final Future<Map<String, dynamic>> _reviewFuture;
  int _currentIndex = 0;

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  int _safeExtractInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) {
      if (value.containsKey('testId')) return _safeExtractInt(value['testId']);
      if (value.containsKey('id')) return _safeExtractInt(value['id']);
    }
    return 0;
  }

  String _safeExtractString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  List<Map<String, dynamic>> _safeDetailsList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _fetchAttemptDetail(String id) async {
    final resolvedId = int.tryParse(id);
    if (resolvedId == null) {
      final dynamic rawResult = _safeMap(Get.arguments)['result'];
      final dynamic data = _safeMap(rawResult)['data'];
      final dynamic fallbackId = data is Map
          ? (data['userTestId'] ?? data['attemptId'] ?? data['id'])
          : (_safeMap(rawResult)['userTestId'] ?? _safeMap(rawResult)['attemptId'] ?? _safeMap(rawResult)['id']);

      if (fallbackId != null && int.tryParse(fallbackId.toString()) != null) {
        return await _fetchAttemptDetail(fallbackId.toString());
      }

      return {};
    }

    try {
      // test_v1_router is mounted at /v1/tests, so full path is /v1/tests/test-attempts/:attemptId/result
      final response = await DioClient.dio.get('/v1/tests/test-attempts/$resolvedId/result');
      final dynamic rawData = response.data['data'] ?? response.data;
      return _safeMap(rawData);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        rethrow;
      }

      final fallbackResponse = await DioClient.dio.get('/questionTest/DetailResult/$id');
      final dynamic rawData = fallbackResponse.data['data'] ?? fallbackResponse.data;
      return _safeMap(rawData);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTestQuestions(int id) async {
    try {
      final response = await DioClient.dio.get('/v1/tests/$id/questions');
      final dynamic rawData = response.data['data'] ?? response.data;
      if (rawData is List) {
        return rawData.whereType<Map>().map((q) => Map<String, dynamic>.from(q)).toList();
      }
      if (rawData is Map && rawData['questions'] is List) {
        return (rawData['questions'] as List)
            .whereType<Map>()
            .map((q) => Map<String, dynamic>.from(q))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;

      final fallback = await DioClient.dio.get('/questionTest/Detail/$id');
      final dynamic rawData = fallback.data['data'] ?? fallback.data;
      if (rawData is List) {
        return rawData.whereType<Map>().map((q) => Map<String, dynamic>.from(q)).toList();
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchReviewData() async {
    final attempt = await _fetchAttemptDetail(attemptId);
    final attemptDetails = _safeDetailsList(attempt['details']);

    final resolvedTestId = testId > 0 ? testId : _safeExtractInt(attempt['testId']);
    final allQuestions = resolvedTestId > 0 ? await _fetchTestQuestions(resolvedTestId) : <Map<String, dynamic>>[];

    final attemptByQuestionId = <String, Map<String, dynamic>>{};
    for (final detail in attemptDetails) {
      final key = _safeExtractString(detail['questionId']);
      if (key.isNotEmpty) {
        attemptByQuestionId[key] = detail;
      }
    }

    final mergedDetails = <Map<String, dynamic>>[];

    if (allQuestions.isNotEmpty) {
      for (final question in allQuestions) {
        final questionId = _safeExtractString(question['id']);
        final attemptDetail = attemptByQuestionId[questionId] ?? <String, dynamic>{};

        mergedDetails.add({
          ...question,
          ...attemptDetail,
          'questionId': question['id'] ?? attemptDetail['questionId'],
          'selectedOption': _safeExtractString(attemptDetail['selectedOption']),
          'isCorrect': _toBool(attemptDetail['isCorrect']),
        });
      }
    } else {
      mergedDetails.addAll(attemptDetails.map((detail) => {
            ...detail,
            'selectedOption': _safeExtractString(detail['selectedOption']),
            'isCorrect': _toBool(detail['isCorrect']),
          }));
    }

    final total = mergedDetails.length;
    final answered = mergedDetails.where((d) => _safeExtractString(d['selectedOption']).isNotEmpty).length;
    final correct = mergedDetails.where((d) => _toBool(d['isCorrect'])).length;

    return {
      'testId': resolvedTestId,
      'details': mergedDetails,
      'total': total,
      'answered': answered,
      'correct': correct,
      'incorrect': answered - correct,
      'skipped': total - answered,
    };
  }

  @override
  void initState() {
    super.initState();
    final args = _safeMap(Get.arguments);
    testId = _safeExtractInt(args['testId'] ?? args['result'] ?? args);
    attemptId = _safeExtractString(
      args['attemptId'] ??
          args['attemptID'] ??
          _safeMap(args['result'])['userTestId'] ??
          _safeMap(_safeMap(args['result'])['data'])['userTestId'] ??
          '',
    );
    _reviewFuture = _fetchReviewData();
  }

  String _extractCorrectAnswer(Map<String, dynamic> question) {
    final dynamic value = question['correctAnswer'] ?? question['correct_answer'] ?? question['answer'];
    return value?.toString().trim() ?? '';
  }

  String _normalizeAnswer(String value) {
    return value.trim().toUpperCase();
  }

  bool _isCorrectOption(String optionLabel, String correctAnswer, String optionText) {
    final normalizedCorrect = _normalizeAnswer(correctAnswer);
    final normalizedLabel = _normalizeAnswer(optionLabel);
    final normalizedText = _normalizeAnswer(optionText);

    if (normalizedCorrect.isEmpty) return false;
    if (normalizedCorrect == normalizedLabel) return true;
    if (normalizedCorrect == normalizedText) return true;
    return false;
  }

  bool _isSelectedOption(String optionLabel, String selectedOption, String optionText) {
    final normalizedSelected = _normalizeAnswer(selectedOption);
    final normalizedLabel = _normalizeAnswer(optionLabel);
    final normalizedText = _normalizeAnswer(optionText);

    if (normalizedSelected.isEmpty) return false;
    if (normalizedSelected == normalizedLabel) return true;
    if (normalizedSelected == normalizedText) return true;
    return false;
  }

  String _extractImageUrl(Map<String, dynamic> detail) {
    final mediaFiles = _safeDetailsList(detail['mediaFiles']);
    for (final media in mediaFiles) {
      final mediaType = _safeExtractString(media['mediaType']).toLowerCase();
      final mediaUrl = _safeExtractString(media['mediaUrl']);
      if (mediaType == 'image' && mediaUrl.isNotEmpty) {
        return mediaUrl;
      }
    }

    final mediaMappings = _safeDetailsList(detail['mediaMappings']);
    for (final mapping in mediaMappings) {
      final media = _safeMap(mapping['media']);
      final mediaType = _safeExtractString(media['type']).toLowerCase();
      final mediaUrl = _safeExtractString(media['url']);
      if (mediaType == 'image' && mediaUrl.isNotEmpty) {
        return mediaUrl;
      }
    }

    return '';
  }

  String _extractOptionText(Map<String, dynamic> detail, String label) {
    final normalized = label.trim().toUpperCase();

    // Priority 1: Try direct optionA, optionB, optionC, optionD fields
    final directKey = 'option$normalized';
    final directValue = detail[directKey];
    if (directValue != null) {
      final text = _safeExtractString(directValue).trim();
      if (text.isNotEmpty) return text;
    }

    // Priority 2: Try lowercase optionA, optionB, optionC, optionD
    final lowerKey = 'option${normalized.toLowerCase()}';
    final lowerValue = detail[lowerKey];
    if (lowerValue != null) {
      final text = _safeExtractString(lowerValue).trim();
      if (text.isNotEmpty) return text;
    }

    // Priority 3: Try choiceA, choiceB, choiceC, choiceD
    final choiceKey = 'choice$normalized';
    final choiceValue = detail[choiceKey];
    if (choiceValue != null) {
      final text = _safeExtractString(choiceValue).trim();
      if (text.isNotEmpty) return text;
    }

    // Priority 4: Try answerA, answerB, answerC, answerD
    final answerKey = 'answer$normalized';
    final answerValue = detail[answerKey];
    if (answerValue != null) {
      final text = _safeExtractString(answerValue).trim();
      if (text.isNotEmpty) return text;
    }

    // Priority 5: Try answers list
    final answers = detail['answers'];
    if (answers is List) {
      final index = normalized.codeUnitAt(0) - 65;
      if (index >= 0 && index < answers.length) {
        final text = _safeExtractString(answers[index]).trim();
        if (text.isNotEmpty) return text;
      }
    }

    // Priority 6: Try options map
    if (detail['options'] is Map) {
      final options = _safeMap(detail['options']);
      final text = _safeExtractString(options[normalized] ?? options[normalized.toLowerCase()]).trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  Widget _buildOptionTile({
    required String label,
    required String text,
    required bool isSelected,
    required bool isCorrect,
  }) {
    final backgroundColor = isCorrect
        ? const Color(0xFF16A34A)
        : isSelected
            ? const Color(0xFFDC2626)
            : Colors.transparent;
    final borderColor = isCorrect
        ? const Color(0xFF16A34A)
        : isSelected
            ? const Color(0xFFDC2626)
            : const Color(0xFF94A3B8);
    final textColor = isCorrect || isSelected ? Colors.white : Colors.white;

    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCorrect || isSelected ? Colors.white.withOpacity(0.95) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isCorrect
                        ? const Color(0xFF16A34A)
                        : isSelected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: text.isNotEmpty
                  ? Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (isCorrect || isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTile(Map<String, dynamic> detail, int index, int totalQuestions) {
    final correctAnswer = _extractCorrectAnswer(detail);
    // Try multiple field names for question text
    var questionText = detail['question']?.toString() ?? 
                       detail['questionText']?.toString() ?? 
                       detail['questionContent']?.toString() ?? 
                       '';
    if (questionText.isEmpty) {
      questionText = 'Không có nội dung câu hỏi';
    }
    
    // Debug logging
    print('🔍 Question Detail Debug - Index: $index');
    print('   Question Text: ${questionText.substring(0, questionText.length > 50 ? 50 : questionText.length)}...');
    print('   Detail Keys: ${detail.keys.toList()}');
    
    final optionA = _extractOptionText(detail, 'A');
    final optionB = _extractOptionText(detail, 'B');
    final optionC = _extractOptionText(detail, 'C');
    final optionD = _extractOptionText(detail, 'D');
    final selectedOption = detail['selectedOption']?.toString() ?? '';
    final hasCorrectAnswer = correctAnswer.isNotEmpty;
    final status = detail['isCorrect'] == true ? 'Đúng' : (selectedOption.isEmpty ? 'Chưa làm' : 'Sai');
    final imageUrl = _extractImageUrl(detail);
    final explanation = detail['explanation']?.toString() ?? '';
    
    print('✅ Extracted Options:');
    print('   A: ${optionA.isEmpty ? "(empty)" : optionA.substring(0, optionA.length > 30 ? 30 : optionA.length)}');
    print('   B: ${optionB.isEmpty ? "(empty)" : optionB.substring(0, optionB.length > 30 ? 30 : optionB.length)}');
    print('   C: ${optionC.isEmpty ? "(empty)" : optionC.substring(0, optionC.length > 30 ? 30 : optionC.length)}');
    print('   D: ${optionD.isEmpty ? "(empty)" : optionD.substring(0, optionD.length > 30 ? 30 : optionD.length)}');

    // Build options column (reusable)
    final optionsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Câu ${index + 1} / $totalQuestions',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        // Question text with better styling and ensure it's always visible
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildOptionTile(
          label: 'A',
          text: optionA,
          isSelected: _isSelectedOption('A', selectedOption, optionA),
          isCorrect: hasCorrectAnswer && _isCorrectOption('A', correctAnswer, optionA),
        ),
        _buildOptionTile(
          label: 'B',
          text: optionB,
          isSelected: _isSelectedOption('B', selectedOption, optionB),
          isCorrect: hasCorrectAnswer && _isCorrectOption('B', correctAnswer, optionB),
        ),
        _buildOptionTile(
          label: 'C',
          text: optionC,
          isSelected: _isSelectedOption('C', selectedOption, optionC),
          isCorrect: hasCorrectAnswer && _isCorrectOption('C', correctAnswer, optionC),
        ),
        _buildOptionTile(
          label: 'D',
          text: optionD,
          isSelected: _isSelectedOption('D', selectedOption, optionD),
          isCorrect: hasCorrectAnswer && _isCorrectOption('D', correctAnswer, optionD),
        ),
       const SizedBox(height: 6),
        if (explanation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Giải thích: $explanation',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 22,             // Tăng kích thước chữ (từ 18 lên 22)
              fontWeight: FontWeight.bold, // In đậm toàn bộ đoạn văn bản
              height: 1.6,
            ),
          ),
        ],
      ],
    );
    // If no image: show full-width layout (reading tests)
    if (imageUrl.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: optionsColumn,
            ),
          ),
        ],
      );
    }

    // If has image: show split-screen layout (listening tests)
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // === LEFT SIDE: Image ===
              Expanded(
                flex: 5,
                child: Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(16),
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(80),
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Không thể tải hình ảnh',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // === RIGHT SIDE: Questions + Answers ===
              Expanded(
                flex: 6,
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: optionsColumn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasPrevious => _currentIndex > 0;

  bool _hasNext(int total) => _currentIndex < total - 1;

  void _goPrevious() {
    if (_hasPrevious) {
      setState(() => _currentIndex--);
    }
  }

  void _goNext(int total) {
    if (_hasNext(total)) {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _showQuestionMenu(BuildContext context, List<Map<String, dynamic>> details) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Đã xóa phần Padding chứa tiêu đề và nút Close ở đây
              
              const SizedBox(height: 8), // Thêm một khoảng giãn nhỏ ở đầu nếu muốn
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final selected = _safeExtractString(details[index]['selectedOption']);
                    final isAnswered = selected.isNotEmpty;
                    final isCorrect = _toBool(details[index]['isCorrect']);
                    final isCurrent = _currentIndex == index;

                    final bgColor = isCurrent
                        ? const Color(0xFF6366F1)
                        : !isAnswered
                            ? const Color(0xFF334155)
                            : isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFDC2626);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildFooter(BuildContext context, List<Map<String, dynamic>> details) {
    final answeredCount = details.where((d) => _safeExtractString(d['selectedOption']).isNotEmpty).length;

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _hasPrevious ? _goPrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Câu trước'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasPrevious ? const Color(0xFF6366F1) : const Color(0xFF334155),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _hasNext(details.length) ? () => _goNext(details.length) : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Câu sau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasNext(details.length) ? const Color(0xFF6366F1) : const Color(0xFF334155),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Quay lại',
        ),
        title: const Text(
          'Chi tiết đáp án',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reviewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không tải được đáp án chi tiết: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reviewData = snapshot.data ?? <String, dynamic>{};
          final details = _safeDetailsList(reviewData['details']);

          if (details.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Không có dữ liệu đáp án để hiển thị',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          if (_currentIndex >= details.length) {
            _currentIndex = 0;
          }

          return Column(
            children: [
              Expanded(
                child: _buildQuestionTile(details[_currentIndex], _currentIndex, details.length),
              ),
              _buildFooter(context, details),
            ],
          );
        },
      ),
    );
  }
}
