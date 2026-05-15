import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/test_controller.dart';
import 'package:just_audio/just_audio.dart';

class TestPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> test;
  const TestPreviewDialog({super.key, required this.test});

  @override
  State<TestPreviewDialog> createState() => _TestPreviewDialogState();
}

class _TestPreviewDialogState extends State<TestPreviewDialog> {
  final controller = Get.find<TestController>();
  late AudioPlayer _sharedPlayer;
  String? _currentlyPlayingUrl;
  int? _currentlyPlayingIndex;
  
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _sharedPlayer = AudioPlayer();
    _loadQuestions();
  }

  @override
  void dispose() {
    _sharedPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final data = await controller.fetchTestQuestions(widget.test['id']);
    if (mounted) {
      setState(() {
        questions = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.test['title'] ?? 'Chi tiết bài thi',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${questions.length} câu hỏi • ${widget.test['duration'] ?? '-'} • ${widget.test['tags']?.join(', ') ?? ''}',
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const Divider(height: 48, color: Colors.white10),
            
            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : questions.isEmpty
                      ? const Center(child: Text('Không có câu hỏi nào trong đề thi này', style: TextStyle(color: Colors.white38)))
                      : ListView.separated(
                          itemCount: questions.length,
                          separatorBuilder: (_, __) => Divider(height: 40, color: Colors.white.withOpacity(0.05)),
                          itemBuilder: (context, index) {
                            final q = questions[index];
                            return _QuestionItem(
                              index: index + 1, 
                              question: q,
                              sharedPlayer: _sharedPlayer,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final AudioPlayer sharedPlayer;
  const _QuestionItem({required this.index, required this.question, required this.sharedPlayer});

  @override
  Widget build(BuildContext context) {
    final media = (question['mediaMappings'] as List?) ?? [];
    final audioMapping = media.firstWhere((m) => m['media']?['type'] == 'audio', orElse: () => null);
    debugPrint("🔍 Audio mapping for Câu $index: $audioMapping");
    final audioUrl = audioMapping?['media']?['url'];
    final double? startSecond = audioMapping != null ? (audioMapping['startSecond']?.toDouble()) : null;
    final double? endSecond = audioMapping != null ? (audioMapping['endSecond']?.toDouble()) : null;
    final imageUrl = media.firstWhere((m) => m['media']?['type'] == 'image', orElse: () => null)?['media']?['url'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Câu $index',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question['question'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        
        if (imageUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.white.withOpacity(0.05),
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white10)),
              ),
            ),
          ),
        ],

        if (audioUrl != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 916,
            child: _AudioPlayerWidget(
              url: audioUrl, 
              startSecond: startSecond, 
              endSecond: endSecond,
              player: sharedPlayer,
              questionId: question['id'],
            ),
          ),
        ],

        const SizedBox(height: 16),
        // Options and Explanation group
        SizedBox(
          width: 916, // Exactly 450 * 2 + 16 spacing
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _OptionItem(label: 'A', text: question['optionA'], isCorrect: question['correctAnswer'] == 'A'),
                  _OptionItem(label: 'B', text: question['optionB'], isCorrect: question['correctAnswer'] == 'B'),
                  _OptionItem(label: 'C', text: question['optionC'], isCorrect: question['correctAnswer'] == 'C'),
                  _OptionItem(label: 'D', text: question['optionD'], isCorrect: question['correctAnswer'] == 'D'),
                ],
              ),
              if (question['explanation'] != null && question['explanation'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity, // Now it will fill the 916px parent
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giải thích:', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        question['explanation'],
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionItem extends StatelessWidget {
  final String label;
  final String? text;
  final bool isCorrect;
  const _OptionItem({required this.label, this.text, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 450,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? Colors.green.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? Colors.green : Colors.white10,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(color: isCorrect ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text!,
              style: TextStyle(color: isCorrect ? Colors.white : Colors.white70, fontSize: 14),
            ),
          ),
          if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final double? startSecond;
  final double? endSecond;
  final AudioPlayer player;
  final dynamic questionId;

  const _AudioPlayerWidget({
    required this.url, 
    this.startSecond, 
    this.endSecond, 
    required this.player,
    required this.questionId,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  bool isThisPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isThisActive = false; // Whether this widget is currently controlling the shared player

  @override
  void initState() {
    super.initState();
    _listenToPlayer();
  }

  void _listenToPlayer() {
    widget.player.playerStateStream.listen((state) {
      if (!mounted) return;
      
      // Check if the current source matches this widget's URL and clipping
      // Note: just_audio doesn't make it easy to compare ClippingAudioSource
      // So we'll use a more manual approach with a global state if needed, 
      // but for now let's rely on the URL or just use the "isThisActive" flag
    });

    widget.player.positionStream.listen((p) {
      if (mounted && isThisActive) {
        setState(() => position = p);
        
        // Manual clipping check: if reached endSecond, stop
        if (widget.endSecond != null) {
          final endDuration = Duration(milliseconds: (widget.endSecond! * 1000).toInt());
          if (p >= endDuration && isThisPlaying) {
            widget.player.pause();
            setState(() => isThisPlaying = false);
            widget.player.seek(Duration(milliseconds: (widget.startSecond! * 1000).toInt()));
          }
        }
      }
    });

    widget.player.durationStream.listen((d) {
      if (mounted && isThisActive) {
        // For manual clipping, we display the segment duration
        if (widget.startSecond != null && widget.endSecond != null) {
          setState(() => duration = Duration(milliseconds: ((widget.endSecond! - widget.startSecond!) * 1000).toInt()));
        } else if (d != null && d != Duration.zero) {
          setState(() => duration = d);
        }
      }
    });

    widget.player.playerStateStream.listen((state) {
      if (mounted && isThisActive) {
        setState(() => isThisPlaying = state.playing);
      } else if (mounted && !isThisActive) {
        if (isThisPlaying) {
          setState(() {
            isThisPlaying = false;
            position = Duration.zero;
          });
        }
      }
    });
  }

  Future<void> _play() async {
    try {
      _ActivePlayerManager.setActive(widget.questionId, () {
        if (mounted) {
          setState(() {
            isThisActive = false;
            isThisPlaying = false;
            position = Duration.zero;
          });
        }
      });

      final startPos = Duration(milliseconds: ((widget.startSecond ?? 0) * 1000).toInt());
      final segmentDuration = widget.startSecond != null && widget.endSecond != null
          ? Duration(milliseconds: ((widget.endSecond! - widget.startSecond!) * 1000).toInt())
          : Duration.zero;

      setState(() {
        isThisActive = true;
        isThisPlaying = true;
        position = startPos;
        duration = segmentDuration;
      });

      await widget.player.setUrl(widget.url);
      await widget.player.seek(startPos);
      widget.player.play();
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final startMs = ((widget.startSecond ?? 0) * 1000).toInt();
    final relativePos = Duration(milliseconds: (position.inMilliseconds - startMs).clamp(0, duration.inMilliseconds));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isThisActive ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isThisActive ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (isThisActive && isThisPlaying) {
                widget.player.pause();
                setState(() => isThisPlaying = false);
              } else if (isThisActive && !isThisPlaying) {
                widget.player.play();
                setState(() => isThisPlaying = true);
              } else {
                _play();
              }
            },
            icon: Icon(
              isThisActive && isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, 
              color: const Color(0xFF6366F1), 
              size: 32
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(relativePos),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: const Color(0xFF6366F1),
                inactiveTrackColor: Colors.white10,
                thumbColor: const Color(0xFF6366F1),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble().clamp(
                  startMs.toDouble(), 
                  startMs.toDouble() + duration.inMilliseconds.toDouble()
                ),
                min: startMs.toDouble(),
                max: startMs.toDouble() + (duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                onChanged: (val) {
                  if (isThisActive) {
                    widget.player.seek(Duration(milliseconds: val.toInt()));
                  }
                },
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Simple manager to handle singleton playback across widgets
class _ActivePlayerManager {
  static dynamic _activeId;
  static VoidCallback? _onCancelPrevious;

  static void setActive(dynamic id, VoidCallback onCancel) {
    if (_activeId != id) {
      _onCancelPrevious?.call();
      _activeId = id;
      _onCancelPrevious = onCancel;
    }
  }
}
