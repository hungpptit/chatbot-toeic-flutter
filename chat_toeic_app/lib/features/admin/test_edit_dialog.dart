import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/features/admin/test_controller.dart';
import 'package:chat_toeic_app/core/api/upload_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class TestEditDialog extends StatefulWidget {
  final Map<String, dynamic> test;
  const TestEditDialog({super.key, required this.test});

  @override
  State<TestEditDialog> createState() => _TestEditDialogState();
}

class _TestEditDialogState extends State<TestEditDialog> {
  final controller = Get.find<TestController>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  // Track global audio
  Uint8List? _newAudioBytes;
  String? _newAudioName;
  double? _newAudioDuration;
  bool _isAudioUploading = false;
  late AudioPlayer _globalAudioPlayer;

  @override
  void initState() {
    super.initState();
    _globalAudioPlayer = AudioPlayer();
    _titleController = TextEditingController(text: widget.test['title']);
    _durationController = TextEditingController(text: widget.test['duration']);
    _loadQuestions();
  }

  @override
  void dispose() {
    _globalAudioPlayer.dispose();
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final data = await controller.fetchTestQuestions(widget.test['id']);
    if (mounted) {
      setState(() {
        // Deep copy questions to avoid modifying original until saved
        questions = data.map((q) => Map<String, dynamic>.from(q)).toList();
        isLoading = false;
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result != null && mounted) {
      setState(() {
        _newAudioBytes = result.files.first.bytes;
        _newAudioName = result.files.first.name;
        // Reset old URL since we have new bytes
      });
      Get.snackbar('Thông báo', 'Đã chọn audio mới, nhấn Lưu để hoàn tất');
    }
  }

  Future<void> _saveAll() async {
    if (!mounted) return;
    
    // Call background update and close dialog immediately
    controller.backgroundUpdateTest(
      testId: widget.test['id'],
      title: _titleController.text,
      duration: _durationController.text,
      questions: questions,
      newAudioBytes: _newAudioBytes,
      newAudioName: _newAudioName,
      existingAudioDuration: (questions.expand((q) => (q['mediaMappings'] as List? ?? [])).firstWhere(
        (m) => m['media']?['type'] == 'audio', 
        orElse: () => null)?['media']?['duration'] as num?)?.toDouble(),
    );

    Get.back(); // Close immediately
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
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF6366F1), size: 32),
                const SizedBox(width: 16),
                const Text('Chỉnh sửa bài thi', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.white54)),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    cacheExtent: 1000, 
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false, // Let items handle their own boundaries
                    itemCount: questions.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Section 1: Metadata
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Thông tin chung'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Tiêu đề', _titleController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Thời lượng (vd: 45 minutes)', _durationController)),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      } else if (index == 1) {
                        // Section 2: Audio
                        // Determine if this test has audio by checking questions
                        final existingAudioMapping = questions.expand((q) => (q['mediaMappings'] as List? ?? [])).firstWhere(
                          (m) => m['media']?['type'] == 'audio', 
                          orElse: () => null
                        );
                        final String? existingAudioUrl = existingAudioMapping?['media']?['url'];
                        
