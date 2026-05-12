import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:chat_toeic_app/features/vocabulary/vocabulary_controller.dart';
import 'package:chat_toeic_app/widgets/nav_bar.dart';

class VocabularyView extends StatelessWidget {
  const VocabularyView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VocabularyController());
    final searchInputController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          const CustomNavBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tra từ vựng TOEIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchInputController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Nhập từ cần tra (ví dụ: build)...',
                                hintStyle: const TextStyle(color: Color(0xFF475569)),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              ),
                              onSubmitted: (val) => controller.searchWord(val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () => controller.searchWord(searchInputController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                              ),
                              child: const Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Result Section
                      Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final data = controller.wordData.value;
                        if (data == null) {
                          return const SizedBox.shrink();
                        }
                        
                        return _buildWordDetails(data, controller);
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDetails(Map<String, dynamic> data, VocabularyController controller) {
    final word = data['word'] ?? '';
    final pronunciations = data['pronunciations'] as List? ?? [];
    final meanings = data['meanings'] as List? ?? [];
    final synonyms = data['synonyms'] as List? ?? [];
    final antonyms = data['antonyms'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Phonetics Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              
              // Display primary parts of speech if available
              if (meanings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    meanings.map((m) => m['partOfSpeech']).toSet().join(', '),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Phonetics Row
              Wrap(
                spacing: 32,
                runSpacing: 16,
                children: pronunciations.map((p) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${p['accent'] ?? ''} /${p['phoneticText'] ?? ''}/',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(LucideIcons.volume2, color: const Color(0xFF6366F1), size: 18),
                        onPressed: () => controller.playAudio(p['audioUrl']),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        
        // Meanings List
        ...meanings.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        m['definition'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (m['example'] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF6366F1), fontSize: 20)),
                        Expanded(
                          child: Text(
                            m['example'],
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(color: Colors.white10, height: 40),
              ],
            ),
          );
        }).toList(),
        
        // Synonyms & Antonyms
        if (synonyms.isNotEmpty) ...[
          const Text(
            'Synonyms',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: synonyms.map<Widget>((s) => _buildChip(s['synonym'], const Color(0xFF10B981))).toList(),
          ),
          const SizedBox(height: 32),
        ],
        
        if (antonyms.isNotEmpty) ...[
          const Text(
            'Antonyms',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: antonyms.map<Widget>((a) => _buildChip(a['antonym'], const Color(0xFFF43F5E))).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
