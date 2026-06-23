import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chat_toeic_app/features/chat/chat_controller.dart';
import 'package:chat_toeic_app/widgets/nav_bar.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    final authController = Get.find<AuthController>();
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: _buildSidebar(controller, authController),
      ) : null,
      body: Column(
        children: [
          const CustomNavBar(),
          Expanded(
            child: Row(
              children: [
                // Sidebar (Left) - Hidden on mobile
                if (!isMobile) _buildSidebar(controller, authController),
                
                // Main Chat Area (Right)
                Expanded(
                  child: Obx(() {
                    final noChatsLeft = !controller.isVip.value && controller.remainingChatsToday.value <= 0;
                    
                    return Column(
                      children: [
                        // Header
                        _buildChatHeader(controller, isMobile: isMobile, context: context),
                        
                        if (noChatsLeft)
                          Expanded(
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 550),
                                padding: const EdgeInsets.all(24),
                                child: SingleChildScrollView(
                                  child: _buildUpgradePanel(controller, context),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          // Messages
                          Expanded(child: _buildMessageList(controller, isMobile: isMobile)),
                          
                          // Input Area
                          _buildInputArea(controller, isMobile: isMobile),
                        ]
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ChatController controller, AuthController authController) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () => controller.startNewChat(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          
          // Conversation List
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.conversations.length,
              itemBuilder: (context, index) {
                final conv = controller.conversations[index];
                final isSelected = controller.currentConversationId.value == conv['id'];
                
                return _buildConversationItem(conv, isSelected, controller);
              },
            )),
          ),
          
          // User Info
          _buildUserProfile(authController),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv, bool isSelected, ChatController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => controller.selectConversation(conv['id']),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.messageSquare, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  conv['title'] ?? 'Untitled Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreHorizontal, 
                  size: 16, 
                  color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent
                ),
                padding: EdgeInsets.zero,
                color: const Color(0xFF1E293B),
                onSelected: (value) {
                  if (value == 'rename') {
                    _showRenameDialog(conv, controller);
                  } else if (value == 'delete') {
                    controller.deleteConversation(conv['id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Đổi tên', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(Map<String, dynamic> conv, ChatController controller) {
    final textController = TextEditingController(text: conv['title']);
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Đổi tên hội thoại', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              controller.renameConversation(conv['id'], textController.text);
              Get.back();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Obx(() {
        final user = authController.user.value;
        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                user?['username']?[0]?.toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['username'] ?? 'User',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    user?['email'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildChatHeader(ChatController controller, {bool isMobile = false, required BuildContext context}) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )),
            const SizedBox(width: 8),
          ],
          Obx(() {
            final id = controller.currentConversationId.value;
            final conv = controller.conversations.firstWhereOrNull((c) => c['id'] == id);
            return Text(
              conv?['title'] ?? 'Chat TOEIC AI',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            );
          }),
          const Spacer(),
          
          // VIP Status Badge & Upgrade Button
          Obx(() {
            if (controller.isVip.value) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.crown, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('VIP ACTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            } else {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      'Free (${controller.remainingChatsToday.value}/15)',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(24),
                            child: SingleChildScrollView(
                              child: _buildUpgradePanel(controller, ctx),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.crown, size: 14, color: Colors.white),
                    label: const Text('Lên VIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              );
            }
          }),
          
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20, color: Color(0xFF94A3B8)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePanel(ChatController controller, BuildContext context) {
    final selectedPlanId = Rxn<int>();
    
    // Set initial selection if available
    if (controller.subscriptions.isNotEmpty) {
      selectedPlanId.value = controller.subscriptions.first['id'];
    }

    return Obx(() {
      // If QR code is generated, show the payment view
      if (controller.paymentUrl.value.isNotEmpty) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(LucideIcons.wallet, size: 48, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán qua ZaloPay',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đơn hàng: ${controller.paymentOrderId.value}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(controller.paymentUrl.value)}',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mở ứng dụng ZaloPay quét mã QR để thanh toán',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Control buttons
            ElevatedButton.icon(
              onPressed: () async {
                await controller.verifyPayment();
                if (controller.isVip.value) {
                  Navigator.of(context).pop(); // Đóng dialog nếu đang mở
                }
              },
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Tôi đã thanh toán thành công'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),

            TextButton(
              onPressed: () => controller.cancelPayment(),
              child: const Text('Quay lại chọn gói khác', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      }

      // Default Packages list
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.crown, size: 40, color: Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Nâng Cấp VIP Chatbot',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Trò chuyện không giới hạn và mở khóa tất cả tính năng AI',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('Chọn gói đăng ký của bạn:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),

          // Render Packages
          if (controller.subscriptions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ...controller.subscriptions.map((sub) {
              final id = sub['id'] as int;
              final name = sub['name'] ?? '';
              final price = sub['price'];
              final duration = sub['durationDays'] ?? 30;
              final description = sub['description'] ?? '';
              
              // Set selected defaults if not set
              if (selectedPlanId.value == null) {
                selectedPlanId.value = id;
              }
              
              return Obx(() {
                final isSelected = selectedPlanId.value == id;
                return GestureDetector(
                  onTap: () => selectedPlanId.value = id,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description.isNotEmpty ? description : 'Thời hạn sử dụng $duration ngày',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatPrice(price),
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
            
          const SizedBox(height: 24),
          
          // Action buttons
          Obx(() {
            final activeId = selectedPlanId.value;
            if (activeId == null) return const SizedBox.shrink();
            
            return controller.isGeneratingQr.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => controller.createPayment(activeId, 'zalopay'),
                        icon: const Icon(LucideIcons.qrCode),
                        label: const Text('Thanh toán ZaloPay (Mã QR động)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    
                    ],
                  );
          }),
        ],
      );
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0đ';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    final str = numPrice.toInt().toString();
    if (str.length > 3) {
      return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + 'đ';
    }
    return '$strđ';
  }

  Widget _buildMessageList(ChatController controller, {bool isMobile = false}) {
    return Obx(() {
      if (controller.isLoading.value && controller.messages.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
      }
      
      if (controller.messages.isEmpty && controller.currentConversationId.value == null) {
        return _buildEmptyState();
      }
      
      final horizontalPadding = isMobile ? 16.0 : 100.0;
      final verticalPadding = isMobile ? 20.0 : 40.0;

      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        itemCount: controller.messages.length + (controller.isSending.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.messages.length) {
            return _buildTypingIndicator();
          }
          final msg = controller.messages[index];
          final isAI = msg['role'] == 'model' || msg['role'] == 'ai';
          return _buildMessageBubble(msg['content'] ?? '', isAI);
        },
      );
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.bot, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isAI) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700), // Limit width for readability
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isAI ? Colors.white.withOpacity(0.03) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAI ? 4 : 20),
                  bottomRight: Radius.circular(isAI ? 20 : 4),
                ),
                border: isAI ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              ),
              child: Text(
                content,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          
          if (!isAI) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.user, color: Colors.white70, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bot, color: Color(0xFF6366F1), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Hỏi tôi bất cứ điều gì về TOEIC',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tôi có thể giúp bạn giải đề, học từ vựng hoặc giải thích ngữ pháp.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatController controller, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withOpacity(0),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 800),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Better default alignment
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  maxLines: 5,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Hỏi tôi bất cứ điều gì...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Obx(() => IconButton(
                  onPressed: controller.isSending.value ? null : () => controller.sendMessage(),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: controller.isSending.value 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.arrowUp, color: Colors.white, size: 20),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white70,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