                        // If no audio exists and we haven't uploaded a new one, and it's likely a Reading test, hide this section
                        if (existingAudioUrl == null && _newAudioBytes == null) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('File nghe (Toàn bộ bài thi)'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                                gradient: LinearGradient(
                                  colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Tầng 1: Icon và Text thẳng hàng
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.music_note_rounded, color: Color(0xFF6366F1), size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _newAudioBytes != null ? 'Sẽ sử dụng audio mới vừa tải lên' : 'Đề thi đang sử dụng file nghe hệ thống',
                                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                            const Text(
                                              'File âm thanh này sẽ được dùng chung cho toàn bộ các câu hỏi Listening',
                                              style: TextStyle(color: Colors.white38, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  if (existingAudioUrl != null && _newAudioBytes == null) ...[
                                    const SizedBox(height: 20),
                                    // Tầng 2: Player và Button thẳng hàng
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MiniAudioPlayer(url: existingAudioUrl, player: _globalAudioPlayer),
                                        ),
                                        const SizedBox(width: 16),
                                        if (_isAudioUploading)
                                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                        else
                                          ElevatedButton.icon(
                                            onPressed: _pickAudio,
                                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                            label: const Text('Thay đổi Audio'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF6366F1),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 0,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ] else if (_newAudioBytes != null) ...[
                                     const SizedBox(height: 20),
                                     Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text('Đã chọn file mới: ', style: TextStyle(color: Colors.green, fontSize: 13)),
                                        Text(_newAudioName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        ElevatedButton.icon(
                                          onPressed: _pickAudio,
                                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                          label: const Text('Chọn file khác'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white10,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                     ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildSectionHeader('Danh sách câu hỏi (${questions.length})'),
                            const SizedBox(height: 24),
                          ],
                        );
                      }

                      // Section 3: Questions
                      final qIndex = index - 2;
                      return RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            children: [
                              _QuestionEditItem(
                                key: ValueKey('q_${questions[qIndex]['id']}'),
                                index: qIndex + 1,
                                question: questions[qIndex],
                                onChanged: () => setState(() {}),
                              ),
                              if (qIndex < questions.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Divider(color: Colors.white10),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            // Footer Action
            const Divider(height: 32, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Lưu tất cả', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _QuestionEditItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onChanged;
  const _QuestionEditItem({super.key, required this.index, required this.question, required this.onChanged});

  @override
  State<_QuestionEditItem> createState() => _QuestionEditItemState();
}

class _QuestionEditItemState extends State<_QuestionEditItem> {
  late TextEditingController _qController;
  late TextEditingController _aController;
  late TextEditingController _bController;
  late TextEditingController _cController;
  late TextEditingController _dController;
  late TextEditingController _expController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _qController = TextEditingController(text: widget.question['question']);
    _aController = TextEditingController(text: widget.question['optionA']);
    _bController = TextEditingController(text: widget.question['optionB']);
    _cController = TextEditingController(text: widget.question['optionC']);
    _dController = TextEditingController(text: widget.question['optionD']);
    _expController = TextEditingController(text: widget.question['explanation']);
    
    final audioMapping = (widget.question['mediaMappings'] as List?)?.firstWhere(
      (m) => m['media']?['type'] == 'audio', orElse: () => null);
    _startController = TextEditingController(text: (audioMapping?['startSecond'] ?? '').toString());
    _endController = TextEditingController(text: (audioMapping?['endSecond'] ?? '').toString());
    
    // Listen to changes
    _qController.addListener(() => widget.question['question'] = _qController.text);
    _aController.addListener(() => widget.question['optionA'] = _aController.text);
    _bController.addListener(() => widget.question['optionB'] = _bController.text);
    _cController.addListener(() => widget.question['optionC'] = _cController.text);
    _dController.addListener(() => widget.question['optionD'] = _dController.text);
    _expController.addListener(() => widget.question['explanation'] = _expController.text);
    _startController.addListener(() => widget.question['_newStartSecond'] = double.tryParse(_startController.text));
    _endController.addListener(() => widget.question['_newEndSecond'] = double.tryParse(_endController.text));
  }

  @override
  void dispose() {
    _qController.dispose();
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _dController.dispose();
    _expController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      // Check size limit: 10MB
      if (result.files.first.size > 10 * 1024 * 1024) {
        Get.snackbar('Lỗi', 'Dung lượng ảnh không được vượt quá 10MB');
        return;
      }

      if (mounted) setState(() => _isImageUploading = true);
      
      setState(() {
        widget.question['_newImageBytes'] = result.files.first.bytes;
        widget.question['_newImageName'] = result.files.first.name;
        _isImageUploading = false;
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = (widget.question['mediaMappings'] as List?) ?? [];
    final existingImageUrl = media.firstWhere((m) => m['media']?['type'] == 'image', orElse: () => null)?['media']?['url'];
    
    final newImageBytes = widget.question['_newImageBytes'] as Uint8List?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1),
              child: Text('${widget.index}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildSmallTextField('Nội dung câu hỏi', _qController)),
            if ([1, 2, 3, 4].contains(widget.question['partId'])) ...[
              const SizedBox(width: 12),
              SizedBox(width: 80, child: _buildSmallTextField('Start (s)', _startController)),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: _buildSmallTextField('End (s)', _endController)),
            ],
          ],
        ),
        
        const SizedBox(height: 16),
        // Image Preview and Upload
        if (newImageBytes != null || existingImageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (newImageBytes != null)
                  Image.memory(newImageBytes, height: 180, fit: BoxFit.cover, cacheHeight: 360)
                else
                  Image.network(existingImageUrl!, height: 180, fit: BoxFit.cover, cacheHeight: 360),
                if (_isImageUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image, size: 16),
          label: Text((newImageBytes != null || existingImageUrl != null) ? 'Thay đổi hình ảnh' : 'Thêm hình ảnh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: Colors.white10),
          ),
        ),

        const SizedBox(height: 20),
        // Options Rows (Faster than GridView shrinkWrap)
        Row(
          children: [
            Expanded(child: _buildOptionField('Đáp án A', _aController, 'A')),
            const SizedBox(width: 16),
            Expanded(child: _buildOptionField('Đáp án B', _bController, 'B')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildOptionField('Đáp án C', _cController, 'C')),
            const SizedBox(width: 16),
            Expanded(child: _buildOptionField('Đáp án D', _dController, 'D')),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildSmallTextField('Giải thích', _expController, maxLines: 2),
      ],
    );
  }

  Widget _buildSmallTextField(String label, TextEditingController controller, {int? maxLines = 1}) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines == 1 ? 1 : null, // Nếu là 1 thì giữ 1, nếu > 1 thì cho phép co giãn vô tận
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildOptionField(String label, TextEditingController controller, String value) {
    bool isCorrect = widget.question['correctAnswer'] == value;
    return Container(
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.08) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCorrect ? Colors.green.withOpacity(0.4) : Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: widget.question['correctAnswer'],
            onChanged: (val) {
              setState(() => widget.question['correctAnswer'] = val);
              widget.onChanged();
            },
            activeColor: Colors.green,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAudioPlayer extends StatefulWidget {
  final String url;
  final AudioPlayer player;
  const _MiniAudioPlayer({required this.url, required this.player});

  @override
  State<_MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<_MiniAudioPlayer> {
  final List<StreamSubscription> _subscriptions = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Set the URL only if not already set or different
      await widget.player.setUrl(widget.url);
      
      _subscriptions.add(widget.player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      }));
      _subscriptions.add(widget.player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      }));
      _subscriptions.add(widget.player.playerStateStream.listen((state) {
        if (mounted) setState(() => isPlaying = state.playing);
      }));
    } catch (e) {
      print("Error initializing mini player: $e");
    }
  }

  @override
  void dispose() {
    for (var s in _subscriptions) {
      s.cancel();
    }
    // We DON'T dispose the player here, it's managed by the parent
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              if (isPlaying) {
                widget.player.pause();
              } else {
                widget.player.play();
              }
            },
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_position),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: const Color(0xFF6366F1),
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                onChanged: (val) {
                  widget.player.seek(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_duration),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
