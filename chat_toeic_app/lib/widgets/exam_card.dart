import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/theme/app_colors.dart';
import 'package:chat_toeic_app/features/test/test_detail_view.dart';
import 'package:chat_toeic_app/features/test/test_history_view.dart';
import 'package:chat_toeic_app/features/test/test_history_view.dart';

class ExamCard extends StatelessWidget {
  final Map<String, dynamic> test;

  const ExamCard({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Padding for the main info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  test['title'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Info Row
                Row(
                  children: [
                    _buildIconInfo(Icons.access_time, test['duration'] ?? '--'),
                    const SizedBox(width: 16),
                    _buildIconInfo(Icons.people_outline, '${test['participants'] ?? 0}'),
                    const SizedBox(width: 16),
                    _buildIconInfo(Icons.chat_bubble_outline, '${test['comments'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Secondary Info
                Text(
                  '${test['questions'] ?? 0} câu hỏi',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        final testId = test['id'];
                        if (testId != null) {
                          Get.to(() => TestDetailView(testId: testId));
                        } else {
                          ScaffoldMessenger.of(Get.context!).showSnackBar(
                            const SnackBar(content: Text('Không thể xác định bài thi')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Làm bài',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () {
                        final testId = test['id'];
                        if (testId != null) {
                          Navigator.of(Get.context!, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => TestHistoryView(testId: testId),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(Get.context!).showSnackBar(
                            const SnackBar(content: Text('Không thể xác định bài thi')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        foregroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Kết quả',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
