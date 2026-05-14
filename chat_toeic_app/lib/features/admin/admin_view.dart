import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/features/admin/course_list_panel.dart';
import 'package:chat_toeic_app/features/admin/user_list_panel.dart';
import 'package:chat_toeic_app/features/admin/part_list_panel.dart';
import 'package:chat_toeic_app/features/admin/type_list_panel.dart';
import 'package:chat_toeic_app/features/admin/skill_list_panel.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  bool isSidebarCollapsed = false;
  late Map<String, bool> expandedItems;

  @override
  void initState() {
    super.initState();
    expandedItems = {};
  }

  String? activeAdminContent; // null = default empty dashboard

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.user.value;

    // Auto trigger fetch if user data is missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.user.value == null && !authController.isLoading.value) {
        authController.fetchUserProfile();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // System background
      body: Column(
        children: [
          // Top Navigation Bar
          _buildTopNav(user),
          
          // Main Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Sidebar
                _buildSidebar(),
                
                // Main Content Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // System surface
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Either show default placeholder or the selected admin panel
                        if (activeAdminContent == null) ...[
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.dashboard_customize_outlined, size: 64, color: Colors.white10),
                                SizedBox(height: 16),
                                Text(
                                  'Nội dung quản trị sẽ hiển thị ở đây',
                                  style: TextStyle(color: Colors.white24, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ] else if (activeAdminContent == 'courses') ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CourseListPanel(),
                          ),
                                    ] else if (activeAdminContent == 'parts') ...[
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: PartListPanel(),
                                      ),
                                    ] else if (activeAdminContent == 'types') ...[
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: TypeListPanel(),
                                      ),
                                    ] else if (activeAdminContent == 'skills') ...[
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: SkillListPanel(),
                                      ),
                                    ] else if (activeAdminContent == 'users') ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: UserListPanel(),
                          ),
                        ],

                        // Floating Cloud Icon (Bottom Right)
                        Positioned(
                          bottom: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.wb_cloudy_outlined, color: Color(0xFF6366F1), size: 24),
                          ),
                        ),
                      ],
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

  Widget _buildTopNav(Map<String, dynamic>? user) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
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
          _buildTopNavItem('Trang chủ', false, route: '/home'),
          const SizedBox(width: 12),
          _buildTopNavItem('Tra từ vựng', false, route: '/vocabulary'),
          const SizedBox(width: 12),
          _buildTopNavItem('Chat TOEIC', false, route: '/chatbot'),
          const Spacer(),
          // User Profile Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Get.toNamed('/profile');
              } else if (value == 'logout') {
                Get.find<AuthController>().logout();
              }
            },
            offset: const Offset(0, 50),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Thông tin', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  user?['username'] ?? 'phanhung',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavItem(String title, bool isActive, {String? route}) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Get.toNamed(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }



  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Sidebar Header (Title + Collapse)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isSidebarCollapsed 
                ? IconButton(
                    onPressed: () => setState(() => isSidebarCollapsed = !isSidebarCollapsed),
                    icon: const Icon(Icons.menu, color: Colors.white70),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'ADMIN PANEL',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => isSidebarCollapsed = !isSidebarCollapsed),
                        icon: const Icon(Icons.menu_open, color: Colors.white70),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 16),
            
            const SizedBox(height: 8),
            // Menu Items
            _buildExpandableSidebarItem(
              Icons.people_outline, 
              'Quản lý người dùng', 
              ['Danh sách', 'Chức năng khác']
            ),
            _buildExpandableSidebarItem(
              Icons.quiz_outlined, 
              'Quản lý đề thi', 
              ['Danh sách đề', 'Thêm đề mới']
            ),
            _buildExpandableSidebarItem(
              Icons.import_contacts_outlined, 
              'Quản lý chung', 
              ['Danh sách khóa học', 'Danh sách part', 'Danh sách type', 'Danh sách skill']
            ),
            _buildSidebarItem(Icons.analytics_outlined, 'Thống kê nhanh', isSelected: false),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSidebarItem(IconData icon, String title, List<String> subItems) {
    bool isExpanded = expandedItems[title] ?? false;

    if (isSidebarCollapsed) {
      return _buildSidebarItem(icon, title);
    }

    return Column(
      children: [
        _buildSidebarItem(
          icon, 
          title, 
          isExpandable: true, 
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              expandedItems[title] = !isExpanded;
            });
          }
        ),
        if (isExpanded)
          ...subItems.map((subItem) => _buildSubItem(subItem, parentTitle: title)),
      ],
    );
  }

  Widget _buildSubItem(String title, {required String parentTitle}) {
    return Container(
      margin: const EdgeInsets.only(left: 54, right: 16, bottom: 4),
      child: InkWell(
        onTap: () {
          // Hiển thị trực tiếp trong panel phải thay vì chuyển route
          setState(() {
            if (parentTitle == 'Quản lý người dùng') {
              if (title == 'Danh sách') {
                activeAdminContent = 'users';
              } else if (title == 'Chức năng khác') {
                activeAdminContent = 'users_manage';
              } else {
                activeAdminContent = null;
              }
            } else if (parentTitle == 'Quản lý chung') {
              if (title == 'Danh sách khóa học') {
                activeAdminContent = 'courses';
              } else if (title == 'Danh sách part') {
                activeAdminContent = 'parts';
              } else if (title == 'Danh sách type') {
                activeAdminContent = 'types';
              } else if (title == 'Danh sách skill') {
                activeAdminContent = 'skills';
              } else if (title == 'Thêm / Sửa') {
                activeAdminContent = 'courses_manage';
              } else {
                activeAdminContent = null;
              }
            } else {
              // fallback mapping based on explicit title
              if (title == 'Danh sách khóa học') {
                activeAdminContent = 'courses';
              } else if (title == 'Danh sách part') {
                activeAdminContent = 'parts';
              } else if (title == 'Danh sách type') {
                activeAdminContent = 'types';
              } else if (title == 'Danh sách skill') {
                activeAdminContent = 'skills';
              } else if (title == 'Thêm / Sửa') {
                activeAdminContent = 'courses_manage';
              } else {
                activeAdminContent = null;
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Optional: highlight on hover or selection
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {
    bool isSelected = false, 
    bool isExpandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSidebarCollapsed ? 8 : 16, 
        vertical: 4
      ),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSidebarCollapsed ? 0 : 16, 
            vertical: 12
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon, 
                color: isSelected ? const Color(0xFF6366F1) : Colors.white60, 
                size: 22
              ),
              if (!isSidebarCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                      fontSize: 14
                    ),
                  ),
                ),
                Icon(
                  isExpandable 
                      ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)
                      : Icons.chevron_right, 
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white24, 
                  size: 18
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
