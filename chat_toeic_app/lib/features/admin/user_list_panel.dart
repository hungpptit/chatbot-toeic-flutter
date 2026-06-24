import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/user_controller.dart';
import 'package:chat_toeic_app/widgets/admin_action_button.dart';

class UserListPanel extends StatefulWidget {
  const UserListPanel({super.key});

  @override
  State<UserListPanel> createState() => _UserListPanelState();
}

class _UserListPanelState extends State<UserListPanel> {
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
    final controller = Get.put(UserController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
      }

      final usersList = controller.filteredUsers;

      if (usersList.isEmpty && controller.searchQuery.isEmpty) {
        return const Center(child: Text('Không có người dùng nào', style: TextStyle(color: Colors.white60)));
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Quản lý User', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.snackbar('Thông báo', 'Chức năng thêm người dùng đang được phát triển');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Thêm User'),
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
                hintText: 'Tìm kiếm username/email...',
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
                final tableWidth = isMobile ? 800.0 : constraints.maxWidth;
                
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
                              Expanded(flex: 3, child: Text('Username', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              SizedBox(width: 100, child: Text('Role', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              SizedBox(width: 140, child: Text('Hành động', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Table Body
                        Expanded(
                          child: usersList.isEmpty
                              ? const Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.white38)))
                              : ListView.separated(
                                  itemCount: (() {
                                    final total = usersList.length;
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
                                    final u = usersList[start + idx];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 48, child: Text('${u['id'] ?? ''}', style: const TextStyle(color: Colors.white70))),
                                          Expanded(flex: 3, child: Text('${u['username'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                          Expanded(flex: 3, child: Text('${u['email'] ?? '-'}', style: const TextStyle(color: Colors.white70))),
                                          SizedBox(width: 100, child: Center(child: Text('${u['roleId'] == 2 ? 'Admin' : 'User'}', style: TextStyle(color: u['roleId'] == 2 ? const Color(0xFF6366F1) : Colors.white60, fontWeight: FontWeight.bold)))),
                                          SizedBox(
                                            width: 140,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                AdminActionButton(type: AdminActionButtonType.view, onTap: () => _showViewUserDialog(context, u)),
                                                AdminActionButton(type: AdminActionButtonType.edit, onTap: () => _showEditUserDialog(context, controller, u)),
                                                AdminActionButton(
                                                  type: AdminActionButtonType.delete,
                                                  onTap: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        backgroundColor: const Color(0xFF1E293B),
                                                        title: const Text('Xóa User', style: TextStyle(color: Colors.white)),
                                                        content: const Text('Bạn có chắc muốn xóa người dùng này?', style: TextStyle(color: Colors.white60)),
                                                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')), ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa'))],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      final ok = await controller.deleteUser(u['id']);
                                                      if (ok) Get.snackbar('Thành công', 'Đã xóa User');
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
            final total = usersList.length;
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

  void _showViewUserDialog(BuildContext context, Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Thông tin chi tiết người dùng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _buildDetailRow('ID', '${u['id'] ?? ''}'),
                const SizedBox(height: 12),
                _buildDetailRow('Username', '${u['username'] ?? '-'}'),
                const SizedBox(height: 12),
                _buildDetailRow('Email', '${u['email'] ?? '-'}'),
                const SizedBox(height: 12),
                _buildDetailRow('Vai trò', (u['roleId'] == 2 || u['role_id'] == 2) ? 'Admin' : 'User'),
                const SizedBox(height: 12),
                _buildDetailRow('Trạng thái', u['status'] == false ? 'Đã khóa' : 'Hoạt động'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showEditUserDialog(BuildContext context, UserController controller, Map<String, dynamic> u) {
    final usernameController = TextEditingController(text: u['username'] ?? '');
    final emailController = TextEditingController(text: u['email'] ?? '');
    int selectedRoleId = u['roleId'] ?? u['role_id'] ?? 1;
    bool isLocked = u['status'] == false;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Chỉnh sửa người dùng',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedRoleId,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Vai trò (Role)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('User'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: isSaving ? null : (val) {
                          if (val != null) {
                            setState(() {
                              selectedRoleId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Khóa tài khoản', style: TextStyle(color: Colors.white, fontSize: 14)),
                        value: isLocked,
                        activeColor: const Color(0xFF6366F1),
                        contentPadding: EdgeInsets.zero,
                        onChanged: isSaving ? null : (val) {
                          setState(() {
                            isLocked = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isSaving = true;
                      });
                      
                      try {
                        final updatedUser = await controller.updateUser(
                          u['id'],
                          {
                            'username': usernameController.text,
                            'email': emailController.text,
                            'role_id': selectedRoleId,
                            'status': !isLocked, // active if not locked
                          },
                        );
                        
                        if (updatedUser != null) {
                          Navigator.of(context).pop(); // Close edit dialog
                          Get.snackbar(
                            'Thành công',
                            'Cập nhật thông tin người dùng thành công',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green.withOpacity(0.8),
                            colorText: Colors.white,
                          );
                        } else {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      } catch (e) {
                        setState(() {
                          isSaving = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
