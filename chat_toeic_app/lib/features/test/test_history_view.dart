import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestHistoryView extends StatefulWidget {
  final int testId;

  const TestHistoryView({super.key, required this.testId});

  @override
  State<TestHistoryView> createState() => _TestHistoryViewState();
}

class _TestHistoryViewState extends State<TestHistoryView> {
  late final Future<List<Map<String, dynamic>>> _historyFuture;

  Future<int> _fetchTotalQuestions() async {
    try {
      final response = await DioClient.dio.get('/v1/tests/${widget.testId}/questions');
      final dynamic rawData = response.data['data'] ?? response.data;
      if (rawData is List) {
        return rawData.length;
      }
      if (rawData is Map && rawData['questions'] is List) {
        return (rawData['questions'] as List).length;
      }
    } catch (_) {
      // Keep fallback below if this endpoint is unavailable.
    }
    return 50;
  }

  int _safeExtractInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) {
      if (value.containsKey('testId')) return _safeExtractInt(value['testId']);
      if (value.containsKey('id')) return _safeExtractInt(value['id']);
      if (value.isNotEmpty) return _safeExtractInt(value.values.first);
    }
    return 0;
  }

  String _safeExtractString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final totalQuestions = await _fetchTotalQuestions();
    final response = await DioClient.dio.get('/v1/tests/${widget.testId}/attempts/history');
    final dynamic rawData = response.data['data'] ?? response.data;

    List<Map<String, dynamic>> normalizeList(List<dynamic> input) {
      return input
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
            final status = _safeExtractString(item['status']);
            final rawScore = _safeExtractString(item['score']);
            int correct = 0;
            if (rawScore.contains('/')) {
              final parts = rawScore.split('/');
              correct = int.tryParse(parts.first.trim()) ?? 0;
            } else {
              correct = int.tryParse(rawScore.trim()) ?? 0;
            }

            return {
              ...item,
              'displayScore': '$correct/$totalQuestions',
              'displayStatus': status == 'cancelled'
                  ? 'Đã hủy'
                  : status == 'canceled'
                    ? 'Đã hủy'
                      : status == 'completed'
                          ? 'Đã hoàn thành'
                          : 'Đang làm',
            };
          })
          .toList();
    }

    if (rawData is List) {
      return normalizeList(rawData);
    }

    if (rawData is Map && rawData['data'] is List) {
      return normalizeList(rawData['data'] as List);
    }

    return [];
  }

  String _formatDuration(String value) {
    if (value.isEmpty) return '00:00:00';
    final parts = value.split(':');
    if (parts.length == 3) {
      return value;
    }
    return '00:00:00';
  }

  void _openReview(Map<String, dynamic> item) {
    final status = _safeExtractString(item['status']);
    if (status != 'completed') {
      Get.snackbar(
        'Không thể xem chi tiết',
        'Bài này đang ở trạng thái ${_safeExtractString(item['displayStatus'])}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
      );
      return;
    }

    final attemptId = _safeExtractString(item['userTestId']);
    if (attemptId.isEmpty) return;

    Get.toNamed(
      '/test-answer-details',
      arguments: {
        'testId': widget.testId,
        'attemptId': attemptId,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📚 [TestHistoryView] initState(testId=${widget.testId})');
    _historyFuture = _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📚 [TestHistoryView] build(testId=${widget.testId})');
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
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
                      const Text(
                        'Không tải được lịch sử làm bài',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _safeExtractString(snapshot.error),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final history = snapshot.data ?? <Map<String, dynamic>>[];

            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text(
                            'Bạn chưa thực hiện bài thi này',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final displayScore = _safeExtractString(item['displayScore']);
                            final score = displayScore.isNotEmpty ? displayScore : _safeExtractString(item['score']);
                            final date = _safeExtractString(item['date']);
                            final duration = _formatDuration(_safeExtractString(item['duration']));
                            final status = _safeExtractString(item['status']);
                            final displayStatus = _safeExtractString(item['displayStatus']);

                            return InkWell(
                              onTap: status == 'completed' ? () => _openReview(item) : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: status == 'completed' ? const Color(0xFF1E293B) : const Color(0xFF162033),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: status == 'completed' ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.03)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: status == 'completed'
                                            ? const Color(0xFF6366F1).withOpacity(0.12)
                                            : Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        status == 'completed' ? Icons.history : Icons.cancel_outlined,
                                        color: status == 'completed' ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            status == 'completed'
                                                ? 'Lần làm #${history.length - index}'
                                                : 'Lần làm #${history.length - index} · $displayStatus',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          status == 'completed' ? score : displayStatus,
                                          style: TextStyle(
                                            color: status == 'completed' ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          duration,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Lịch sử làm bài',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}