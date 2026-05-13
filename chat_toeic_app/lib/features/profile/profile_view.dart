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
                                    Icons.lock_outline, 
                                    'Mật khẩu', 
                                    '********',
                                    trailing: TextButton(
                                      onPressed: () {
                                        Get.snackbar(
                                          'Thông báo', 
                                          'Tính năng đổi mật khẩu đang được phát triển',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: const Color(0xFF1E293B),
                                          colorText: Colors.white,
                                        );
                                      },
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
