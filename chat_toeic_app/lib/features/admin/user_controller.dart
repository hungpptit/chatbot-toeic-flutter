import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class UserController extends GetxController {
  var isLoading = false.obs;
  var users = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/adminUser/all');
      if (response.statusCode == 200) {
        final resp = response.data;
        List<dynamic> dataList = [];
        if (resp is List) {
          dataList = resp;
        } else if (resp is Map && resp['data'] is List) {
          dataList = resp['data'];
        } else if (resp is Map && resp['users'] is List) {
          dataList = resp['users'];
        } else {
          // Unexpected shape
          Get.snackbar('Lỗi', 'Dữ liệu trả về không đúng định dạng: ${resp.runtimeType}');
          return;
        }

        users.value = dataList.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách người dùng: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> payload) async {
    try {
      // Creation may be handled by public users endpoint
      final response = await DioClient.dio.post('/v1/users', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final created = response.data['data'] ?? response.data;
        final Map<String, dynamic> createdMap = created as Map<String, dynamic>;
        users.insert(0, createdMap);
        users.refresh();
        return createdMap;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo người dùng: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateUser(dynamic id, Map<String, dynamic> payload) async {
    try {
      // Admin route expects body with userId and fields
      final userId = id is String ? int.tryParse(id) ?? id : id;
      final body = {'userId': userId, ...payload};
      final response = await DioClient.dio.put('/adminUser/update', data: body);
      if (response.statusCode == 200) {
        final updated = response.data['data'] ?? response.data;
        final idx = users.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          users[idx] = {...users[idx], ...updated};
          users.refresh();
        }
        return updated as Map<String, dynamic>;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật người dùng: $e');
    }
    return null;
  }

  Future<bool> deleteUser(dynamic id) async {
    try {
      // Admin delete expects JSON body { userId }
      final userId = id is String ? int.tryParse(id) ?? id : id;
      final response = await DioClient.dio.delete('/adminUser', data: {'userId': userId});
      if (response.statusCode == 200 || response.statusCode == 204) {
        users.removeWhere((u) => u['id'] == id);
        users.refresh();
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa người dùng: $e');
    }
    return false;
  }

  // Optional: change role via admin endpoint
  Future<bool> updateUserRole(dynamic userId, int newRoleId) async {
    try {
      final uid = userId is String ? int.tryParse(userId) ?? userId : userId;
      final response = await DioClient.dio.put('/adminUser/role', data: {'userId': uid, 'newRoleId': newRoleId});
      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật role: $e');
    }
    return false;
  }

  // Optional: lock/unlock account
  Future<bool> lockUser(dynamic userId, bool newStatus) async {
    try {
      final uid = userId is String ? int.tryParse(userId) ?? userId : userId;
      final response = await DioClient.dio.put('/adminUser/lock', data: {'userId': uid, 'newStatus': newStatus});
      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể khoá/mở khoá user: $e');
    }
    return false;
  }
}
