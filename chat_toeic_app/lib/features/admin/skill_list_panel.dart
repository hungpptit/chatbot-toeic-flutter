import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/skill_controller.dart';
import 'package:chat_toeic_app/widgets/admin_action_button.dart';

class SkillListPanel extends StatefulWidget {
  const SkillListPanel({super.key});

  @override
  State<SkillListPanel> createState() => _SkillListPanelState();
}

class _SkillListPanelState extends State<SkillListPanel> {
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
    final controller = Get.put(SkillController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
      }

      final skills = controller.filteredSkills;

      if (skills.isEmpty && controller.searchQuery.isEmpty) {
        return const Center(child: Text('Không có Skill nào', style: TextStyle(color: Colors.white60)));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Quản lý Skill', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final TextEditingController nameCtrl = TextEditingController();
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('Thêm Skill mới', style: TextStyle(color: Colors.white)),
                        content: TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Tên Skill', hintStyle: TextStyle(color: Colors.white38))),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('Tạo'))],
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      final created = await controller.createSkill(result);
                      if (created != null) Get.snackbar('Thành công', 'Đã tạo Skill');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm Skill'),
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
                hintText: 'Tìm kiếm tên Skill...',
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

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final tableWidth = isMobile ? 600.0 : constraints.maxWidth;
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: isMobile ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: const [
                              SizedBox(width: 48, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              Expanded(flex: 3, child: Text('Tên Skill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              SizedBox(width: 140, child: Text('Hành động', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Table Body
                        Expanded(
                          child: skills.isEmpty
                              ? const Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.white38)))
                              : ListView.separated(
                                  itemCount: (() {
                                    final total = skills.length;
                                    final currentPage = page > 0 ? page : 1;
                                    final start = (currentPage - 1) * pageSize;
                                    if (start >= total) return 0;
                                    final remaining = total - start;
                                    return remaining >= pageSize ? pageSize : remaining;
                                  })(),
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final currentPage = page > 0 ? page : 1;
                                    final start = (currentPage - 1) * pageSize;
                                    final s = skills[start + idx];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 48, child: Text('${s['id'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                                          Expanded(flex: 3, child: Text('${s['name'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                          SizedBox(
                                            width: 140,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                AdminActionButton(
                                                  type: AdminActionButtonType.edit,
                                                  onTap: () async {
                                                    final nameCtrl = TextEditingController(text: s['name'] ?? '');
                                                    final result = await showDialog<String?>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: const Color(0xFF1E293B),
                                                        title: const Text('Sửa Skill', style: TextStyle(color: Colors.white)),
                                                        content: TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Tên Skill', hintStyle: TextStyle(color: Colors.white38))),
                                                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('Lưu'))],
                                                      ),
                                                    );
                                                    if (result != null && result.isNotEmpty) {
                                                      final updated = await controller.updateSkill(s['id'], result);
                                                      if (updated != null) Get.snackbar('Thành công', 'Đã cập nhật Skill');
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
                                                        title: const Text('Xóa Skill', style: TextStyle(color: Colors.white)),
                                                        content: const Text('Bạn có chắc muốn xóa Skill này?', style: TextStyle(color: Colors.white60)),
                                                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa'))],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      final ok = await controller.deleteSkill(s['id']);
                                                      if (ok) Get.snackbar('Thành công', 'Đã xóa Skill');
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          // Compact Pagination
          Builder(builder: (ctx) {
            final total = skills.length;
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
