import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/user_controller.dart';

class UserListPanel extends StatefulWidget {
  const UserListPanel({super.key});

  @override
  State<UserListPanel> createState() => _UserListPanelState();
}

class _UserListPanelState extends State<UserListPanel> {
  final int pageSize = 10;
  int page = 1;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
      }

      final users = controller.users;

      return Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Quản lý người dùng', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                SizedBox(width: 48, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 2, child: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                SizedBox(width: 140, child: Text('Hành động', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // List
          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('Không có người dùng', style: TextStyle(color: Colors.white60)))
                : ListView.separated(
                    itemCount: (() {
                      final total = users.length;
                      final start = (page - 1) * pageSize;
                      if (start >= total) return 0;
                      final remaining = total - start;
                      return remaining >= pageSize ? pageSize : remaining;
                    })(),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final start = (page - 1) * pageSize;
                      final u = users[start + idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                        child: Row(
                          children: [
                            SizedBox(width: 48, child: Text('${u['id'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                            Expanded(flex: 2, child: Text('${u['username'] ?? u['name'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(flex: 3, child: Text('${u['email'] ?? '-'}', style: const TextStyle(color: Colors.white70))),
                            SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // View
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: Text('Người dùng #${u['id']}: ${u['username'] ?? u['name']}', style: const TextStyle(color: Colors.white)),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('ID: ${u['id'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                                                const SizedBox(height: 8),
                                                Text('Tên: ${u['username'] ?? u['name'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                                                const SizedBox(height: 8),
                                                Text('Email: ${u['email'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                                                const SizedBox(height: 8),
                                                Text('Role: ${u['role_id'] ?? ''}', style: const TextStyle(color: Colors.white60)),
                                              ],
                                            ),
                                          ),
                                          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng'))],
                                        ),
                                      );
                                    },
                                    child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFFFD54F), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.remove_red_eye, color: Color(0xFF0B1220), size: 18)),
                                  ),

                                  // Edit
                                  InkWell(
                                    onTap: () async {
                                      final nameCtrl = TextEditingController(text: u['username'] ?? u['name'] ?? '');
                                      final emailCtrl = TextEditingController(text: u['email'] ?? '');
                                      final result = await showDialog<Map<String, String>?>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Chỉnh sửa người dùng', style: TextStyle(color: Colors.white)),
                                          content: Column(mainAxisSize: MainAxisSize.min, children: [
                                            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Tên', hintStyle: TextStyle(color: Colors.white38))),
                                            const SizedBox(height: 8),
                                            TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Email', hintStyle: TextStyle(color: Colors.white38))),
                                          ]),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Hủy')),
                                            ElevatedButton(onPressed: () => Navigator.of(ctx).pop({'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim()}), child: const Text('Lưu')),
                                          ],
                                        ),
                                      );

                                      if (result != null) {
                                        final updated = await controller.updateUser(u['id'], {'username': result['name'], 'email': result['email']});
                                        if (updated != null) Get.snackbar('Thành công', 'Đã cập nhật người dùng');
                                      }
                                    },
                                    child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF9CA3AF), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit, color: Color(0xFF0B1220), size: 18)),
                                  ),

                                  // Delete
                                  InkWell(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Xóa người dùng', style: TextStyle(color: Colors.white)),
                                          content: const Text('Bạn có chắc muốn xóa người dùng này?', style: TextStyle(color: Colors.white60)),
                                          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa'))],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final ok = await controller.deleteUser(u['id']);
                                        if (ok) Get.snackbar('Thành công', 'Đã xóa người dùng');
                                      }
                                    },
                                    child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.delete, color: Colors.white, size: 18)),
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
            final total = users.length;
            final totalPages = total == 0 ? 1 : (total / pageSize).ceil();
            final currentPage = page > totalPages ? totalPages : page;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentPage > 1 ? () => setState(() => page = currentPage - 1) : null,
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
                Text('Trang $currentPage / $totalPages', style: const TextStyle(color: Colors.white70)),
                IconButton(
                  onPressed: currentPage < totalPages ? () => setState(() => page = currentPage + 1) : null,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                ),
              ],
            );
          }),
        ],
      );
    });
  }
}
