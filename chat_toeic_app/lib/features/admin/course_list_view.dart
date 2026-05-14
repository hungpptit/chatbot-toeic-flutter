import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/course_controller.dart';

class CourseListView extends StatelessWidget {
  const CourseListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CourseController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách khóa học'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        final courses = controller.courses;

        if (courses.isEmpty) {
          return const Center(
            child: Text('Không có khóa học nào', style: TextStyle(color: Colors.white60)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final course = courses[index];
              final tests = (course['tests'] as List<dynamic>?) ?? [];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${course['id'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${course['name'] ?? '-'}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        Text('${tests.length} bài', style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                    if (tests.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: tests.map<Widget>((t) => Chip(
                          label: Text(t['title'] ?? t['name'] ?? '', style: const TextStyle(color: Colors.white70)),
                          backgroundColor: const Color(0xFF0B1220),
                        )).toList(),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
