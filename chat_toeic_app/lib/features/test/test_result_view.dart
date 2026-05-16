import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/test/test_result_controller.dart';

class TestResultView extends StatelessWidget {
  const TestResultView({super.key});

  static const double _scoreCircleSize = 270;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TestResultController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === HEADER ===
            _buildHeader(controller),

            // === MAIN CONTENT ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              child: Column(
                children: [
                  // === CIRCULAR SCORE DISPLAY ===
                  _buildCircularScore(controller),
                  const SizedBox(height: 32),

                  // === SCORE BREAKDOWN ===
                  _buildScoreBreakdown(controller),
                  const SizedBox(height: 28),

                  // === FEEDBACK MESSAGE ===
                  _buildFeedbackMessage(controller),
                  const SizedBox(height: 32),

                  // === PRIMARY ACTION BUTTONS (Centered, side by side) ===
                  Center(child: _buildPrimaryActionButtons(controller)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HEADER: Close button and test info
  Widget _buildHeader(TestResultController controller) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => controller.goHome(),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Text(
            'Kết Quả',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  /// CIRCULAR SCORE DISPLAY with progress indicator
  Widget _buildCircularScore(TestResultController controller) {
    return Obx(
      () {
        final percentage = controller.scorePercentage.value;

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle with gradient
                Container(
                  width: _scoreCircleSize,
                  height: _scoreCircleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF111C34),
                    border: Border.all(
                      color: const Color(0xFF24324F),
                      width: 2.5,
                    ),
                  ),
                ),

                // Circular Progress using CustomPaint for smooth animation
                SizedBox(
                  width: _scoreCircleSize,
                  height: _scoreCircleSize,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getScoreColor(percentage),
                    ),
                    backgroundColor: const Color(0xFF334155),
                  ),
                ),

                // Center text with glow effect
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () => Text(
                        '${controller.scorePercentage.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getScoreColor(percentage),
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(
                      () => Text(
                        '${controller.correctAnswers.value}/${controller.displayTotal.value} câu',
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// SCORE BREAKDOWN: Show correct/incorrect in compact form
  Widget _buildScoreBreakdown(TestResultController controller) {
    return Obx(
      () {
        final total = controller.totalQuestions.value;
        final correct = controller.correctAnswers.value;
        final incorrect = total - correct;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF111C34),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF60A5FA).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactBreakdownItem(
                count: correct,
                label: 'Đúng',
                color: const Color(0xFF10B981),
              ),
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF334155),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _buildCompactBreakdownItem(
                count: incorrect,
                label: 'Sai',
                color: const Color(0xFFEF4444),
              ),
              Container(
                width: 2,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF334155),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _buildCompactBreakdownItem(
                count: total,
                label: 'Tổng',
                color: const Color(0xFF93C5FD),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Compact breakdown item
  Widget _buildCompactBreakdownItem({
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  /// FEEDBACK MESSAGE based on score
  Widget _buildFeedbackMessage(TestResultController controller) {
    return Obx(
      () {
        final message = controller.getFeedbackMessage;
        final percentage = controller.scorePercentage.value;
        final detailedText = _getDetailedFeedback(percentage);
        final scoreColor = _getScoreColor(percentage);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111C34),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scoreColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getScoreIcon(percentage),
                      color: scoreColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 200,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  detailedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// PRIMARY ACTION BUTTONS (Centered, side by side)
  Widget _buildPrimaryActionButtons(TestResultController controller) {
    final double buttonAreaWidth = (Get.width - 32).clamp(360.0, 420.0);

    return SizedBox(
      width: buttonAreaWidth,
      child: Row(
        children: [
          // "Xem đáp án chi tiết" Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () => controller.viewDetailedAnswers(),
                icon: const Icon(Icons.description_outlined, size: 22),
                label: const Text(
                  'Xem đáp án',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // "Làm lại bài" Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () => controller.retakeTest(),
                icon: const Icon(Icons.refresh, size: 22),
                label: const Text(
                  'Làm lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Get color based on score percentage
  Color _getScoreColor(double percentage) {
    if (percentage >= 90) {
      return const Color(0xFF10B981); // Green
    } else if (percentage >= 75) {
      return const Color(0xFF3B82F6); // Blue
    } else if (percentage >= 60) {
      return const Color(0xFFF59E0B); // Amber
    } else if (percentage >= 50) {
      return const Color(0xFFFF6B6B); // Orange-Red
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  /// Helper: Get detailed feedback text based on score
  String _getDetailedFeedback(double percentage) {
    if (percentage >= 90) {
      return 'Bạn chinh phục bài thi một cách xuất sắc. Tiếp tục duy trì phong độ!';
    } else if (percentage >= 75) {
      return 'Bạn thực hiện tốt. Chỉ cần rèn luyện thêm một chút nữa.';
    } else if (percentage >= 60) {
      return 'Bạn đi đúng hướng. Hãy ôn tập và làm thêm bài tập.';
    } else if (percentage >= 50) {
      return 'Bạn cần tập trung học tập thêm nhiều hơn.';
    } else {
      return 'Hãy bắt đầu lại từ đầu với kế hoạch học tập chi tiết hơn.';
    }
  }

  /// Helper: Get icon based on score percentage
  IconData _getScoreIcon(double percentage) {
    if (percentage >= 90) {
      return Icons.star;
    } else if (percentage >= 75) {
      return Icons.thumb_up;
    } else if (percentage >= 60) {
      return Icons.trending_up;
    } else if (percentage >= 50) {
      return Icons.info;
    } else {
      return Icons.warning;
    }
  }
}
