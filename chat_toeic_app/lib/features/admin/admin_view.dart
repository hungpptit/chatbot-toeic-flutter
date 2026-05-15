import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/features/admin/course_list_panel.dart';
import 'package:chat_toeic_app/features/admin/user_list_panel.dart';
import 'package:chat_toeic_app/features/admin/part_list_panel.dart';
import 'package:chat_toeic_app/features/admin/type_list_panel.dart';
import 'package:chat_toeic_app/features/admin/skill_list_panel.dart';
import 'package:chat_toeic_app/features/admin/test_list_panel.dart';

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

    final isMobile = MediaQuery.of(context).size.width < 800;
    final collapsed = isSidebarCollapsed;

    // Auto trigger fetch if user data is missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.user.value == null && !authController.isLoading.value) {
        authController.fetchUserProfile();
      }
    });
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: _buildSidebar(false, isDrawer: true, isMobile: isMobile),
      ) : null,
      body: Column(
        children: [
          // Top Navigation Bar
          _buildTopNav(user, isMobile: isMobile),
          
          // Main Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Sidebar - Hidden on mobile
                if (!isMobile) _buildSidebar(collapsed, isMobile: isMobile),
                
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
                                    ] else if (activeAdminContent == 'exams') ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TestListPanel(),
                          ),
                                    ] else if (activeAdminContent == 'users') ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: UserListPanel(),
                          ),
                        ],

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

  Widget _buildTopNav(Map<String, dynamic>? user, {bool isMobile = false}) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )),
            const SizedBox(width: 8),
          ],
          const Text(
            'Chatbot TOEIC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 48),
            // Nav Items
            _buildTopNavItem('Trang chủ', false, route: '/home'),
            const SizedBox(width: 12),
            _buildTopNavItem('Tra từ vựng', false, route: '/vocabulary'),
            const SizedBox(width: 12),
            _buildTopNavItem('Chat TOEIC', false, route: '/chatbot'),
          ],
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
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Text(
                    user?['username'] ?? 'phanhung',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white54),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSubItemSelected(String title, String parentTitle) {
    if (parentTitle == 'Quản lý người dùng') {
      if (title == 'Danh sách') return activeAdminContent == 'users';
      if (title == 'Chức năng khác') return activeAdminContent == 'users_manage';
    } else if (parentTitle == 'Quản lý chung') {
      if (title == 'Danh sách khóa học') return activeAdminContent == 'courses';
      if (title == 'Danh sách part') return activeAdminContent == 'parts';
      if (title == 'Danh sách type') return activeAdminContent == 'types';
      if (title == 'Danh sách skill') return activeAdminContent == 'skills';
    } else if (parentTitle == 'Quản lý đề thi') {
      if (title == 'Danh sách đề') return activeAdminContent == 'exams';
      if (title == 'Thêm đề mới') return activeAdminContent == 'exams_add';
    }
    return false;
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



  Widget _buildSidebar(bool collapsed, {bool isDrawer = false, bool isMobile = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 80 : 280,
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
              child: collapsed
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
                      if (!isDrawer)
                        IconButton(
                          onPressed: () => setState(() => isSidebarCollapsed = !isSidebarCollapsed),
                          icon: const Icon(Icons.menu_open, color: Colors.white70),
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: 16),
            
            const SizedBox(height: 8),
            // General Navigation (Only on Mobile Sidebar)
            if (isMobile) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Divider(color: Colors.white10),
              ),
              _buildSidebarItem(
                Icons.home_outlined, 
                'Trang chủ', 
                collapsed: collapsed,
                onTap: () => Get.toNamed('/home'),
              ),
              _buildSidebarItem(
                Icons.translate_outlined, 
                'Tra từ vựng', 
                collapsed: collapsed,
                onTap: () => Get.toNamed('/vocabulary'),
              ),
              _buildSidebarItem(
                Icons.chat_outlined, 
                'Chat TOEIC', 
                collapsed: collapsed,
                onTap: () => Get.toNamed('/chatbot'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Divider(color: Colors.white10),
              ),
            ],

            // Menu Items
            _buildExpandableSidebarItem(
              Icons.people_outline, 
              'Quản lý người dùng', 
              ['Danh sách', 'Chức năng khác'],
              collapsed: collapsed,
            ),
            _buildExpandableSidebarItem(
              Icons.quiz_outlined, 
              'Quản lý đề thi', 
              ['Danh sách đề', 'Thêm đề mới'],
              collapsed: collapsed,
            ),
            _buildExpandableSidebarItem(
              Icons.import_contacts_outlined, 
              'Quản lý chung', 
              ['Danh sách khóa học', 'Danh sách part', 'Danh sách type', 'Danh sách skill'],
              collapsed: collapsed,
            ),
            _buildSidebarItem(
              Icons.analytics_outlined, 
              'Thống kê nhanh', 
              isSelected: activeAdminContent == 'stats',
              collapsed: collapsed,
              onTap: () => setState(() => activeAdminContent = 'stats'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSidebarItem(IconData icon, String title, List<String> subItems, {required bool collapsed}) {
    bool isExpanded = expandedItems[title] ?? false;
    bool isAnyChildSelected = subItems.any((item) => _isSubItemSelected(item, title));

    if (collapsed) {
      return _buildSidebarItem(icon, title, isSelected: isAnyChildSelected, collapsed: collapsed);
    }

    return Column(
      children: [
        _buildSidebarItem(
          icon, 
          title, 
          isSelected: isAnyChildSelected, 
          isExpandable: true, 
          isExpanded: isExpanded,
          collapsed: collapsed,
          onTap: () {
            setState(() {
              expandedItems[title] = !isExpanded;
            });
          }
        ),
        if (isExpanded)
          ...subItems.map((subItem) => _buildSubItem(subItem, parentTitle: title, collapsed: collapsed)),
      ],
    );
  }

  Widget _buildSubItem(String title, {required String parentTitle, required bool collapsed}) {
    bool isSelected = _isSubItemSelected(title, parentTitle);
    return Container(
      margin: const EdgeInsets.only(left: 54, right: 16, bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            if (parentTitle == 'Quản lý người dùng') {
              if (title == 'Danh sách') {
                activeAdminContent = 'users';
              } else if (title == 'Chức năng khác') {
                activeAdminContent = 'users_manage';
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
              }
            } else if (parentTitle == 'Quản lý đề thi') {
              if (title == 'Danh sách đề') {
                activeAdminContent = 'exams';
              } else if (title == 'Thêm đề mới') {
                activeAdminContent = 'exams_add';
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)) : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    required bool collapsed,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 16, 
        vertical: 4
      ),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 16, 
            vertical: 12
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)) : null,
          ),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon, 
                color: isSelected ? const Color(0xFF6366F1) : Colors.white60, 
                size: 22
              ),
              if (!collapsed) ...[
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
