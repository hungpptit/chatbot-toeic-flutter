import 'dart:convert';
import 'dart:typed_data';

import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:chat_toeic_app/core/api/upload_service.dart';
import 'package:chat_toeic_app/features/admin/test_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:chat_toeic_app/core/utils/app_env.dart';

enum TestUploadMode { manual, json }

enum TestUploadType { listening, reading, mixed }

class QuestionDraft {
  static int _seed = 0;

  QuestionDraft({
    String? question,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctAnswer,
    String? explanation,
    int? typeId,
    int? skillId,
    int? partId,
    this.imagePath,
    this.audioPath,
    this.imageUrl,
    this.audioUrl,
    this.startSecond,
    this.endSecond,
  })  : id = '${DateTime.now().microsecondsSinceEpoch}_${_seed++}',
        question = question ?? '',
        optionA = optionA ?? '',
        optionB = optionB ?? '',
        optionC = optionC ?? '',
        optionD = optionD ?? '',
        correctAnswer = correctAnswer ?? 'A',
        explanation = explanation ?? '',
        typeId = typeId ?? 1,
        skillId = skillId ?? 1,
        partId = partId ?? 1;

  final String id;

  String question;
  String optionA;
  String optionB;
  String optionC;
  String optionD;
  String correctAnswer;
  String explanation;
  int typeId;
  int skillId;
  int partId;
  String? imagePath;
  String? audioPath;
  String? imageUrl;
  String? audioUrl;
  double? startSecond;
  double? endSecond;
  Uint8List? imageBytes;
  Uint8List? audioBytes;
  String? imageFileName;
  String? audioFileName;

  factory QuestionDraft.listening() {
    return QuestionDraft(typeId: 1, skillId: 6, partId: 1);
  }

  factory QuestionDraft.reading() {
    return QuestionDraft(typeId: 1, skillId: 1, partId: 5);
  }

  factory QuestionDraft.fromJson(Map<String, dynamic> json) {
    final draft = QuestionDraft(
      question: json['question']?.toString(),
      optionA: json['optionA']?.toString(),
      optionB: json['optionB']?.toString(),
      optionC: json['optionC']?.toString(),
      optionD: json['optionD']?.toString(),
      correctAnswer: json['correctAnswer']?.toString(),
      explanation: json['explanation']?.toString(),
      typeId: _toInt(json['typeId']) ?? 1,
      skillId: _toInt(json['skillId']) ?? 1,
      partId: _toInt(json['partId']) ?? 1,
      imagePath: json['imagePath']?.toString(),
      audioPath: json['audioPath']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      audioUrl: json['audioUrl']?.toString() ?? json['audio_url']?.toString(),
      startSecond: _toDouble(json['startSecond'] ?? json['start_second']),
      endSecond: _toDouble(json['endSecond'] ?? json['end_second']),
    );

    final media = json['media'];
    if (media is List) {
      for (final item in media) {
        if (item is Map) {
          final mediaItem = item.map((key, value) => MapEntry(key.toString(), value));
          final type = mediaItem['type']?.toString();
          final url = mediaItem['url']?.toString();
          if (type == 'image' && url != null && url.isNotEmpty) {
            draft.imageUrl = url;
          }
          if (type == 'audio' && url != null && url.isNotEmpty) {
            draft.audioUrl = url;
          }
        }
      }
    }

    return draft;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'question': question.trim(),
      'optionA': optionA.trim(),
      'optionB': optionB.trim(),
      'optionC': optionC.trim(),
      'optionD': optionD.trim(),
      'correctAnswer': correctAnswer.trim(),
      'explanation': explanation.trim(),
      'typeId': typeId,
      'skillId': skillId,
      'partId': partId,
    };

    if (imagePath != null && imagePath!.isNotEmpty) payload['imagePath'] = imagePath;
    if (audioPath != null && audioPath!.isNotEmpty) payload['audioPath'] = audioPath;
    if (imageUrl != null && imageUrl!.isNotEmpty) payload['imageUrl'] = imageUrl;
    if (audioUrl != null && audioUrl!.isNotEmpty) payload['audioUrl'] = audioUrl;
    if (startSecond != null) payload['startSecond'] = startSecond;
    if (endSecond != null) payload['endSecond'] = endSecond;
    return payload;
  }
}

