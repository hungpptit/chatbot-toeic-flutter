import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class PartController extends GetxController {
  var isLoading = false.obs;
  var parts = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  List<Map<String, dynamic>> get filteredParts {
    if (searchQuery.value.isEmpty) return parts;
    return parts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchParts();
  }

  Future<void> fetchParts() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/adminMetadata/parts');
      if (response.statusCode == 200) {
        final raw = response.data;
        List<dynamic> data = [];
        if (raw is List) {
          data = raw;
        } else if (raw is Map && raw['data'] != null) {
          data = raw['data'];
        } else if (raw is Map && raw['items'] != null) {
          data = raw['items'];
        }
        parts.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách Part: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createPart(String name) async {
    try {
      final response = await DioClient.dio.post('/adminMetadata/parts', data: {'name': name});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final created = response.data is Map && response.data['data'] != null ? response.data['data'] : response.data;
        parts.insert(0, created as Map<String, dynamic>);
        parts.refresh();
        return created.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo Part: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updatePart(int id, String name) async {
    try {
      final response = await DioClient.dio.put('/adminMetadata/parts/$id', data: {'name': name});
      if (response.statusCode == 200) {
        final updated = response.data is Map && response.data['data'] != null ? response.data['data'] : response.data;
        final idx = parts.indexWhere((p) => p['id'] == id);
        if (idx != -1) {
          parts[idx] = {...parts[idx], 'name': updated['name'] ?? name};
          parts.refresh();
        }
        return updated.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật Part: $e');
    }
    return null;
  }

  Future<bool> deletePart(int id) async {
    try {
      final response = await DioClient.dio.delete('/adminMetadata/parts/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        parts.removeWhere((p) => p['id'] == id);
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa Part: $e');
    }
    return false;
  }
}
