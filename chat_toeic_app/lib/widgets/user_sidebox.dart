import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/theme/app_colors.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';

class UserSideBox extends StatelessWidget {
  const UserSideBox({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Obx(() {
        final isLoggedIn = authController.isLoggedIn.value;
        final user = authController.user.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white10,
              backgroundImage: user?['avatar_url'] != null 
                  ? NetworkImage(user!['avatar_url']) 
                  : null,
              child: user?['avatar_url'] == null 
                  ? const Icon(Icons.person, size: 40, color: Colors.white24)
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Status
            Text(
              isLoggedIn ? (user?['username'] ?? 'User') : 'Chưa đăng nhập',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Reminder
            const Text(
              'Bạn chưa tạo mục tiêu cho quá trình luyện thi của mình',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tạo ngay',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed('/statistics'),
                icon: const Icon(Icons.bar_chart, size: 20),
                label: const Text('THỐNG KÊ KẾT QUẢ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
