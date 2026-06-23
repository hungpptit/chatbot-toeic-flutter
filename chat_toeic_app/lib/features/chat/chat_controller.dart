import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class ChatController extends GetxController {
  var isLoading = false.obs;
  var isSending = false.obs;
  var conversations = <Map<String, dynamic>>[].obs;
  var messages = <Map<String, dynamic>>[].obs;
  var currentConversationId = Rxn<int>();

  // VIP Subscription state
  var isVip = false.obs;
  var vipExpireAt = Rxn<DateTime>();
  var chatLimitToday = 15.obs;
  var chatCountToday = 0.obs;
  var remainingChatsToday = 15.obs;

  var subscriptions = <Map<String, dynamic>>[].obs;
  var isGeneratingQr = false.obs;
  var paymentUrl = ''.obs;
  var paymentOrderId = ''.obs;
  var selectedSubId = Rxn<int>();
  
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  Timer? _paymentTimer;

  @override
  void onInit() {
    super.onInit();
    checkVipStatus();
    fetchSubscriptions();
    fetchConversations();
  }

  Future<void> checkVipStatus() async {
    try {
      final response = await DioClient.dio.get('/v1/payments/vip-status');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        isVip.value = data['isVip'] ?? false;
        if (data['vipExpireAt'] != null) {
          vipExpireAt.value = DateTime.tryParse(data['vipExpireAt']);
        } else {
          vipExpireAt.value = null;
        }
        chatLimitToday.value = data['chatLimitToday'] ?? 15;
        chatCountToday.value = data['chatCountToday'] ?? 0;
        remainingChatsToday.value = data['remainingChatsToday'] ?? 15;
      }
    } catch (e) {
      print('Error checking VIP status: $e');
    }
  }

  Future<void> fetchSubscriptions() async {
    try {
      final response = await DioClient.dio.get('/v1/payments/subscriptions');
      if (response.statusCode == 200) {
        subscriptions.value = (response.data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
    }
  }

  Future<void> createPayment(int subId, String gateway) async {
    isGeneratingQr.value = true;
    try {
      final response = await DioClient.dio.post('/v1/payments/create', data: {
        'subscriptionId': subId,
        'paymentGateway': gateway,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'];
        paymentUrl.value = data['paymentUrl'] ?? '';
        paymentOrderId.value = data['orderId'] ?? '';
        selectedSubId.value = subId;
        startPaymentPolling();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể khởi tạo thanh toán: $e');
    } finally {
      isGeneratingQr.value = false;
    }
  }

  void startPaymentPolling() {
    _paymentTimer?.cancel();
    int checkCount = 0;
    _paymentTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      checkCount++;
      // Hết hạn sau 5 phút (150 lần check)
      if (checkCount > 150) {
        stopPaymentPolling();
        Get.snackbar('Hết thời gian', 'Quá thời gian thanh toán. Vui lòng thử lại nếu muốn tiếp tục.',
            backgroundColor: Colors.orangeAccent, colorText: Colors.white);
        cancelPayment();
        return;
      }

      await checkVipStatus();
      if (isVip.value) {
        timer.cancel();
        _paymentTimer = null;
        paymentUrl.value = '';
        paymentOrderId.value = '';
        selectedSubId.value = null;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar('Thành công', 'Tài khoản của bạn đã được nâng cấp lên VIP!',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    });
  }

  void stopPaymentPolling() {
    _paymentTimer?.cancel();
    _paymentTimer = null;
  }

  void cancelPayment() {
    stopPaymentPolling();
    paymentUrl.value = '';
    paymentOrderId.value = '';
    selectedSubId.value = null;
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

    if (!isVip.value && remainingChatsToday.value <= 0) {
      Get.snackbar(
        'Hết lượt chat miễn phí',
        'Bạn đã dùng hết 15 tin nhắn miễn phí hôm nay. Vui lòng đăng ký VIP để tiếp tục.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }
    
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
        final data = response.data['data'];
        if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          String content = '';
          
          if (firstResult['type'] == 'General-AI') {
            content = firstResult['answer'] ?? '';
          } else if (firstResult['type'] == 'Vocabulary-Lookup') {
            content = 'Từ vựng: ${firstResult['word']}\nĐịnh nghĩa: ${firstResult['definition']}\nGiải thích: ${firstResult['viExplanation']}';
          } else if (firstResult['type'] == 'Question') {
            content = 'Câu hỏi: ${firstResult['question']}\nĐáp án: ${firstResult['answer']}\nGiải thích: ${firstResult['explanation']}';
          } else {
            content = firstResult['answer'] ?? firstResult.toString();
          }

          messages.add({
            'role': 'model',
            'content': content,
          });

          // Cập nhật lượt chat còn lại trên giao diện
          if (!isVip.value) {
            remainingChatsToday.value = (remainingChatsToday.value - 1).clamp(0, 15);
            chatCountToday.value = (chatCountToday.value + 1).clamp(0, 15);
          }
        } else {
          // Fallback: reload messages if result format is unexpected
          await fetchMessages(currentConversationId.value!);
        }
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (e is DioException && e.response?.statusCode == 403) {
        messages.removeLast(); // Xóa tin nhắn gửi lỗi
        await checkVipStatus(); // Cập nhật lại trạng thái chính xác
        Get.snackbar(
          'Đạt giới hạn',
          'Bạn đã hết lượt chat miễn phí hôm nay. Vui lòng đăng ký gói VIP.',
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Lỗi', 'Không thể gửi tin nhắn. Vui lòng thử lại.');
      }
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
    stopPaymentPolling();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
