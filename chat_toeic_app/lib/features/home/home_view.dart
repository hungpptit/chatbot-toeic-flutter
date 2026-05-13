import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/theme/app_colors.dart';
import 'package:chat_toeic_app/features/home/home_controller.dart';
import 'package:chat_toeic_app/widgets/nav_bar.dart';
import 'package:chat_toeic_app/widgets/exam_card.dart';
import 'package:chat_toeic_app/widgets/user_sidebox.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.put(HomeController());
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
          
          return Column(
            children: [
              const CustomNavBar(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Content
                    Expanded(
                      flex: 3,
                      child: CustomScrollView(
                        slivers: [
                          // Header Section
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thư viện đề thi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Category Tabs (Filter Chips)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Obx(() => Row(
                                      children: homeController.categories.map((cat) => _buildCategoryTab(cat, homeController)).toList(),
                                    )),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Search Bar
                                  _buildSearchBar(homeController),
                                ],
                              ),
                            ),
                          ),
                          
                          // Grid Section
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                            sliver: Obx(() {
                              if (homeController.isLoading.value) {
                                return const SliverToBoxAdapter(
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              
                              final tests = homeController.paginatedTests;
                              if (tests.isEmpty) {
                                return const SliverToBoxAdapter(
                                  child: Center(
                                    child: Text('Không tìm thấy đề thi nào', style: TextStyle(color: Color(0xFF94A3B8))),
                                  ),
                                );
                              }
                              
                              return SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: 1.1,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => ExamCard(test: tests[index]),
                                  childCount: tests.length,
                                ),
                              );
                            }),
                          ),
                          
                          // Pagination
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 48),
                            sliver: SliverToBoxAdapter(
                              child: _buildPagination(homeController),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Sidebar (Only on large screens)
                    if (!isMobile)
                      Container(
                        width: 320,
                        padding: const EdgeInsets.fromLTRB(0, 32, 24, 32),
                        child: const UserSideBox(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      drawer: MediaQuery.of(context).size.width < 768 ? const Drawer(child: UserSideBox()) : null,
    );
  }

  Widget _buildCategoryTab(String title, HomeController controller) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == title;
      return GestureDetector(
        onTap: () => controller.selectedCategory.value = title,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.05),
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar(HomeController controller) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm đề thi...',
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(HomeController controller) {
    return Obx(() {
      final total = controller.totalPages;
      if (total <= 1) return const SizedBox.shrink();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left,
            onPressed: controller.currentPage.value > 1 
                ? () => controller.currentPage.value-- 
                : null,
          ),
          const SizedBox(width: 8),
          ...List.generate(total, (index) {
            final page = index + 1;
            final isSelected = controller.currentPage.value == page;
            return GestureDetector(
              onTap: () => controller.currentPage.value = page,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _buildPageButton(
            icon: Icons.chevron_right,
            onPressed: controller.currentPage.value < total 
                ? () => controller.currentPage.value++ 
                : null,
          ),
        ],
      );
    });
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: onPressed != null ? Colors.white : Colors.white24, size: 20),
      ),
    );
  }
}
