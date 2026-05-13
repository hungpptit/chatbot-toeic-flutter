import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Same as scaffold background
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // Logo
          const Text(
            'Chatbot TOEIC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48),
          
          // Nav Items
          _buildNavItem('Trang chủ', '/home'),
          _buildNavItem('Tra từ vựng', '/vocabulary'),
          _buildNavItem('Chat TOEIC', '/chatbot'),
          
          const Spacer(),
          
          // Login Button / Profile
          Obx(() => authController.isLoggedIn.value
              ? PopupMenuButton<int>(
                  offset: const Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  color: const Color(0xFF1E293B),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Thông tin', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 1) {
                      Get.toNamed('/profile');
                    } else if (value == 2) {
                      authController.logout();
                    }
                  },
                )
              : ElevatedButton(
                  onPressed: () => Get.toNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Đăng nhập'),
                )),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, String route) {
    // Standardize route checking for web/mobile
    final currentRoute = Get.currentRoute;
    final isSelected = currentRoute == route || currentRoute == '/#$route';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Get.offNamed(route);
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
