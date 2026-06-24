import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/widgets/nav_bar.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Auto trigger fetch if user data is missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.user.value == null && !authController.isLoading.value) {
        authController.fetchUserProfile();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          const CustomNavBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Profile Header Card
                      Obx(() {
                        final user = authController.user.value;
                        final isLoading = authController.isLoading.value;

                        if (isLoading && user == null) {
                          return const Column(
                            children: [
                              SizedBox(height: 100),
                              CircularProgressIndicator(color: Color(0xFF6366F1)),
                              SizedBox(height: 16),
                              Text('Đang tải thông tin...', style: TextStyle(color: Colors.white70)),
                            ],
                          );
                        }

                        if (user == null) {
                          return Column(
                            children: [
                              const SizedBox(height: 100),
                              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 16),
                              const Text('Không thể tải thông tin người dùng', 
                                  style: TextStyle(color: Colors.white, fontSize: 18)),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => authController.fetchUserProfile(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            // Avatar
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white24, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: user['avatar'] != null
                                    ? Image.network(user['avatar'], fit: BoxFit.cover)
                                    : const Icon(Icons.person, size: 60, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Name
                            Text(
                              user['username'] ?? 'Người dùng',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email
                            Text(
                              user['email'] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    Icons.badge_outlined, 
                                    'User ID', 
                                    '#${user['id']}'
                                  ),
                                  const Divider(height: 32, color: Colors.white10),
                                  _buildInfoRow(
                                    Icons.admin_panel_settings_outlined, 
                                    'Vai trò', 
                                    user['role_id'] == 2 ? 'Quản trị viên' : 'Thành viên',
                                    trailing: user['role_id'] == 2 
                                      ? InkWell(
                                          onTap: () => Get.toNamed('/admin'),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Admin Panel', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF6366F1)),
                                              ],
                                            ),
                                          ),
                                        )
                                      : null,
                                  ),
                                  const Divider(height: 32, color: Colors.white10),
                                  _buildInfoRow(
                                    Icons.bar_chart_outlined, 
                                    'Học tập', 
                                    'Thống kê kết quả',
                                    trailing: InkWell(
                                      onTap: () => Get.toNamed('/statistics'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Xem thống kê', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF10B981)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 32, color: Colors.white10),
                                  _buildInfoRow(
                                    Icons.lock_outline, 
                                    'Mật khẩu', 
                                    '********',
                                    trailing: TextButton(
                                      onPressed: () => _showChangePasswordDialog(context, authController),
                                      child: const Text('Đổi mật khẩu', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Action Buttons
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => authController.logout(),
                                icon: const Icon(Icons.logout),
                                label: const Text('Đăng xuất'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent, width: 1),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthController authController) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currentPasswordError = RxnString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Đổi mật khẩu',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Obx(() => TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      errorText: currentPasswordError.value,
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
                    onChanged: (_) {
                      if (currentPasswordError.value != null) {
                        currentPasswordError.value = null;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mật khẩu hiện tại';
                      }
                      return null;
                    },
                  )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
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
                        return 'Vui lòng nhập mật khẩu mới';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải từ 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
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
                      if (value != newPasswordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            Obx(() {
              final isBtnLoading = authController.isLoading.value;
              return ElevatedButton(
                onPressed: isBtnLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    currentPasswordError.value = null;
                    final errorMsg = await authController.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    if (errorMsg == null) {
                      Get.back(); // Close change password dialog
                      
                      // Show success notification popup
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                                SizedBox(width: 12),
                                Text('Thành công', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: const Text(
                              'Đổi mật khẩu tài khoản của bạn đã được cập nhật thành công.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Đồng ý', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (errorMsg.contains('không chính xác') || errorMsg.contains('incorrect')) {
                      currentPasswordError.value = 'Mật khẩu hiện tại không chính xác';
                    } else {
                      Get.snackbar(
                        'Đổi mật khẩu thất bại',
                        errorMsg,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isBtnLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }
}
