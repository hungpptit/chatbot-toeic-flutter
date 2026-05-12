import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class ChatController extends GetxController {
  var isLoading = false.obs;
  var isSending = false.obs;
  var conversations = <Map<String, dynamic>>[].obs;
  var messages = <Map<String, dynamic>>[].obs;
  var currentConversationId = Rxn<int>();
  
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/users/me/conversations');
      if (response.statusCode == 200) {
        conversations.value = (response.data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectConversation(int id) async {
    currentConversationId.value = id;
    await fetchMessages(id);
  }

  Future<void> fetchMessages(int conversationId) async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/conversations/$conversationId/messages');
      if (response.statusCode == 200) {
        messages.value = (response.data['data'] as List).cast<Map<String, dynamic>>();
        _scrollToBottom();
      }
    } catch (e) {
      print('Error fetching messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startNewChat() async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.post('/v1/conversations', data: {
        'title': 'New Conversation',
      });
      if (response.statusCode == 201) {
        final newConv = response.data['data'] as Map<String, dynamic>;
        conversations.insert(0, newConv);
        selectConversation(newConv['id']);
      }
    } catch (e) {
      print('Error starting new chat: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renameConversation(int id, String newTitle) async {
    try {
      final response = await DioClient.dio.patch('/v1/conversations/$id', data: {
        'title': newTitle,
      });
      if (response.statusCode == 200) {
        final index = conversations.indexWhere((c) => c['id'] == id);
        if (index != -1) {
          conversations[index] = {...conversations[index], 'title': newTitle};
          conversations.refresh();
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể đổi tên cuộc hội thoại');
    }
  }

  Future<void> deleteConversation(int id) async {
    try {
      final response = await DioClient.dio.delete('/v1/conversations/$id');
      if (response.statusCode == 200) {
        conversations.removeWhere((c) => c['id'] == id);
        if (currentConversationId.value == id) {
          currentConversationId.value = null;
          messages.clear();
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể xóa cuộc hội thoại');
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || currentConversationId.value == null) return;
    
    // Optimistic UI update
    final userMessage = {'role': 'user', 'content': text};
    messages.add(userMessage);
    messageController.clear();
    _scrollToBottom();
    
    isSending.value = true;
    try {
      final response = await DioClient.dio.post(
        '/v1/conversations/${currentConversationId.value}/ask',
        data: {'rawText': text},
      );
      
      if (response.statusCode == 200) {
        // The backend might return the AI response directly or we might need to fetch messages
        // Based on the router, askChatbot likely returns the answer
        final aiResponse = response.data['data'];
        if (aiResponse != null) {
          messages.add({
            'role': 'model',
            'content': aiResponse['content'] ?? aiResponse.toString(),
          });
        } else {
          // Fallback: reload messages
          await fetchMessages(currentConversationId.value!);
        }
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar('Lỗi', 'Không thể gửi tin nhắn. Vui lòng thử lại.');
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
