import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/test/test_controller.dart';

class TestDetailView extends StatelessWidget {
  final int testId;

  const TestDetailView({
    super.key,
    required this.testId,
  });

  @override
  Widget build(BuildContext context) {
    // Get existing controller or create new one
    TestController testController;
    try {
      testController = Get.find<TestController>(tag: 'test_$testId');
    } catch (e) {
      testController = Get.put(
        TestController(),
        tag: 'test_$testId',
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmation(context, testController);
        if (shouldExit && context.mounted) {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Obx(
          () {
          // Fetch questions once if not loading and not fetched yet
          if (testController.questions.isEmpty &&
              !testController.isLoading.value &&
              !testController.testStarted.value &&
              testController.isTestActive.value &&
              !testController.isCancelling.value) {
            print('📥 Pre-loading questions to detect test type...');
            testController.fetchQuestions(testId);
          }

          // Show intro screen for listening tests that haven't started
          if (testController.isListeningTest.value && !testController.testStarted.value) {
            print('📖 Showing introduction screen for listening test');
            return _buildListeningIntro(testController, context);
          }

          // If still loading, show spinner
          if (testController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (testController.questions.isEmpty) {
            print('⚠️ Questions list is empty!');
            return const Center(
              child: Text(
                'Không có câu hỏi nào',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          print('✅ Rendering ${testController.questions.length} questions');

            return Column(
              children: [
                // === HEADER: Timer + Progress + Submit ===
                _buildHeader(testController, context),

                // === MAIN CONTENT: Split-Screen (Image + Question+Answers) ===
                Expanded(
                  child: _buildSplitScreenContent(testController),
                ),

                // === FOOTER: Navigation Buttons ===
                _buildFooter(testController, context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ========== LISTENING INTRO SCREEN ==========
  Widget _buildListeningIntro(TestController controller, BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                // Header with PART info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C34),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF24324F)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'PART 1',
                        style: TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main content card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C34),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF24324F)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LISTENING TEST',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'In the Listening test, you will be asked to demonstrate how well you understand spoken English. The entire Listening test will last approximately 45 minutes. There are four parts, and directions are given for each part. You must mark your answers on the separate answer sheet. Do not write your answers in your test book.',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 14,
                          height: 1.75,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PART 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Directions: For each question in this part, you will hear four statements about a picture in your test book. When you hear the statements, you must select the one statement that best describes what you see in the picture. Then find the number of the question on your answer sheet and mark your answer. The statements will not be printed in your test book and will be spoken only one time.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 14,
                          height: 1.75,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Sample image
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1327),
                          border: Border.all(color: const Color(0xFF2A3D64)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            'https://res.cloudinary.com/degzfp5hs/image/upload/v1762226881/toeic-media/images/ljlphpzp6v4qepytcdlo.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 44,
                                  color: Color(0xFF64748B),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Start action only
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            print('🎬 START button pressed - initiating test attempt');
                            // Create test attempt and trigger audio auto-play
                            await controller.startTestAttempt(testId);
                            print('✅ START button - test attempt created, setting testStarted=true');
                            controller.testStarted.value = true;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24),
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'BẮT ĐẦU',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ========== SPLIT-SCREEN LAYOUT ==========
  Widget _buildSplitScreenContent(TestController controller) {
    final question = controller.currentQuestion;
    
    print('🎬 _buildSplitScreenContent called');
    print('   Current question index: ${controller.currentQuestionIndex.value}');
    print('   Question keys: ${question.keys.toList()}');
    print('   Has mediaMappings: ${question.containsKey('mediaMappings')}');
    
    // Extract image URL from mediaMappings
    String? imageUrl;
    if (question.isNotEmpty && question['mediaMappings'] is List && (question['mediaMappings'] as List).isNotEmpty) {
      for (final mapping in (question['mediaMappings'] as List)) {
        if (mapping['media'] != null) {
          final mediaType = mapping['media']['type'] as String?;
          final mediaUrl = mapping['media']['url'] as String?;
          
          print('   Found media - type: $mediaType, url: ${mediaUrl?.substring(0, 50)}...');
          
          if (mediaType == 'image' && imageUrl == null) {
            imageUrl = mediaUrl;
            print('   ✓ Set imageUrl: ${imageUrl?.substring(0, 50)}...');
          }
        }
      }
    } else {
      print('   ⚠️ No mediaMappings found or invalid structure');
    }

    // If no image, show full width question content
    if (imageUrl == null || imageUrl.isEmpty) {
      print('   📄 No image - showing full-width layout');
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Number
            Obx(
              () => Text(
                'Câu ${controller.currentQuestionIndex.value + 1} / ${controller.totalQuestions.value}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionContent(controller),
            const SizedBox(height: 32),
            _buildAnswerOptions(controller),
          ],
        ),
      );
    }
    
    print('   🖼️  Showing split-screen layout with image');

    // Split-screen layout: Image on left, Content on right (ratio ~1:1.2)
    return Row(
      children: [
        // === LEFT SIDE: Image ===
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 1.0,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Không thể tải hình ảnh',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // === RIGHT SIDE: Question + Answers ===
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number
                  Obx(
                    () => Text(
                      'Câu ${controller.currentQuestionIndex.value + 1} / ${controller.totalQuestions.value}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question Content (without audio/image display)
                  _buildQuestionContentNoMedia(controller),
                  const SizedBox(height: 32),

                  // Answer Options
                  _buildAnswerOptions(controller),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ========== HEADER ==========
  Widget _buildHeader(TestController controller, BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () async {
              final shouldExit = await _showExitConfirmation(context, controller);
              if (shouldExit && context.mounted) {
                Get.back();
              }
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Progress Bar (center)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiến độ',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Obx(
                      () => LinearProgressIndicator(
                        value: controller.totalQuestions.value > 0
                            ? controller.currentQuestionIndex.value / controller.totalQuestions.value
                            : 0,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button + Timer
          Row(
            children: [
              // Submit Button
              ElevatedButton(
                onPressed: () {
                  controller.submitTest(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Nộp bài',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Timer (or Question Timer for Listening)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF334155),
                  ),
                ),
                child: Obx(
                  () => Text(
                    controller.timeString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ========== QUESTION CONTENT ==========
  Widget _buildQuestionContent(TestController controller) {
    final question = controller.currentQuestion;
    
    // Extract audio and image URLs from mediaMappings
    String? audioUrl;
    String? imageUrl;
    if (question['mediaMappings'] is List && (question['mediaMappings'] as List).isNotEmpty) {
      for (final mapping in (question['mediaMappings'] as List)) {
        if (mapping['media'] != null) {
          final mediaType = mapping['media']['type'] as String?;
          final mediaUrl = mapping['media']['url'] as String?;
          
          if (mediaType == 'audio' && audioUrl == null) {
            audioUrl = mediaUrl;
          } else if (mediaType == 'image' && imageUrl == null) {
            imageUrl = mediaUrl;
          }
        }
      }
    }
    
    // DEBUG: Print question data
    print('📌 Question Content:');
    print('  - question: "${question['question']}"');
    print('  - hasAudio: ${audioUrl != null}');
    print('  - hasImage: ${imageUrl != null}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Text
        Text(
          question['question'] ?? 'Không có nội dung câu hỏi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Audio Player (if available)
        if (audioUrl != null && audioUrl.isNotEmpty)
          _buildAudioPlayer(controller, audioUrl),

        // Image (if available)
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Không thể tải hình ảnh',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// ========== QUESTION CONTENT (No Media - For Split Screen Right Side) ==========
  Widget _buildQuestionContentNoMedia(TestController controller) {
    final question = controller.currentQuestion;
    
    // Extract audio URL from mediaMappings only
    String? audioUrl;
    if (question['mediaMappings'] is List && (question['mediaMappings'] as List).isNotEmpty) {
      for (final mapping in (question['mediaMappings'] as List)) {
        if (mapping['media'] != null) {
          final mediaType = mapping['media']['type'] as String?;
          final mediaUrl = mapping['media']['url'] as String?;
          
          if (mediaType == 'audio' && audioUrl == null) {
            audioUrl = mediaUrl;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Text
        Text(
          question['question'] ?? 'Không có nội dung câu hỏi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Audio Player (if available)
        if (audioUrl != null && audioUrl.isNotEmpty)
          _buildAudioPlayer(controller, audioUrl),
      ],
    );
  }

  /// ========== AUDIO PLAYER ==========
  Widget _buildAudioPlayer(TestController controller, String audioUrl) {
    // Hide manual audio controls when current question is in listening mode.
    if (controller.isCurrentQuestionListening) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          Obx(
            () => GestureDetector(
              onTap: () {
                if (controller.isAudioPlaying.value) {
                  controller.pauseAudio();
                } else {
                  controller.playAudio(audioUrl);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isAudioPlaying.value ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Audio Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nghe âm thanh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhấn nút để phát âm thanh',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Stop Button
          Obx(
            () => controller.isAudioPlaying.value
                ? GestureDetector(
                    onTap: () => controller.stopAudio(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  /// ========== ANSWER OPTIONS ==========
  Widget _buildAnswerOptions(TestController controller) {
    final question = controller.currentQuestion;
    
    // Build answers array from optionA, B, C, D
    final answerOptions = [
      {'label': 'A', 'text': question['optionA'] as String? ?? ''},
      {'label': 'B', 'text': question['optionB'] as String? ?? ''},
      {'label': 'C', 'text': question['optionC'] as String? ?? ''},
      {'label': 'D', 'text': question['optionD'] as String? ?? ''},
    ];

    print('🎯 Rendering answers:');
    for (int i = 0; i < answerOptions.length; i++) {
      print('   $i: ${answerOptions[i]['label']} - ${answerOptions[i]['text']}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn đáp án:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (index) {
            final answerText = answerOptions[index]['text'] as String;
            final label = answerOptions[index]['label'] as String;

            return Obx(
              () {
                final selected = controller.selectedAnswerForCurrentQuestion == index;
                return GestureDetector(
                  onTap: () {
                    controller.selectAnswer(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio Button
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF94A3B8),
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6366F1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Answer Text
                        Expanded(
                          child: Text(
                            '$label. $answerText',
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// ========== FOOTER: Navigation ==========
  Widget _buildFooter(TestController controller, BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(12),
      child: Obx(
        () {
          // For listening tests: show progress + timing info (no manual navigation)
          if (controller.shouldUseListeningNavigationUi) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Question Menu Button
                ElevatedButton.icon(
                  onPressed: () {
                    _showQuestionMenu(context, controller);
                  },
                  icon: const Icon(Icons.menu),
                  label: const Text('Danh sách câu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                ),
              ],
            );
          }

          // For reading/other tests: show previous/next buttons
          return Row(
            children: [
              // Previous Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.hasPreviousQuestion
                      ? () => controller.previousQuestion()
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Câu trước'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.hasPreviousQuestion
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Question Menu Button - Show answered/total
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showQuestionMenu(context, controller);
                  },
                  icon: const Icon(Icons.menu),
                  label: Obx(
                    () => Text(
                      '${controller.userAnswers.length}/${controller.totalQuestions.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Next Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.hasNextQuestion
                      ? () => controller.nextQuestion()
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Câu sau'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.hasNextQuestion
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ========== DIALOGS & MENUS ==========

  /// Question Selection Menu
  void _showQuestionMenu(BuildContext context, TestController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh sách câu hỏi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF334155)),

              // Questions Grid
              Expanded(
                child: Obx(
                  () => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: controller.totalQuestions.value,
                    itemBuilder: (context, index) {
                      final isAnswered = controller.isQuestionAnswered(index);
                      final isCurrent = controller.currentQuestionIndex.value == index;

                      return GestureDetector(
                        onTap: () {
                          controller.goToQuestion(index);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF6366F1)
                                : isAnswered
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent || isAnswered
                                    ? Colors.white
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.white, const Color(0xFF334155), 'Chưa trả lời'),
                    _buildLegendItem(Colors.white, const Color(0xFF10B981), 'Đã trả lời'),
                    _buildLegendItem(Colors.white, const Color(0xFF6366F1), 'Hiện tại'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Legend Item
  Widget _buildLegendItem(Color textColor, Color boxColor, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Helper: Format seconds to mm:ss
  /// Exit Confirmation Dialog
  Future<bool> _showExitConfirmation(
    BuildContext context,
    TestController controller,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Bạn có chắc chắn muốn thoát?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Bạn đã trả lời ${controller.userAnswers.length}/${controller.totalQuestions.value} câu. '
            'Nếu thoát, bài thi sẽ bị hủy bỏ.',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(color: Color(0xFF6366F1)),
              ),
            ),
            TextButton(
              onPressed: () async {
                await controller.cancelTest();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                'Thoát',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    ) ??
        false;
  }
}
