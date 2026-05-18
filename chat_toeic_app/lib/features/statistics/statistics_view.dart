import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chat_toeic_app/core/theme/app_colors.dart';
import 'package:chat_toeic_app/features/statistics/statistics_controller.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/features/test/test_controller.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:chat_toeic_app/widgets/nav_bar.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StatisticsController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          const CustomNavBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(controller),
                    const SizedBox(height: 32),
                    _buildQuickStats(controller),
                    const SizedBox(height: 32),
                    LayoutBuilder(builder: (context, constraints) {
                      if (constraints.maxWidth > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildAccuracyChart(controller)),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildPartStats(controller)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildAccuracyChart(controller),
                          const SizedBox(height: 24),
                          _buildPartStats(controller),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),
                    _buildHistoryList(controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(StatisticsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white10),
            ),
            const SizedBox(width: 16),
              const Text(
                'Thống kê học tập',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  // Fetch recommendations from backend and show dialog
                  try {
                    final auth = Get.find<AuthController>();
                    final user = auth.user.value;
                    if (user == null || user['id'] == null) {
                      Get.snackbar('Lỗi', 'Vui lòng đăng nhập để sử dụng tính năng này');
                      return;
                    }

                    final userId = user['id'].toString();
                    final loading = Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

                    final resp = await DioClient.dio.get('/ml/recommend/details/$userId');
                    Get.back(); // close loading

                    if (resp.statusCode == 200 && resp.data != null && resp.data['data'] != null) {
                      final data = resp.data['data'];
                      final weakSkills = data['weak_skills'] as List<dynamic>? ?? [];
                      final questions = data['questions'] as List<dynamic>? ?? [];

                      if (weakSkills.isEmpty && questions.isEmpty) {
                        _showNoWeakSkillDialog(
                          title: 'Chúc mừng!',
                          message: 'Hiện tại bạn chưa có kỹ năng yếu nào nổi bật. Hãy tiếp tục duy trì phong độ nhé.',
                        );
                        return;
                      }

                      if (weakSkills.isEmpty) {
                        _showNoWeakSkillDialog(
                          title: 'Chúc mừng!',
                          message: 'Hiện tại bạn chưa có kỹ năng yếu nào nổi bật. Hãy tiếp tục duy trì phong độ nhé.',
                        );
                        return;
                      }

                      if (questions.isEmpty) {
                        _showNoWeakSkillDialog(
                          title: 'Chúc mừng!',
                          message: 'Hiện tại bạn chưa có kỹ năng yếu nào nổi bật. Hãy tiếp tục duy trì phong độ nhé.',
                        );
                        return;
                      }

                      // Show bottom sheet with recommended questions
                      Get.bottomSheet(
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kỹ năng yếu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: weakSkills.map((s) => Chip(label: Text(s.toString(), style: const TextStyle(color: Colors.white)))).toList(),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Start practice: preload questions into TestController and navigate
                                      final practiceTestId = DateTime.now().millisecondsSinceEpoch ~/ 1000; // unique int

                                      // Create a TestController with tag matching TestDetailView expectation
                                      final tag = 'test_$practiceTestId';
                                      TestController testController;
                                      try {
                                        testController = Get.find<TestController>(tag: tag);
                                      } catch (e) {
                                        testController = Get.put(TestController(), tag: tag);
                                      }

                                      // Preload questions (ensure they are Map<String,dynamic>)
                                      final List<Map<String, dynamic>> qList = questions.map<Map<String,dynamic>>((e) => Map<String,dynamic>.from(e as Map)).toList();
                                      testController.questions.assignAll(qList);
                                      testController.totalQuestions.value = qList.length;

                                      // Mark controller as practice mode and activate test state
                                      testController.isPracticeMode.value = true;
                                      testController.isTestActive.value = true;
                                      testController.testStarted.value = true;
                                      testController.testId.value = practiceTestId;

                                      // Navigate to test detail with our synthetic testId
                                      Get.back(); // close bottom sheet
                                      Get.toNamed('/test-detail', arguments: {'testId': practiceTestId});
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    child: const Text('Bắt đầu luyện tập'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Câu hỏi gợi ý', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...questions.map((q) {
                                  final qText = q['question'] ?? q['content'] ?? '';
                                  final questionTypeName = _extractQuestionTypeName(q);
                                  final questionTypeDescription = _extractQuestionTypeDescription(q);
                                  final questionTypeLabel = _extractQuestionTypeLabel(q);
                                  final partLabel = _extractPartLabel(q);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111C34),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF24324F)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          qText.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildMetaChip(questionTypeLabel),
                                            _buildMetaChip(partLabel),
                                          ],
                                        ),
                                        if (questionTypeName != null || questionTypeDescription != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            questionTypeName != null
                                                ? 'Question Type: $questionTypeName${questionTypeDescription != null ? ' - $questionTypeDescription' : ''}'
                                                : 'Question Type: Unknown',
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        isScrollControlled: true,
                      );
                    } else {
                      Get.snackbar('Lỗi', 'Không nhận được gợi ý. Vui lòng thử lại sau.');
                    }
                  } catch (e) {
                    try { Get.back(); } catch (_) {}
                    print('Error fetching recommendations: $e');
                    Get.snackbar('Lỗi', 'Không thể lấy gợi ý luyện tập');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Dự đoán kỹ năng yếu'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Theo dõi quá trình luyện tập và sự tiến bộ của bạn',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildQuickStats(StatisticsController controller) {
    final stats = controller.userStats.value;
    return Row(
      children: [
        _buildStatCard(
          'Tổng số bài thi',
          '${stats['totalAttempts'] ?? 0}',
          Icons.assignment_turned_in,
          const Color(0xFF6366F1),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Thời gian luyện tập',
          controller.formatDuration(stats['totalTimeSeconds'] ?? 0),
          Icons.timer,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNoWeakSkillDialog({
    required String title,
    required String message,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF111C34),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(color: Color(0xFF10B981)),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _extractQuestionTypeLabel(dynamic question) {
    final dynamic raw = question is Map ? (question['questionType'] ?? question['type'] ?? question['typeId']) : null;

    String? candidate;
    if (raw is Map) {
      candidate = (raw['name'] ?? raw['title'] ?? raw['label'] ?? raw['typeName'] ?? raw['questionTypeName'])?.toString();
    } else if (raw != null) {
      candidate = raw.toString();
    }

    final lower = candidate?.toLowerCase() ?? '';
    if (lower.contains('listen')) return 'Listening';
    if (lower.contains('read')) return 'Reading';

    final partNumber = _extractPartNumber(question);
    if (partNumber >= 1 && partNumber <= 4) return 'Listening';
    if (partNumber >= 5 && partNumber <= 7) return 'Reading';

    return candidate?.isNotEmpty == true ? candidate! : 'Unknown type';
  }

  String? _extractQuestionTypeName(dynamic question) {
    if (question is! Map) return null;

    final dynamic raw = question['questionType'] ?? question['type'];
    if (raw is Map) {
      final name = raw['name'] ?? raw['title'] ?? raw['label'] ?? raw['typeName'] ?? raw['questionTypeName'];
      return name?.toString();
    }

    if (raw != null) {
      return raw.toString();
    }

    return null;
  }

  String? _extractQuestionTypeDescription(dynamic question) {
    if (question is! Map) return null;

    final dynamic raw = question['questionType'] ?? question['type'];
    if (raw is Map) {
      final description = raw['description'] ?? raw['desc'];
      final text = description?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }

  String _extractPartLabel(dynamic question) {
    final partNumber = _extractPartNumber(question);
    if (partNumber > 0) {
      return 'Part $partNumber';
    }

    final dynamic raw = question is Map ? question['part'] : null;
    if (raw is Map) {
      final name = (raw['name'] ?? raw['title'] ?? raw['label'] ?? raw['partName'])?.toString();
      if (name != null && name.isNotEmpty) return name;
    } else if (raw != null) {
      return raw.toString();
    }

    return 'Part unknown';
  }

  int _extractPartNumber(dynamic question) {
    if (question is! Map) return 0;

    final dynamic rawPart = question['part'] ?? question['partId'];
    if (rawPart is int) return rawPart;
    if (rawPart is String) return int.tryParse(rawPart) ?? 0;
    if (rawPart is Map) {
      final dynamic nested = rawPart['id'] ?? rawPart['partId'] ?? rawPart['number'];
      if (nested is int) return nested;
      if (nested is String) return int.tryParse(nested) ?? 0;
    }

    return 0;
  }

  Widget _buildAccuracyChart(StatisticsController controller) {
    return Container(
      constraints: const BoxConstraints(minHeight: 450),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Độ chính xác theo thời gian',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Timeframe Selector
              Obx(() => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [7, 30, 90].map((days) {
                    final isSelected = controller.selectedTimeframe.value == days;
                    return GestureDetector(
                      onTap: () => controller.selectedTimeframe.value = days,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$days ngày',
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: Obx(() {
              if (controller.isChartLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final data = controller.accuracyOverTime;
              if (data.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Chưa có dữ liệu biểu đồ', style: TextStyle(color: Colors.white24)),
                  ),
                );
              }

              return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < data.length) {
                              if (data.length > 7 && index % (data.length ~/ 5) != 0) return const SizedBox.shrink();
                              final date = data[index]['date'].toString().substring(5); // mm-dd
                              return Text(date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['accuracy'].toDouble())).toList(),
                        isCurved: true,
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF6366F1).withOpacity(0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPartStats(StatisticsController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê theo Part',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...controller.partStats.map((part) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(part['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                    Text('${part['accuracy']}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (part['accuracy'] as num).toDouble() / 100,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: (part['accuracy'] as num) > 70 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryList(StatisticsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lịch sử làm bài gần đây',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() => Column(
          children: [
            ...controller.paginatedHistory.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(item['date'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['correct']}/${item['total']}',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(item['duration'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            )),
            
            // Pagination Controls
            if (controller.totalHistoryPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageButton(
                      icon: Icons.chevron_left,
                      onPressed: controller.currentHistoryPage.value > 1 
                          ? () => controller.currentHistoryPage.value-- 
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Trang ${controller.currentHistoryPage.value} / ${controller.totalHistoryPages}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    _buildPageButton(
                      icon: Icons.chevron_right,
                      onPressed: controller.currentHistoryPage.value < controller.totalHistoryPages 
                          ? () => controller.currentHistoryPage.value++ 
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        )),
      ],
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: onPressed != null ? Colors.white : Colors.white24, size: 20),
      ),
    );
  }}
