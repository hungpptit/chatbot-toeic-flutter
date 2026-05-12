import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:just_audio/just_audio.dart';

class VocabularyController extends GetxController {
  var isLoading = false.obs;
  var wordData = Rxn<Map<String, dynamic>>();
  var searchController = RxString('');
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> searchWord(String word) async {
    if (word.trim().isEmpty) return;
    
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/vocabulary/word/$word');
      if (response.statusCode == 200) {
        wordData.value = response.data;
      } else {
        Get.snackbar('Lỗi', 'Không tìm thấy từ vựng này');
        wordData.value = null;
      }
    } catch (e) {
      print('Error searching word: $e');
      Get.snackbar('Thông báo', 'Từ vựng này chưa có trong hệ thống hoặc lỗi kết nối');
      wordData.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể phát âm thanh: $e');
    }
  }
}
