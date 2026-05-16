import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class TypeController extends GetxController {
  var isLoading = false.obs;
  var types = <Map<String, dynamic>>[].obs;
  var searchQuery = ''.obs;

  List<Map<String, dynamic>> get filteredTypes {
    if (searchQuery.value.isEmpty) return types;
    return types.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchTypes();
  }

  Future<void> fetchTypes() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/adminMetadata/types');
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
        types.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách Type: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createType(String name) async {
    try {
      final response = await DioClient.dio.post('/adminMetadata/types', data: {'name': name});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final created = response.data is Map && response.data['data'] != null ? response.data['data'] : response.data;
        types.insert(0, created as Map<String, dynamic>);
        types.refresh();
        return created.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo Type: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateType(int id, String name) async {
    try {
      final response = await DioClient.dio.put('/adminMetadata/types/$id', data: {'name': name});
      if (response.statusCode == 200) {
        final updated = response.data is Map && response.data['data'] != null ? response.data['data'] : response.data;
        final idx = types.indexWhere((t) => t['id'] == id);
        if (idx != -1) {
          types[idx] = {...types[idx], 'name': updated['name'] ?? name};
          types.refresh();
        }
        return updated.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật Type: $e');
    }
    return null;
  }

  Future<bool> deleteType(int id) async {
    try {
      final response = await DioClient.dio.delete('/adminMetadata/types/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        types.removeWhere((t) => t['id'] == id);
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa Type: $e');
    }
    return false;
  }
}
