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
    final List<String> categories = [
      'Tất cả', 'TOFEL', 'IELTS Academic', 'IELTS General', 
      'TOEIC', 'Digital SAT', 'TOPIK I & II', 'Tiếng Anh THPTQG', 
      'ACT', 'AI-Test', 'Practice - Toeic'
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // Nav Bar
          const CustomNavBar(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Filter + Grid
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thư viện đề thi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Category Tabs
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories.map((cat) => _buildCategoryTab(cat, homeController)).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Search Bar
                            _buildSearchBar(homeController),
                            const SizedBox(height: 32),
                            
                            // Grid
                            Obx(() {
                              if (homeController.isLoading.value) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final tests = homeController.paginatedTests;
                              if (tests.isEmpty) {
                                return const Center(
                                  child: Text('Không tìm thấy đề thi nào', style: TextStyle(color: Colors.white70)),
                                );
                              }
                              
                              return Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      childAspectRatio: 1.4,
                                    ),
                                    itemCount: tests.length,
                                    itemBuilder: (context, index) => ExamCard(test: tests[index]),
                                  ),
                                  const SizedBox(height: 32),
                                  _buildPagination(homeController),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 32),
                      
                      // Right Column: Sidebox
                      const UserSideBox(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String title, HomeController controller) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == title;
      return GestureDetector(
        onTap: () => controller.selectedCategory.value = title,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryStart : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryStart : Colors.white10,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchBar(HomeController controller) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Nhập tên đề thi...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white24),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Tìm kiếm'),
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
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
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: controller.currentPage.value > 1 
                ? () => controller.currentPage.value-- 
                : null,
          ),
          ...List.generate(total, (index) {
            final page = index + 1;
            final isSelected = controller.currentPage.value == page;
            return GestureDetector(
              onTap: () => controller.currentPage.value = page,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryStart : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: controller.currentPage.value < total 
                ? () => controller.currentPage.value++ 
                : null,
          ),
        ],
      );
    });
  }
}
