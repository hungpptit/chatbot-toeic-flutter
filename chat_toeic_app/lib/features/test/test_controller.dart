import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class TestController extends GetxController {
  final player = AudioPlayer();
  var questions = [].obs;
  var isLoading = false.obs;
  var currentQuestionIndex = 0.obs;

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  Future<void> fetchQuestions(int testId) async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/tests/$testId/questions');
      if (response.statusCode == 200) {
        questions.assignAll(response.data['data']);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải câu hỏi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playAudio(String url) async {
    try {
      await player.setUrl(url);
      player.play();
    } catch (e) {
      Get.snackbar('Lỗi Audio', 'Không thể phát âm thanh: $e');
    }
  }
}
