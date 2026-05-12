import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class Message {
  final String role;
  final String content;
  Message({required this.role, required this.content});
}

class ChatbotController extends GetxController {
  var messages = <Message>[].obs;
  var isLoading = false.obs;

  Future<void> askAi(String conversationId, String text) async {
    // Add user message locally
    messages.add(Message(role: 'user', content: text));
    
    isLoading.value = true;
    try {
      final response = await DioClient.dio.post(
        '/v1/conversations/$conversationId/ask',
        data: {'rawText': text},
      );

      if (response.statusCode == 200) {
        final aiContent = response.data['data']['candidates'][0]['content']['parts'][0]['text'];
        messages.add(Message(role: 'model', content: aiContent));
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể kết nối với AI: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
