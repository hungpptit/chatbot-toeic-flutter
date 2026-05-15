import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:chat_toeic_app/core/api/upload_service.dart';
import 'dart:typed_data';

class TestController extends GetxController {
  var isLoading = false.obs;
  var tests = <Map<String, dynamic>>[].obs;
  var uploadProgress = <int, double>{}.obs; // testId -> progress (0.0 to 1.0)
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

  Future<List<Map<String, dynamic>>> fetchTestQuestions(int testId) async {
    try {
      final response = await DioClient.dio.get('/v1/tests/$testId/questions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải câu hỏi: $e');
    }
    return [];
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

  Future<bool> updateTest(int id, Map<String, dynamic> data) async {
    try {
      final response = await DioClient.dio.patch('/v1/tests/$id', data: data);
      if (response.statusCode == 200) {
        fetchTests(); // Refresh list
        return true;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật đề thi: $e');
    }
    return false;
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> data) async {
    try {
      final response = await DioClient.dio.patch('/v1/tests/questions/$id', data: data);
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Update question error: $e");
    }
    return false;
  }

  // New Background Update Logic
  Future<void> backgroundUpdateTest({
    required int testId,
    required String title,
    required String duration,
    required List<Map<String, dynamic>> questions,
    Uint8List? newAudioBytes,
    String? newAudioName,
    double? existingAudioDuration,
  }) async {
    try {
      uploadProgress[testId] = 0.05; // Starting

      // 1. Upload Audio if needed
      String? finalAudioUrl;
      double? finalAudioDuration = existingAudioDuration;
      
      if (newAudioBytes != null) {
        final uploadedAudio = await UploadService.uploadAudio(newAudioBytes, newAudioName!);
        if (uploadedAudio != null) {
          finalAudioUrl = uploadedAudio['url'];
          finalAudioDuration = uploadedAudio['duration'];
        }
      }
      uploadProgress[testId] = 0.15;

      // 2. Update Test Meta
      await updateTest(testId, {'title': title, 'duration': duration});
      uploadProgress[testId] = 0.2;

      // 3. Update Questions sequentially
      int total = questions.length;
      for (int i = 0; i < total; i++) {
        var q = questions[i];
        String? questionImageUrl;
        
        // Upload image if needed
        if (q['_newImageBytes'] != null) {
          final uploadedImg = await UploadService.uploadImage(q['_newImageBytes'], q['_newImageName']);
          if (uploadedImg != null) {
            questionImageUrl = uploadedImg['url'];
          }
        }

        final Map<String, dynamic> updateData = {
          'question': q['question'],
          'optionA': q['optionA'],
          'optionB': q['optionB'],
          'optionC': q['optionC'],
          'optionD': q['optionD'],
          'correctAnswer': q['correctAnswer'],
          'explanation': q['explanation'],
          'mediaFiles': [],
        };

        // Media Logic (same as before)
        if (questionImageUrl != null) {
          updateData['mediaFiles'].add({'type': 'image', 'url': questionImageUrl});
        } else {
          final existingImage = (q['mediaMappings'] as List?)?.firstWhere(
            (m) => m['media']?['type'] == 'image', orElse: () => null);
          if (existingImage != null) {
            updateData['mediaFiles'].add({'type': 'image', 'url': existingImage['media']['url']});
          }
        }

        final existingAudioMapping = (q['mediaMappings'] as List?)?.firstWhere(
          (m) => m['media']?['type'] == 'audio', orElse: () => null);
        
        if (finalAudioUrl != null || q['_newStartSecond'] != null || q['_newEndSecond'] != null) {
          final audioUrl = finalAudioUrl ?? existingAudioMapping?['media']?['url'];
          if (audioUrl != null) {
            updateData['mediaFiles'].add({
              'type': 'audio',
              'url': audioUrl,
              'duration': finalAudioDuration ?? existingAudioMapping?['media']?['duration'],
              'startSecond': q['_newStartSecond'] ?? existingAudioMapping?['startSecond'],
              'endSecond': q['_newEndSecond'] ?? existingAudioMapping?['endSecond'],
            });
          }
        } else if (existingAudioMapping != null) {
          updateData['mediaFiles'].add({
            'type': 'audio',
            'url': existingAudioMapping['media']['url'],
            'startSecond': existingAudioMapping['startSecond'],
            'endSecond': existingAudioMapping['endSecond'],
          });
        }

        await updateQuestion(q['id'], updateData);
        
        // Update progress: from 0.2 to 1.0
        uploadProgress[testId] = 0.2 + (0.8 * (i + 1) / total);
      }

      Get.snackbar('Hoàn tất', 'Đề thi "$title" đã được cập nhật thành công');
    } catch (e) {
      Get.snackbar('Lỗi', 'Cập nhật đề thi "$title" thất bại: $e');
    } finally {
      // Delay a bit so user can see 100% then remove
      await Future.delayed(const Duration(seconds: 2));
      uploadProgress.remove(testId);
    }
  }
}
