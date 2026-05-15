import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class TestController extends GetxController {
  var isLoading = false.obs;
  var tests = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  List<Map<String, dynamic>> get filteredTests {
    if (searchQuery.value.isEmpty) return tests;
    return tests.where((test) {
      final title = (test['title'] ?? '').toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchTests();
  }

  Future<void> fetchTests() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/tests');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        tests.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách đề thi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteTest(int id) async {
    try {
      final response = await DioClient.dio.delete('/v1/tests/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        tests.removeWhere((t) => t['id'] == id);
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa đề thi: $e');
    }
    return false;
  }
}
