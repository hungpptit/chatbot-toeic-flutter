import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/chatbot/chatbot_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot TOEIC Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Web Layout (Desktop)
            return Row(
              children: [
                const Expanded(flex: 3, child: Center(child: Text('Main Content / Test List'))),
                const VerticalDivider(),
                SizedBox(
                  width: 400,
                  child: ChatbotView(conversationId: 'default'),
                ),
              ],
            );
          } else {
            // Mobile Layout
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Main Content / Test List'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => ChatbotView(conversationId: 'default')),
                    icon: const Icon(Icons.chat),
                    label: const Text('Mở Chatbot AI'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