class TestUploadDialog extends StatefulWidget {
  const TestUploadDialog({super.key});

  @override
  State<TestUploadDialog> createState() => _TestUploadDialogState();
}

class _TestUploadDialogState extends State<TestUploadDialog> {
  final TestController controller = Get.find<TestController>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '45 minutes');

  final List<Map<String, dynamic>> _courses = [];
  final List<QuestionDraft> _questions = [QuestionDraft.listening()];
  final List<QuestionDraft> _readingQuestions = [QuestionDraft.reading()];
  final List<QuestionDraft> _listeningQuestions = [QuestionDraft.listening()];

  TestUploadMode _uploadMode = TestUploadMode.manual;
  TestUploadType _testType = TestUploadType.listening;
  bool _isLoadingCourses = true;
  bool _isSubmitting = false;
  int? _selectedCourseId;

  Map<String, dynamic>? _parsedJson;
  String? _jsonFileName;
  String? _jsonMessage;

  Uint8List? _globalAudioBytes;
  String? _globalAudioFileName;
  String? _globalAudioUrl;
  String? _globalAudioLocalPath;

  late final AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _audioDuration = d);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isAudioPlaying = state.playing);
    });
    _loadCourses();
    _resetQuestions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      final response = await DioClient.dio.get('/v1/courses');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _courses
            ..clear()
            ..addAll(data.map((e) => Map<String, dynamic>.from(e)).toList());
          _selectedCourseId = _courses.isNotEmpty ? _toInt(_courses.first['id']) : null;
          _isLoadingCourses = false;
        });
      } else {
        setState(() => _isLoadingCourses = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCourses = false);
      Get.snackbar('Lỗi', 'Không thể tải danh sách khóa học: $e');
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _resetQuestions() {
    switch (_testType) {
      case TestUploadType.listening:
        if (_questions.isEmpty) _questions.add(QuestionDraft.listening());
        break;
      case TestUploadType.reading:
        if (_questions.isEmpty) _questions.add(QuestionDraft.reading());
        break;
      case TestUploadType.mixed:
        if (_readingQuestions.isEmpty) _readingQuestions.add(QuestionDraft.reading());
        if (_listeningQuestions.isEmpty) _listeningQuestions.add(QuestionDraft.listening());
        break;
    }
  }

  void _switchTestType(TestUploadType type) {
    setState(() {
      _testType = type;
      _parsedJson = null;
      _jsonFileName = null;
      _jsonMessage = null;
      _titleController.clear();
      _durationController.text = '45 minutes';
      _questions
        ..clear()
        ..add(type == TestUploadType.reading ? QuestionDraft.reading() : QuestionDraft.listening());
      _readingQuestions
        ..clear()
        ..add(QuestionDraft.reading());
      _listeningQuestions
        ..clear()
        ..add(QuestionDraft.listening());
    });
  }

  void _switchUploadMode(TestUploadMode mode) {
    setState(() {
      _uploadMode = mode;
      if (mode == TestUploadMode.manual) {
        _parsedJson = null;
        _jsonFileName = null;
        _jsonMessage = null;
      }
    });
  }

  List<QuestionDraft> _activeSingleQuestions() => _questions;

  Future<void> _pickGlobalAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      Get.snackbar('Lỗi', 'Không thể đọc file audio đã chọn');
      return;
    }

    setState(() {
      _globalAudioBytes = file.bytes;
      _globalAudioFileName = file.name;
      _globalAudioUrl = null;
      _globalAudioLocalPath = null;
      _audioPosition = Duration.zero;
      _audioDuration = Duration.zero;
    });

    await _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
    try {
      if (_globalAudioBytes != null) {
        await _audioPlayer.setAudioSource(MemoryAudioSource(_globalAudioBytes!));
      } else if (_globalAudioUrl != null && _globalAudioUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(_globalAudioUrl!);
      } else if (_globalAudioLocalPath != null && _globalAudioLocalPath!.isNotEmpty) {
        final url = _globalAudioLocalPath!.startsWith('http')
            ? _globalAudioLocalPath!
            : '${AppEnv.baseUrl}/admin/preview-local-file?path=${Uri.encodeComponent(_globalAudioLocalPath!)}';
        await _audioPlayer.setUrl(url);
      }
    } catch (e) {
      debugPrint("Error setting up audio player: $e");
    }
  }

  Widget _buildGlobalAudioSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Audio chung cho bài thi nghe', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickGlobalAudio,
                icon: const Icon(Icons.audiotrack_outlined, size: 18),
                label: Text(_globalAudioFileName == null && _globalAudioUrl == null ? 'Chọn file Audio' : 'Đổi file Audio'),
              ),
              if (_globalAudioFileName != null || _globalAudioUrl != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _globalAudioFileName ?? _globalAudioUrl ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _audioPlayer.stop();
                      _globalAudioBytes = null;
                      _globalAudioFileName = null;
                      _globalAudioUrl = null;
                      _globalAudioLocalPath = null;
                      _audioPosition = Duration.zero;
                      _audioDuration = Duration.zero;
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
              ],
            ],
          ),
          if (_globalAudioBytes != null || (_globalAudioUrl != null && _globalAudioUrl!.isNotEmpty) || (_globalAudioLocalPath != null && _globalAudioLocalPath!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_isAudioPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                    icon: Icon(
                      _isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: const Color(0xFF6366F1),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_audioPosition),
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
                        value: _audioPosition.inMilliseconds.toDouble().clamp(
                          0.0,
                          _audioDuration.inMilliseconds.toDouble() > 0 ? _audioDuration.inMilliseconds.toDouble() : 1.0,
                        ),
                        min: 0.0,
                        max: _audioDuration.inMilliseconds.toDouble() > 0 ? _audioDuration.inMilliseconds.toDouble() : 1.0,
                        onChanged: (val) {
                          _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_audioDuration),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      Get.snackbar('Lỗi', 'Không đọc được nội dung file JSON');
      return;
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON gốc phải là một object');
      }

      final hasMixedSections = decoded['readingQuestions'] is List || decoded['listeningQuestions'] is List;
      final hasSingleQuestions = decoded['questions'] is List;

      setState(() {
        _uploadMode = TestUploadMode.json;
        _parsedJson = decoded;
        _jsonFileName = file.name;
        _titleController.text = decoded['title']?.toString() ?? '';
        _durationController.text = decoded['duration']?.toString() ?? _durationController.text;
        final parsedCourseId = _toInt(decoded['courseId']);
        if (parsedCourseId != null) _selectedCourseId = parsedCourseId;

        _globalAudioUrl = decoded['audioUrl']?.toString() ?? decoded['audio_url']?.toString();
        final path = decoded['audioPath']?.toString() ?? decoded['audio_path']?.toString();
        _globalAudioLocalPath = path;
        if (path != null && path.isNotEmpty) {
          _globalAudioFileName = path.split(RegExp(r'[\\/]')).last;
        } else {
          _globalAudioFileName = null;
        }
        
        if (_globalAudioUrl != null && _globalAudioUrl!.isNotEmpty) {
          _setupAudioPlayer();
        } else if (_globalAudioLocalPath != null && _globalAudioLocalPath!.isNotEmpty) {
          _setupAudioPlayer();
        }

        if (hasMixedSections) {
          _testType = TestUploadType.mixed;
          _readingQuestions
            ..clear()
            ..addAll(_parseQuestions(decoded['readingQuestions'], fallbackToReading: true));
          _listeningQuestions
            ..clear()
            ..addAll(_parseQuestions(decoded['listeningQuestions'], fallbackToReading: false));
          if (_readingQuestions.isEmpty) _readingQuestions.add(QuestionDraft.reading());
          if (_listeningQuestions.isEmpty) _listeningQuestions.add(QuestionDraft.listening());
          _jsonMessage = 'Đã nạp đề dạng mixed từ file JSON';
        } else if (hasSingleQuestions) {
          _questions
            ..clear()
            ..addAll(_parseQuestions(decoded['questions'], fallbackToReading: _testType == TestUploadType.reading));
          if (_questions.isEmpty) {
            _questions.add(_testType == TestUploadType.reading ? QuestionDraft.reading() : QuestionDraft.listening());
          }
          _jsonMessage = 'Đã nạp ${_questions.length} câu từ file JSON';
        } else {
          _jsonMessage = 'File JSON không đúng định dạng đề thi đã hỗ trợ';
        }
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể đọc file JSON: $e');
    }
  }

  List<QuestionDraft> _parseQuestions(dynamic source, {required bool fallbackToReading}) {
    if (source is! List) return [];

    return source.whereType<Map>().map((item) {
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final draft = QuestionDraft.fromJson(map);
      if (draft.skillId == 1 && !fallbackToReading) {
        draft.skillId = 6;
      }
      if (fallbackToReading && draft.skillId == 6) {
        draft.skillId = 1;
      }
      return draft;
    }).toList();
  }

  Future<Map<String, dynamic>?> _buildManualPayload() async {
    if (_selectedCourseId == null) {
      Get.snackbar('Thiếu dữ liệu', 'Vui lòng chọn khóa học');
      return null;
    }

    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Thiếu dữ liệu', 'Vui lòng nhập tiêu đề đề thi');
      return null;
    }

    String? globalAudioUrl;
    if (_globalAudioBytes != null && _globalAudioFileName != null) {
      final uploadedAudio = await UploadService.uploadAudio(_globalAudioBytes!, _globalAudioFileName!);
      if (uploadedAudio != null && uploadedAudio['url'] != null) {
        globalAudioUrl = uploadedAudio['url'];
      }
    } else if (_globalAudioUrl != null) {
      globalAudioUrl = _globalAudioUrl;
    }

    if (_testType == TestUploadType.mixed) {
      final readingPayload = await _prepareManualQuestions(_readingQuestions, canUploadMedia: false);
      final listeningPayload = await _prepareManualQuestions(_listeningQuestions, canUploadMedia: true);
      return {
        'title': _titleController.text.trim(),
        'courseId': _selectedCourseId,
        if (_durationController.text.trim().isNotEmpty) 'duration': _durationController.text.trim(),
        'readingQuestions': readingPayload,
        'listeningQuestions': listeningPayload,
        if (globalAudioUrl != null) 'audioUrl': globalAudioUrl,
      };
    }

    final questions = await _prepareManualQuestions(_activeSingleQuestions(), canUploadMedia: _testType == TestUploadType.listening);
    return {
      'title': _titleController.text.trim(),
      'courseId': _selectedCourseId,
      if (_durationController.text.trim().isNotEmpty) 'duration': _durationController.text.trim(),
      'questions': questions,
      if (globalAudioUrl != null) 'audioUrl': globalAudioUrl,
    };
  }

  Future<List<Map<String, dynamic>>> _prepareManualQuestions(
    List<QuestionDraft> drafts, {
    required bool canUploadMedia,
  }) async {
    final result = <Map<String, dynamic>>[];

    for (final draft in drafts) {
      final payload = draft.toPayload();

      if (canUploadMedia && draft.imageBytes != null && draft.imageFileName != null) {
        final uploadedImage = await UploadService.uploadImage(draft.imageBytes!, draft.imageFileName!);
        if (uploadedImage != null && uploadedImage['url'] != null) {
          payload['imageUrl'] = uploadedImage['url'];
        }
      }

      if (canUploadMedia && draft.audioBytes != null && draft.audioFileName != null) {
        final uploadedAudio = await UploadService.uploadAudio(draft.audioBytes!, draft.audioFileName!);
        if (uploadedAudio != null && uploadedAudio['url'] != null) {
          payload['audioUrl'] = uploadedAudio['url'];
        }
      }

      result.add(payload);
    }

    return result;
  }

  Map<String, dynamic>? _buildJsonPayload() {
    if (_parsedJson == null) {
      Get.snackbar('Thiếu dữ liệu', 'Vui lòng chọn file JSON trước');
      return null;
    }

    final payload = jsonDecode(jsonEncode(_parsedJson!)) as Map<String, dynamic>;
    payload['title'] = _titleController.text.trim().isEmpty ? payload['title'] : _titleController.text.trim();
    payload['courseId'] = _selectedCourseId;
    if (_durationController.text.trim().isNotEmpty) {
      payload['duration'] = _durationController.text.trim();
    }
    if (_globalAudioUrl != null) {
      payload['audioUrl'] = _globalAudioUrl;
    }
    return payload;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      Map<String, dynamic>? payload;
      if (_uploadMode == TestUploadMode.manual) {
        payload = await _buildManualPayload();
      } else {
        payload = _buildJsonPayload();
      }

      if (payload == null) return;

      final result = await controller.createNewTest(payload);
      if (result != null && mounted) {
        Get.back();
        Get.snackbar('Thành công', 'Đã tạo đề thi mới');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Lỗi', 'Upload đề thi thất bại: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 1100 ? size.width - 24 : 1100.0;
    final dialogHeight = size.height < 900 ? size.height - 24 : size.height * 0.92;
    final isMobile = size.width < 700;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingCourses
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModeSection(isMobile: isMobile),
                          const SizedBox(height: 16),
                          _buildMetadataSection(isMobile: isMobile),
                          if (_testType == TestUploadType.listening || _testType == TestUploadType.mixed) ...[
                            const SizedBox(height: 20),
                            _buildGlobalAudioSection(),
                          ],
                          const SizedBox(height: 20),
                          if (_uploadMode == TestUploadMode.json) _buildJsonSection(),
                          if (_uploadMode == TestUploadMode.manual) _buildManualEditor(),
                          if (_uploadMode == TestUploadMode.json && _parsedJson != null) _buildJsonPreview(),
                        ],
                      ),
                    ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.upload_file_rounded, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upload đề thi mới', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Chọn kiểu đề, chế độ upload và nhập dữ liệu theo form hoặc file JSON.', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection({bool isMobile = false}) {
    final uploadModeGroup = _buildChoiceGroup(
      label: 'Kiểu upload',
      options: const [
        _ChoiceItem(label: 'Thủ công', value: TestUploadMode.manual),
        _ChoiceItem(label: 'JSON', value: TestUploadMode.json),
      ],
      groupValue: _uploadMode,
      onChanged: (value) => _switchUploadMode(value as TestUploadMode),
    );

    final testTypeGroup = _buildChoiceGroup(
      label: 'Loại đề',
      options: const [
        _ChoiceItem(label: 'Listening only', value: TestUploadType.listening),
        _ChoiceItem(label: 'Reading only', value: TestUploadType.reading),
        _ChoiceItem(label: 'Mixed', value: TestUploadType.mixed),
      ],
      groupValue: _testType,
      onChanged: (value) => _switchTestType(value as TestUploadType),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          uploadModeGroup,
          const SizedBox(height: 14),
          testTypeGroup,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: uploadModeGroup),
        const SizedBox(width: 16),
        Expanded(child: testTypeGroup),
      ],
    );
  }

  Widget _buildChoiceGroup({
    required String label,
    required List<_ChoiceItem> options,
    required Object groupValue,
    required ValueChanged<Object?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = groupValue == option.value;
              return ChoiceChip(
                label: Text(option.label),
                selected: selected,
                onSelected: (_) => onChanged(option.value),
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF111827),
                labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                side: BorderSide(color: selected ? const Color(0xFF6366F1) : Colors.white12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection({bool isMobile = false}) {
    final titleField = TextField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(labelText: 'Tiêu đề đề thi', hintText: 'Nhập tên đề thi'),
    );

    final courseDropdown = DropdownButtonFormField<int>(
      initialValue: _selectedCourseId,
      items: _courses.map((course) {
        final id = _toInt(course['id']);
        return DropdownMenuItem<int>(
          value: id,
          child: Text('${course['name'] ?? 'Course'} (#$id)', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCourseId = value),
      decoration: const InputDecoration(labelText: 'Khóa học'),
    );

    final durationField = TextField(
      controller: _durationController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(labelText: 'Thời lượng', hintText: '45 minutes'),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin chung', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (isMobile) ...[
            titleField,
            const SizedBox(height: 14),
            courseDropdown,
            const SizedBox(height: 14),
            durationField,
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: titleField,
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: courseDropdown,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: durationField,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJsonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Nhập file JSON', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: _pickJsonFile,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(_jsonFileName == null ? 'Chọn file JSON' : 'Đổi file JSON'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hỗ trợ file JSON không path và có path. Nếu có imagePath/audioPath, backend sẽ tự upload Cloudinary trước khi lưu đề.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontSize: 12),
          ),
          if (_jsonFileName != null) ...[
            const SizedBox(height: 10),
            Text('File: $_jsonFileName', style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13)),
          ],
          if (_jsonMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(_jsonMessage!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJsonPreview() {
    final readingCount = (_parsedJson?['readingQuestions'] as List?)?.length ?? 0;
    final listeningCount = (_parsedJson?['listeningQuestions'] as List?)?.length ?? 0;
    final singleCount = (_parsedJson?['questions'] as List?)?.length ?? 0;
    final hasPaths = _jsonHasPaths(_parsedJson!);
    final previewQuestions = _extractPreviewQuestions(_parsedJson!);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dữ liệu đã nạp từ JSON', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Title: ${_parsedJson!['title'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                Text('CourseId: ${_parsedJson!['courseId'] ?? '-'}', style: const TextStyle(color: Colors.white70)),
                Text('Thời lượng: ${_parsedJson!['duration'] ?? _durationController.text}', style: const TextStyle(color: Colors.white70)),
                Text('Single questions: $singleCount | Reading: $readingCount | Listening: $listeningCount', style: const TextStyle(color: Colors.white70)),
                Text('Có local path: ${hasPaths ? 'Có' : 'Không'}', style: TextStyle(color: hasPaths ? const Color(0xFF34D399) : Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (previewQuestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xem trước câu hỏi (${previewQuestions.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...previewQuestions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == previewQuestions.length - 1 ? 0 : 12),
                      child: _QuestionPreviewCard(
                        index: index + 1,
                        question: question,
                        showMediaPaths: hasPaths,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<QuestionDraft> _extractPreviewQuestions(Map<String, dynamic> payload) {
    final questions = <QuestionDraft>[];

    final single = payload['questions'];
    if (single is List) {
      questions.addAll(_parseQuestions(single, fallbackToReading: _testType == TestUploadType.reading));
    }

    final reading = payload['readingQuestions'];
    if (reading is List) {
      questions.addAll(_parseQuestions(reading, fallbackToReading: true));
    }

    final listening = payload['listeningQuestions'];
    if (listening is List) {
      questions.addAll(_parseQuestions(listening, fallbackToReading: false));
    }

    return questions;
  }

  bool _jsonHasPaths(Map<String, dynamic> payload) {
    bool checkQuestion(Map<String, dynamic> question) {
      return (question['imagePath']?.toString().isNotEmpty ?? false) ||
          (question['audioPath']?.toString().isNotEmpty ?? false);
    }

    final questions = payload['questions'];
    if (questions is List && questions.any((item) => item is Map && checkQuestion(item.map((key, value) => MapEntry(key.toString(), value))))) {
      return true;
    }

    final reading = payload['readingQuestions'];
    if (reading is List && reading.any((item) => item is Map && checkQuestion(item.map((key, value) => MapEntry(key.toString(), value))))) {
      return true;
    }

    final listening = payload['listeningQuestions'];
    if (listening is List && listening.any((item) => item is Map && checkQuestion(item.map((key, value) => MapEntry(key.toString(), value))))) {
      return true;
    }

    return payload['audioPath']?.toString().isNotEmpty ?? false;
  }

  Widget _buildManualEditor() {
    switch (_testType) {
      case TestUploadType.listening:
        return _buildQuestionSection(
          title: 'Câu hỏi Listening',
          questions: _questions,
          allowMedia: true,
          onAdd: () => setState(() => _questions.add(QuestionDraft.listening())),
          onRemoveLast: () => setState(() {
            if (_questions.length > 1) _questions.removeLast();
          }),
        );
      case TestUploadType.reading:
        return _buildQuestionSection(
          title: 'Câu hỏi Reading',
          questions: _questions,
          allowMedia: false,
          onAdd: () => setState(() => _questions.add(QuestionDraft.reading())),
          onRemoveLast: () => setState(() {
            if (_questions.length > 1) _questions.removeLast();
          }),
        );
      case TestUploadType.mixed:
        return Column(
          children: [
            _buildQuestionSection(
              title: 'Reading questions',
              questions: _readingQuestions,
              allowMedia: false,
              onAdd: () => setState(() => _readingQuestions.add(QuestionDraft.reading())),
              onRemoveLast: () => setState(() {
                if (_readingQuestions.length > 1) _readingQuestions.removeLast();
              }),
            ),
            const SizedBox(height: 18),
            _buildQuestionSection(
              title: 'Listening questions',
              questions: _listeningQuestions,
              allowMedia: true,
              onAdd: () => setState(() => _listeningQuestions.add(QuestionDraft.listening())),
              onRemoveLast: () => setState(() {
                if (_listeningQuestions.length > 1) _listeningQuestions.removeLast();
              }),
            ),
          ],
        );
    }
  }

  Widget _buildQuestionSection({
    required String title,
    required List<QuestionDraft> questions,
    required bool allowMedia,
    required VoidCallback onAdd,
    required VoidCallback onRemoveLast,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('$title (${questions.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Thêm câu')),
              const SizedBox(width: 8),
              TextButton.icon(onPressed: onRemoveLast, icon: const Icon(Icons.remove, size: 18), label: const Text('Bớt câu')),
            ],
          ),
          const SizedBox(height: 12),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == questions.length - 1 ? 0 : 16),
              child: _QuestionDraftCard(
                key: ValueKey(question.id),
                title: 'Câu ${index + 1}',
                draft: question,
                allowMedia: allowMedia,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Get.back(),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_isSubmitting ? 'Đang upload...' : 'Tạo đề thi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final int index;
  final QuestionDraft question;
  final bool showMediaPaths;

  const _QuestionPreviewCard({required this.index, required this.question, required this.showMediaPaths});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Câu $index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Text('partId: ${question.partId} | skillId: ${question.skillId} | typeId: ${question.typeId}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(question.question.isEmpty ? '(Chưa có nội dung câu hỏi)' : question.question, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _buildOption('A', question.optionA),
          _buildOption('B', question.optionB),
          _buildOption('C', question.optionC),
          _buildOption('D', question.optionD),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTag('Correct: ${question.correctAnswer}'),
              const SizedBox(width: 8),
              if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
                _buildTag('Image URL'),
                const SizedBox(width: 8),
              ],
              if (question.imagePath != null && question.imagePath!.isNotEmpty) ...[
                _buildTag('Image Path'),
                const SizedBox(width: 8),
              ],
              if (question.audioUrl != null && question.audioUrl!.isNotEmpty) ...[
                _buildTag('Audio URL'),
                const SizedBox(width: 8),
              ],
              if (question.audioPath != null && question.audioPath!.isNotEmpty) ...[
                _buildTag('Audio Path'),
                const SizedBox(width: 8),
              ],
              if (question.startSecond != null || question.endSecond != null)
                _buildTag('Timing: ${question.startSecond ?? 0}s - ${question.endSecond ?? 0}s'),
            ],
          ),
          if (showMediaPaths) ...[
            const SizedBox(height: 8),
            if (question.imagePath != null && question.imagePath!.isNotEmpty)
              Text('imagePath: ${question.imagePath}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            if (question.audioPath != null && question.audioPath!.isNotEmpty)
              Text('audioPath: ${question.audioPath}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                question.imageUrl!,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ] else if (question.imagePath != null && question.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                question.imagePath!.startsWith('http')
                    ? question.imagePath!
                    : '${AppEnv.baseUrl}/admin/preview-local-file?path=${Uri.encodeComponent(question.imagePath!)}',
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (question.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Explanation: ${question.explanation}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label. $value', style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}

class _QuestionDraftCard extends StatefulWidget {
  final String title;
  final QuestionDraft draft;
  final bool allowMedia;

  const _QuestionDraftCard({super.key, required this.title, required this.draft, required this.allowMedia});

  @override
  State<_QuestionDraftCard> createState() => _QuestionDraftCardState();
}

class _QuestionDraftCardState extends State<_QuestionDraftCard> {
  late final TextEditingController _questionController;
  late final TextEditingController _optionAController;
  late final TextEditingController _optionBController;
  late final TextEditingController _optionCController;
  late final TextEditingController _optionDController;
  late final TextEditingController _explanationController;
  late final TextEditingController _typeIdController;
  late final TextEditingController _skillIdController;
  late final TextEditingController _partIdController;
  late final TextEditingController _startSecondController;
  late final TextEditingController _endSecondController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.draft.question);
    _optionAController = TextEditingController(text: widget.draft.optionA);
    _optionBController = TextEditingController(text: widget.draft.optionB);
    _optionCController = TextEditingController(text: widget.draft.optionC);
    _optionDController = TextEditingController(text: widget.draft.optionD);
    _explanationController = TextEditingController(text: widget.draft.explanation);
    _typeIdController = TextEditingController(text: widget.draft.typeId.toString());
    _skillIdController = TextEditingController(text: widget.draft.skillId.toString());
    _partIdController = TextEditingController(text: widget.draft.partId.toString());
    _startSecondController = TextEditingController(text: widget.draft.startSecond?.toString() ?? '');
    _endSecondController = TextEditingController(text: widget.draft.endSecond?.toString() ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _explanationController.dispose();
    _typeIdController.dispose();
    _skillIdController.dispose();
    _partIdController.dispose();
    _startSecondController.dispose();
    _endSecondController.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool isImage}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.audio,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      Get.snackbar('Lỗi', 'Không thể đọc file đã chọn');
      return;
    }

    setState(() {
      if (isImage) {
        widget.draft.imageBytes = file.bytes;
        widget.draft.imageFileName = file.name;
        widget.draft.imagePath = null;
      } else {
        widget.draft.audioBytes = file.bytes;
        widget.draft.audioFileName = file.name;
        widget.draft.audioPath = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncDraft();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            onChanged: (_) => _syncDraft(),
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Câu hỏi', hintText: 'Nhập nội dung câu hỏi'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildOptionField('A', _optionAController)),
              const SizedBox(width: 10),
              Expanded(child: _buildOptionField('B', _optionBController)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildOptionField('C', _optionCController)),
              const SizedBox(width: 10),
              Expanded(child: _buildOptionField('D', _optionDController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.draft.correctAnswer,
                  items: const ['A', 'B', 'C', 'D']
                      .map((value) => DropdownMenuItem<String>(value: value, child: Text('Đáp án $value')))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => widget.draft.correctAnswer = value);
                  },
                  decoration: const InputDecoration(labelText: 'Đáp án đúng'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _explanationController,
                  onChanged: (_) => _syncDraft(),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Giải thích'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildNumberField('typeId', _typeIdController)),
              const SizedBox(width: 10),
              Expanded(child: _buildNumberField('skillId', _skillIdController)),
              const SizedBox(width: 10),
              Expanded(child: _buildNumberField('partId', _partIdController)),
            ],
          ),
          if (widget.allowMedia) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startSecondController,
                    onChanged: (_) => _syncDraft(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Start second', hintText: '0.0'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _endSecondController,
                    onChanged: (_) => _syncDraft(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'End second', hintText: '15.5'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickFile(isImage: true),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(widget.draft.imageBytes != null ? 'Đã chọn ảnh' : 'Chọn ảnh'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickFile(isImage: false),
                  icon: const Icon(Icons.audiotrack_outlined, size: 18),
                  label: Text(widget.draft.audioBytes != null ? 'Đã chọn audio' : 'Chọn audio'),
                ),
                if (widget.draft.imageFileName != null)
                  Chip(label: Text('Image: ${widget.draft.imageFileName}')),
                if (widget.draft.audioFileName != null)
                  Chip(label: Text('Audio: ${widget.draft.audioFileName}')),
              ],
            ),
            if (widget.draft.imageBytes != null) ...[
              const SizedBox(height: 10),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      widget.draft.imageBytes!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.draft.imageBytes = null;
                          widget.draft.imageFileName = null;
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOptionField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => _syncDraft(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: 'Option $label', hintText: 'Đáp án $label'),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => _syncDraft(),
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  void _syncDraft() {
    widget.draft.question = _questionController.text;
    widget.draft.optionA = _optionAController.text;
    widget.draft.optionB = _optionBController.text;
    widget.draft.optionC = _optionCController.text;
    widget.draft.optionD = _optionDController.text;
    widget.draft.explanation = _explanationController.text;
    widget.draft.typeId = int.tryParse(_typeIdController.text.trim()) ?? widget.draft.typeId;
    widget.draft.skillId = int.tryParse(_skillIdController.text.trim()) ?? widget.draft.skillId;
    widget.draft.partId = int.tryParse(_partIdController.text.trim()) ?? widget.draft.partId;
    widget.draft.startSecond = double.tryParse(_startSecondController.text.trim());
    widget.draft.endSecond = double.tryParse(_endSecondController.text.trim());
  }
}

class _ChoiceItem {
  final String label;
  final Object value;

  const _ChoiceItem({required this.label, required this.value});
}

class MemoryAudioSource extends StreamAudioSource {
  final List<int> _bytes;
  MemoryAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}