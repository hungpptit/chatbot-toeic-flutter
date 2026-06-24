import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/features/admin/course_list_panel.dart';
import 'package:chat_toeic_app/features/admin/user_list_panel.dart';
import 'package:chat_toeic_app/features/admin/part_list_panel.dart';
import 'package:chat_toeic_app/features/admin/type_list_panel.dart';
import 'package:chat_toeic_app/features/admin/skill_list_panel.dart';
import 'package:chat_toeic_app/features/admin/test_list_panel.dart';
import 'package:chat_toeic_app/features/admin/user_controller.dart';
import 'package:chat_toeic_app/features/admin/test_controller.dart';
import 'package:chat_toeic_app/features/admin/course_controller.dart';
import 'package:chat_toeic_app/features/admin/test_upload_dialog.dart';

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

    // Instantiate controllers for dashboard metrics and operations
    final userController = Get.put(UserController());
    final testController = Get.put(TestController());
    final courseController = Get.put(CourseController());

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
            'Hệ thống Quản trị - Chatbot TOEIC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            // Switch to Student View Button
            OutlinedButton.icon(
              onPressed: () => Get.offAllNamed('/home'),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Giao diện Học viên'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // User Profile Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Get.toNamed('/profile');
              } else if (value == 'student_view') {
                Get.offAllNamed('/home');
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
                value: 'student_view',
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 20, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Giao diện Học viên', style: TextStyle(color: Colors.white, fontSize: 14)),
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
    } else if (parentTitle == 'Quản lý chung') {
      if (title == 'Danh sách khóa học') return activeAdminContent == 'courses';
      if (title == 'Danh sách part') return activeAdminContent == 'parts';
      if (title == 'Danh sách type') return activeAdminContent == 'types';
      if (title == 'Danh sách skill') return activeAdminContent == 'skills';
    } else if (parentTitle == 'Quản lý đề thi') {
      if (title == 'Danh sách đề') return activeAdminContent == 'exams';
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

            // Trang tổng quan (Dashboard)
            _buildSidebarItem(
              Icons.dashboard_outlined, 
              'Trang tổng quan', 
              isSelected: activeAdminContent == null || activeAdminContent == 'dashboard',
              collapsed: collapsed,
              onTap: () => setState(() => activeAdminContent = null),
            ),
            
            // Menu Items
            _buildExpandableSidebarItem(
              Icons.people_outline, 
              'Quản lý người dùng', 
              ['Danh sách'],
              collapsed: collapsed,
            ),
            _buildExpandableSidebarItem(
              Icons.quiz_outlined, 
              'Quản lý đề thi', 
              ['Danh sách đề'],
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
              'Thống kê học tập', 
              isSelected: false,
              collapsed: collapsed,
              onTap: () => Get.toNamed('/statistics'),
            ),

            if (isMobile) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Divider(color: Colors.white10),
              ),
              _buildSidebarItem(
                Icons.swap_horiz, 
                'Giao diện Học viên', 
                collapsed: collapsed,
                onTap: () => Get.offAllNamed('/home'),
              ),
              const SizedBox(height: 24),
            ],
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

  // Beautiful Dashboard View and KPI Cards
  Widget _buildDashboard(UserController userController, TestController testController, CourseController courseController) {
    return Obx(() {
      final totalUsers = userController.users.length;
      final totalTests = testController.tests.length;
      final totalCourses = courseController.courses.length;
      
      final activeUsers = userController.users.where((u) => u['status'] != false).length;
      final adminUsers = userController.users.where((u) => u['roleId'] == 2 || u['role_id'] == 2).length;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hệ thống quản trị',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tổng quan hoạt động',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Refresh Button
                IconButton(
                  onPressed: () {
                    userController.fetchUsers();
                    testController.fetchTests();
                    courseController.fetchCourses();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Tải lại dữ liệu',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Cards Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isMedium = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
                
                return GridView.count(
                  crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.4 : 1.6,
                  children: [
                    _buildKPICard(
                      'Người dùng',
                      '$totalUsers',
                      '$activeUsers hoạt động',
                      Icons.people_alt_outlined,
                      const Color(0xFF6366F1),
                      isLoading: userController.isLoading.value,
                    ),
                    _buildKPICard(
                      'Đề thi TOEIC',
                      '$totalTests',
                      'Đầy đủ các phần thi',
                      Icons.quiz_outlined,
                      const Color(0xFF10B981),
                      isLoading: testController.isLoading.value,
                    ),
                    _buildKPICard(
                      'Khóa học',
                      '$totalCourses',
                      'Phân chia theo cấp độ',
                      Icons.menu_book_outlined,
                      const Color(0xFFF59E0B),
                      isLoading: courseController.isLoading.value,
                    ),
                    _buildKPICard(
                      'Quản trị viên',
                      '$adminUsers',
                      'Quyền quản trị viên',
                      Icons.admin_panel_settings_outlined,
                      const Color(0xFFEC4899),
                      isLoading: userController.isLoading.value,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Main Columns
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWide ? 2 : 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                          _buildActivityChart(),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: _buildRecentActivities(),
                      ),
                    ],
                  ],
                );
              },
            ),
            
            // If not wide screen, show activities below
            if (MediaQuery.of(context).size.width <= 900) ...[
              const SizedBox(height: 24),
              _buildRecentActivities(),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildKPICard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
            )
          else ...[
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành động nhanh',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 450;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    'Tải lên đề thi',
                    Icons.cloud_upload_outlined,
                    const Color(0xFF6366F1),
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const TestUploadDialog(),
                      );
                    },
                    isMobile: isMobile,
                  ),
                  _buildActionButton(
                    'Quản lý đề thi',
                    Icons.quiz_outlined,
                    const Color(0xFF10B981),
                    onTap: () => setState(() => activeAdminContent = 'exams'),
                    isMobile: isMobile,
                  ),
                  _buildActionButton(
                    'Quản lý học viên',
                    Icons.people_alt_outlined,
                    const Color(0xFFF59E0B),
                    onTap: () => setState(() => activeAdminContent = 'users'),
                    isMobile: isMobile,
                  ),
                  _buildActionButton(
                    'Quản lý khóa học',
                    Icons.menu_book_outlined,
                    const Color(0xFFEC4899),
                    onTap: () => setState(() => activeAdminContent = 'courses'),
                    isMobile: isMobile,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, {required VoidCallback onTap, bool isMobile = false}) {
    return SizedBox(
      width: isMobile ? double.infinity : 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lượt làm bài thi 7 ngày qua',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Simulated', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(40, 'Thứ 2'),
                _buildBar(65, 'Thứ 3'),
                _buildBar(95, 'Thứ 4'),
                _buildBar(80, 'Thứ 5'),
                _buildBar(110, 'Thứ 6'),
                _buildBar(140, 'Thứ 7'),
                _buildBar(165, 'Chủ Nhật', isToday: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isToday 
                ? [const Color(0xFF818CF8), const Color(0xFF6366F1)]
                : [const Color(0xFF475569), const Color(0xFF334155)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isToday ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isToday ? Colors.white : Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'title': 'Đề thi mới được tải lên', 'desc': 'TOEIC Practice Test 2026 #Part 5', 'time': '5 phút trước', 'icon': Icons.cloud_upload_outlined, 'color': const Color(0xFF6366F1)},
      {'title': 'Người dùng mới đăng ký', 'desc': 'hoangnam99@gmail.com', 'time': '20 phút trước', 'icon': Icons.person_add_outlined, 'color': const Color(0xFF10B981)},
      {'title': 'Cập nhật khóa học', 'desc': 'Thay đổi tên khóa học "TOEIC 550+"', 'time': '1 giờ trước', 'icon': Icons.edit_outlined, 'color': const Color(0xFFF59E0B)},
      {'title': 'Giao dịch nâng cấp VIP', 'desc': 'Học viên phanhung thanh toán ZaloPay', 'time': '3 giờ trước', 'icon': Icons.payment_outlined, 'color': const Color(0xFFEC4899)},
      {'title': 'Xóa câu hỏi không hợp lệ', 'desc': 'Admin xóa câu hỏi số #124', 'time': '1 ngày trước', 'icon': Icons.delete_outline, 'color': Colors.redAccent},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhật ký hoạt động gần đây',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => Divider(height: 24, color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final act = activities[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (act['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          act['desc'] as String,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          act['time'] as String,
                          style: const TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
