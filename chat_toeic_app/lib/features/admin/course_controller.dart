import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class CourseController extends GetxController {
  var isLoading = false.obs;
  var courses = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCourses(includeTests: true);
  }

  Future<void> fetchCourses({bool includeTests = true}) async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get(
        '/v1/courses',
        queryParameters: includeTests ? {'include': 'tests'} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        courses.value = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải danh sách khóa học: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> updateCourseName(int id, String newName) async {
    try {
      final response = await DioClient.dio.patch('/v1/courses/$id', data: {'name': newName});
      if (response.statusCode == 200) {
        final updated = response.data['data'] ?? response.data;
        // update local list
        final idx = courses.indexWhere((c) => c['id'] == id);
        if (idx != -1) {
          courses[idx] = {...courses[idx], 'name': updated['name'] ?? newName};
          courses.refresh();
        }
        return updated.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật khóa học: $e');
    }
    return null;
  }

  Future<bool> deleteCourse(int id) async {
    try {
      final response = await DioClient.dio.delete('/v1/courses/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        courses.removeWhere((c) => c['id'] == id);
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa khóa học: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> createCourse(String name) async {
    try {
      final response = await DioClient.dio.post('/v1/courses', data: {'name': name});
      if (response.statusCode == 201 || response.statusCode == 200) {
        final created = response.data['data'] ?? response.data;
        // prepend to list so user sees it immediately
        courses.insert(0, created as Map<String, dynamic>);
        courses.refresh();
        return created.cast<String, dynamic>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo khóa học: $e');
    }
    return null;
  }
}
