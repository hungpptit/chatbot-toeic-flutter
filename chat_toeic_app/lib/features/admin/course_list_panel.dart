import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/course_controller.dart';
import 'package:chat_toeic_app/widgets/admin_action_button.dart';

class CourseListPanel extends StatefulWidget {
  const CourseListPanel({super.key});

  @override
  State<CourseListPanel> createState() => _CourseListPanelState();
}

class _CourseListPanelState extends State<CourseListPanel> {
  final int pageSize = 10;
  int page = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CourseController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
      }

      final courses = controller.filteredCourses;

      if (courses.isEmpty && controller.searchQuery.isEmpty) {
        return const Center(
          child: Text('Không có khóa học nào', style: TextStyle(color: Colors.white60)),
        );
      }
      
      return Column(
        children: [
          // Top title + add button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Quản lý khóa học', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final TextEditingController nameCtrl = TextEditingController();
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('Thêm khóa học mới', style: TextStyle(color: Colors.white)),
                        content: TextField(
                          controller: nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Tên khóa học', hintStyle: TextStyle(color: Colors.white38)),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')),
                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('Tạo')),
                        ],
                      ),
                    );

                    if (result != null && result.isNotEmpty) {
                      final created = await controller.createCourse(result);
                      if (created != null) {
                        Get.snackbar('Thành công', 'Đã tạo khóa học');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm khóa học mới'),
                ),
              ],
            ),
          ),
          
          // Search box moved to top
          Container(
            width: double.infinity,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                debounce(controller.searchQuery, (_) {}, time: const Duration(milliseconds: 500));
                controller.searchQuery.value = val;
                setState(() => page = 1);
              },
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khóa học...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
                filled: true,
                fillColor: const Color(0xFF0B1220),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
              ),
            ),
          ),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                SizedBox(width: 48, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 2, child: Text('Tên khóa học', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 4, child: Text('Bài test', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                SizedBox(width: 140, child: Text('Hành động', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: courses.isEmpty
                ? const Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.white38)))
                : ListView.separated(
                    itemCount: (() {
                      final total = courses.length;
                      final currentPage = page > 0 ? page : 1;
                      final start = (currentPage - 1) * pageSize;
                      if (start >= total) return 0;
                      final remaining = total - start;
                      return remaining >= pageSize ? pageSize : remaining;
                    })(),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final currentPage = page > 0 ? page : 1;
                      final start = (currentPage - 1) * pageSize;
                      final course = courses[start + index];
                      final tests = (course['tests'] as List<dynamic>?) ?? [];

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1220),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 48, child: Text('${course['id'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                            Expanded(
                              flex: 2,
                              child: Text('${course['name'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: tests.isEmpty
                                    ? [const Text('Hiện tại chưa có bài test', style: TextStyle(color: Colors.white60))]
                                    : tests.map<Widget>((t) {
                                        final title = t['title'] ?? t['name'] ?? '';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            title,
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        );
                                      }).toList(),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  AdminActionButton(
                                    type: AdminActionButtonType.edit,
                                    onTap: () async {
                                      final TextEditingController nameCtrl = TextEditingController(text: course['name'] ?? '');
                                      final result = await showDialog<String?>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Cập nhật khóa học', style: TextStyle(color: Colors.white)),
                                          content: TextField(
                                            controller: nameCtrl,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: const InputDecoration(
                                              hintText: 'Tên khóa học mới',
                                              hintStyle: TextStyle(color: Colors.white38),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')),
                                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('Cập nhật')),
                                          ],
                                        ),
                                      );

                                      if (result != null && result.isNotEmpty && result != course['name']) {
                                        final updated = await controller.updateCourseName(course['id'], result);
                                        if (updated != null) {
                                          Get.snackbar('Thành công', 'Đã cập nhật khóa học');
                                        }
                                      }
                                    },
                                  ),
                                  AdminActionButton(
                                    type: AdminActionButtonType.delete,
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Xóa khóa học', style: TextStyle(color: Colors.white)),
                                          content: const Text('Bạn có chắc muốn xóa khóa học này?', style: TextStyle(color: Colors.white60)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
                                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final ok = await controller.deleteCourse(course['id']);
                                        if (ok) Get.snackbar('Thành công', 'Đã xóa khóa học');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          // Pagination controls
          Builder(builder: (ctx) {
            final total = courses.length;
            final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
            final currentPage = page > totalPages ? totalPages : page;
            return Container(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPage > 1 ? () => setState(() => page = currentPage - 1) : null,
                    icon: Icon(Icons.arrow_back, size: 18, color: currentPage > 1 ? Colors.white70 : Colors.white24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text('Trang $currentPage / $totalPages', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: currentPage < totalPages ? () => setState(() => page = currentPage + 1) : null,
                    icon: Icon(Icons.arrow_forward, size: 18, color: currentPage < totalPages ? Colors.white70 : Colors.white24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }
}
