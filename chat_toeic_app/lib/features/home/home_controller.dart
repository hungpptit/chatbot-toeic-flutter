import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;
  var tests = <Map<String, dynamic>>[].obs;
  var selectedCategory = 'Tất cả'.obs;
  var searchQuery = ''.obs;
  
  // Pagination
  var currentPage = 1.obs;
  var pageSize = 6.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTests();
    
    // Reset page when category or search changes
    ever(selectedCategory, (_) => currentPage.value = 1);
    ever(searchQuery, (_) => currentPage.value = 1);
  }

  Future<void> fetchTests() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/tests');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        tests.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách đề thi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get allFilteredTests {
    return tests.where((test) {
      final matchesSearch = test['title'].toString().toLowerCase().contains(searchQuery.value.toLowerCase());
      final matchesCategory = selectedCategory.value == 'Tất cả' || 
                             (test['tags'] as List).contains(selectedCategory.value);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get paginatedTests {
    final filtered = allFilteredTests;
    final startIndex = (currentPage.value - 1) * pageSize.value;
    final endIndex = startIndex + pageSize.value;
    
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  }

  int get totalPages {
    return (allFilteredTests.length / pageSize.value).ceil();
  }
}
