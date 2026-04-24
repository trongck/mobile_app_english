import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math' as math;

// ════════════════════════════════════════════════════════════════════════════
//  CONSTANTS
// ════════════════════════════════════════════════════════════════════════════
const _kGeminiKey = 'AIzaSyBedtMIrCS20y5lgMY-C-RN13m7-7AAWLg';
const _kGeminiModel = 'gemini-3-flash-preview';
const _kGeminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$_kGeminiModel:generateContent?key=$_kGeminiKey';

// ════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ════════════════════════════════════════════════════════════════════════════
enum ChatMode { freeChat, vocabLearn, pronunciation, quiz }

// Ngôn ngữ nhận diện giọng nói
enum MicLang { vietnamese, english, auto }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isLoading;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isLoading = false,
  });
}

// ════════════════════════════════════════════════════════════════════════════
//  LANGUAGE DETECTOR
// ════════════════════════════════════════════════════════════════════════════
class LangDetector {
  /// Trả về tỉ lệ ký tự Latin trong chuỗi (0.0 – 1.0).
  static double latinRatio(String text) {
    if (text.isEmpty) return 0;
    final latin = RegExp(r'[a-zA-Z]').allMatches(text).length;
    return latin / text.length;
  }

  /// Nhận diện ngôn ngữ chính của đoạn text.
  /// Trả về 'vi' hoặc 'en'.
  static String detect(String text) {
    // Dấu thanh tiếng Việt
    final viMarkers = RegExp(
        r'[àáâãèéêìíòóôõùúýăđơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]',
        caseSensitive: false);
    final viCount = viMarkers.allMatches(text).length;
    if (viCount > 2) return 'vi';
    if (latinRatio(text) > 0.5) return 'en';
    return 'vi'; // mặc định tiếng Việt
  }

  /// Tách văn bản thành các đoạn theo ngôn ngữ.
  /// Trả về list [{'lang': 'vi'/'en', 'text': '...'}]
  static List<Map<String, String>> splitByLang(String text) {
    // Loại bỏ markdown
    String clean = text
        .replaceAllMapped(
            RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? '')
        .replaceAll(RegExp(r'^[•\-\*📚🔤💡🔥🎤🧠💬→]+\s*', multiLine: true), '')
        // Xóa emoji
        .replaceAll(
            RegExp(
                r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+',
                unicode: true),
            '');

    final lines = clean.split('\n').map((l) => l.trim()).where((l) => l.length > 2).toList();
    if (lines.isEmpty) return [];

    final segments = <Map<String, String>>[];
    String? curLang;
    final buf = StringBuffer();

    for (final line in lines) {
      final lang = detect(line);
      if (curLang == null) {
        curLang = lang;
        buf.write(line);
      } else if (lang == curLang) {
        buf.write('. $line');
      } else {
        // Ngôn ngữ thay đổi → flush
        final t = buf.toString().trim();
        if (t.isNotEmpty) segments.add({'lang': curLang, 'text': t});
        buf.clear();
        buf.write(line);
        curLang = lang;
      }
    }
    final t = buf.toString().trim();
    if (t.isNotEmpty && curLang != null) {
      segments.add({'lang': curLang, 'text': t});
    }
    return segments;
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  GEMINI SERVICE
// ════════════════════════════════════════════════════════════════════════════
class GeminiService {
  static Future<String> sendMessage({
    required List<Map<String, dynamic>> history,
    required String userMessage,
    required ChatMode mode,
  }) async {
    final systemPrompt = _buildSystemPrompt(mode);

    final contents = <Map<String, dynamic>>[];

    contents.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt}
      ],
    });
    contents.add({
      'role': 'model',
      'parts': [
        {'text': 'Understood! I am ready to help you learn English.'}
      ],
    });

    for (final msg in history) {
      contents.add(msg);
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final body = json.encode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.8,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
      ],
    });

    final response = await http
        .post(
          Uri.parse(_kGeminiUrl),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
    } else {
      throw Exception(
          'Gemini API error ${response.statusCode}: ${response.body}');
    }
  }

  static String _buildSystemPrompt(ChatMode mode) {
    switch (mode) {
      case ChatMode.freeChat:
        return '''You are DevTalk AI — a friendly English tutor for Vietnamese IT developers.
Rules:
- Respond in Vietnamese explanation + English examples
- Correct grammar mistakes gently
- Provide IT-context examples (code, projects, meetings)
- Keep responses concise (2-4 sentences unless explaining vocabulary)
- Encourage the user frequently''';

      case ChatMode.vocabLearn:
        return '''You are DevTalk AI — a vocabulary teaching assistant for IT English.
When user gives a word/phrase, provide:
📚 **[WORD]** /phonetic/
🔤 *[part of speech]* — [Vietnamese meaning]
💡 Example 1: [sentence]
💡 Example 2: [sentence]
🔥 Tip: [memory trick]
Then ask user to use the word in a sentence. Evaluate and praise their attempt.''';

      case ChatMode.pronunciation:
        return '''You are DevTalk AI — a pronunciation coach for IT English.
Help users with pronunciation of technical terms (API, GUI, SQL, etc.).
Provide phonetic spelling, pronunciation tips, and warn about common mispronunciations for Vietnamese speakers.
Keep an encouraging tone.''';

      case ChatMode.quiz:
        return '''You are DevTalk AI — conducting an IT English vocabulary quiz.
Ask one question at a time. Types: multiple choice, fill-in-blank, translate to English, use in a sentence.
Give feedback after each answer. Keep score and report after every 5 questions.
Focus on IT vocabulary: programming, cloud, AI, DevOps. Make it fun!''';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ════════════════════════════════════════════════════════════════════════════
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _history = [];

  late AnimationController _bgAnim;
  late AnimationController _aiTypingAnim;
  late AnimationController _micPulseAnim;

  ChatMode _mode = ChatMode.freeChat;
  // Ngôn ngữ mic hiện tại — mặc định Auto (nhận cả 2)
  MicLang _micLang = MicLang.auto;

  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;

  // ── STT ─────────────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _sttInitialized = false;

  // ── TTS ─────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  static const _modeColors = {
    ChatMode.freeChat: Color(0xFF00D4FF),
    ChatMode.vocabLearn: Color(0xFF7B2FFF),
    ChatMode.pronunciation: Color(0xFF00FF94),
    ChatMode.quiz: Color(0xFFFFD700),
  };

  Color get _activeColor => _modeColors[_mode]!;

  // ── STT locale theo lựa chọn người dùng ─────────────────────────────────
  String get _sttLocale {
    switch (_micLang) {
      case MicLang.vietnamese:
        return 'vi_VN';
      case MicLang.english:
        return 'en_US';
      case MicLang.auto:
        // speech_to_text không có true "auto" — dùng vi_VN làm mặc định
        // vì người dùng thường nói tiếng Việt khi chọn auto.
        // Nếu muốn 100% tiếng Anh hãy chọn EN.
        return 'vi_VN';
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _aiTypingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _micPulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _initTts();
    _initSpeech();
    _addWelcomeMessage();
  }

  // ── TTS init ─────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    try {
      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((msg) {
        debugPrint('[TTS] Error: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });

      await _tts.setLanguage('vi-VN'); // mặc định tiếng Việt
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);

      _ttsReady = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[TTS] Init error: $e');
      try {
        await _tts.setLanguage('vi-VN');
        await _tts.setSpeechRate(0.5);
        await _tts.awaitSpeakCompletion(false);
        _ttsReady = true;
        if (mounted) setState(() {});
      } catch (_) {
        _ttsReady = false;
      }
    }
  }

  // ── STT init ─────────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    if (_sttInitialized) return;
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'doneNoResult') {
            if (mounted && _isListening) setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('[STT] Error: ${error.errorMsg}');
          if (!mounted) return;
          if (mounted) setState(() => _isListening = false);
          if (error.errorMsg != 'error_speech_timeout' &&
              error.errorMsg != 'error_no_match' &&
              error.errorMsg != 'error_busy') {
            _showSnack('Lỗi mic: ${error.errorMsg}');
          }
        },
        debugLogging: false,
      );

      _sttInitialized = available;
      _speechAvailable = available;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[STT] Init error: $e');
      _sttInitialized = false;
      _speechAvailable = false;
      if (mounted) setState(() {});
    }
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: '👋 Xin chào! Tôi là **DevTalk AI**, trợ lý học tiếng Anh IT của bạn.\n\n'
              'Tôi có thể giúp bạn:\n'
              '• 💬 Trò chuyện tiếng Anh tự nhiên\n'
              '• 📚 Học từ vựng IT chuyên sâu\n'
              '• 🎤 Luyện phát âm thuật ngữ kỹ thuật\n'
              '• 🧠 Quiz kiểm tra từ vựng\n\n'
              'Chọn ngôn ngữ mic (🇻🇳/🇺🇸/🔄) và chế độ học ở trên, rồi bắt đầu nào! 🚀',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _bgAnim.dispose();
    _aiTypingAnim.dispose();
    _micPulseAnim.dispose();
    if (_isListening) _speech.stop();
    if (_isSpeaking) _tts.stop();
    super.dispose();
  }

  // ── Send message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    _inputCtrl.clear();

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _messages.add(
          ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
      _messages.add(ChatMessage(
          text: '', isUser: false, time: DateTime.now(), isLoading: true));
    });
    _scrollToBottom();

    try {
      final response = await GeminiService.sendMessage(
        history: List<Map<String, dynamic>>.from(_history),
        userMessage: text,
        mode: _mode,
      );

      _history.add({
        'role': 'user',
        'parts': [
          {'text': text}
        ]
      });
      _history.add({
        'role': 'model',
        'parts': [
          {'text': response}
        ]
      });

      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(
              text: response, isUser: false, time: DateTime.now()));
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Đọc TTS đa ngôn ngữ
      if (_ttsEnabled && _ttsReady && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        await _speakBilingual(response);
      }
    } catch (e) {
      debugPrint('[Chat] Error: $e');
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(
            text: '⚠️ Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
            isUser: false,
            time: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  // ── TTS đa ngôn ngữ: tách đoạn VI / EN rồi đọc lần lượt ────────────────
  Future<void> _speakBilingual(String text) async {
    if (!_ttsReady || !mounted) return;

    final segments = LangDetector.splitByLang(text);
    if (segments.isEmpty) return;

    // Giới hạn tối đa 4 đoạn để không quá dài
    final limited = segments.take(4).toList();

    for (final seg in limited) {
      if (!mounted || !_ttsEnabled) break;

      final lang = seg['lang']!;
      final segText = seg['text']!;
      if (segText.isEmpty) continue;

      try {
        if (_isSpeaking) {
          await _tts.stop();
          await Future.delayed(const Duration(milliseconds: 150));
        }

        // Chọn ngôn ngữ TTS phù hợp
        if (lang == 'vi') {
          await _tts.setLanguage('vi-VN');
          await _tts.setSpeechRate(0.85);
        } else {
          await _tts.setLanguage('en-US');
          await _tts.setSpeechRate(0.75);
        }

        debugPrint('[TTS] [$lang] Speaking: "$segText"');
        await _tts.speak(segText);

        // Chờ đoạn này đọc xong trước khi sang đoạn kế tiếp
        // Ước lượng thời gian dựa trên độ dài text
        final waitMs = (segText.length * 60).clamp(500, 4000);
        await Future.delayed(Duration(milliseconds: waitMs));
      } catch (e) {
        debugPrint('[TTS] Bilingual speak error: $e');
        if (mounted) setState(() => _isSpeaking = false);
      }
    }

    if (mounted) setState(() => _isSpeaking = false);
  }

  // ── Speak một đoạn an toàn (dùng cho nút đọc lại) ───────────────────────
  Future<void> _speakSafe(String text) async {
    if (!_ttsReady || text.isEmpty || !mounted) return;
    try {
      if (_isSpeaking) {
        await _tts.stop();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await _speakBilingual(text);
    } catch (e) {
      debugPrint('[TTS] speakSafe error: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  // ── Toggle microphone ────────────────────────────────────────────────────
  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 150));
      final pending = _inputCtrl.text.trim();
      if (pending.isNotEmpty) _sendMessage(pending);
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!_sttInitialized) await _initSpeech();

    if (!_speechAvailable) {
      _showSnack(
          'Microphone chưa được cấp quyền. Vào Cài đặt → Ứng dụng → Cấp quyền Micro.');
      return;
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _inputCtrl.clear();
    setState(() => _isListening = true);

    final locale = _sttLocale;

    try {
      debugPrint('[STT] Starting listen with locale: $locale');
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _inputCtrl.text = result.recognizedWords);
          if (result.finalResult &&
              result.recognizedWords.trim().isNotEmpty) {
            setState(() => _isListening = false);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _sendMessage(result.recognizedWords.trim());
            });
          }
        },
        localeId: locale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('[STT] listen error: $e');
      setState(() => _isListening = false);
      _sttInitialized = false;
      _speechAvailable = false;
      await _initSpeech();
      if (_speechAvailable) {
        _showSnack('Thử lại, nhấn mic lần nữa');
      } else {
        _showSnack('Không thể dùng mic: $e');
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeMode(ChatMode mode) {
    HapticFeedback.mediumImpact();
    setState(() {
      _mode = mode;
      _history.clear();
    });

    final modeNames = {
      ChatMode.freeChat: '💬 Trò chuyện tự do',
      ChatMode.vocabLearn: '📚 Học từ vựng',
      ChatMode.pronunciation: '🎤 Luyện phát âm',
      ChatMode.quiz: '🧠 Quiz kiểm tra',
    };
    final modeIntros = {
      ChatMode.freeChat:
          'Chế độ trò chuyện tự do! Viết hoặc nói bất kỳ điều gì. 💬',
      ChatMode.vocabLearn:
          'Chế độ học từ vựng! Gửi từ IT bạn muốn học (ví dụ: "microservice"). 📚',
      ChatMode.pronunciation:
          'Chế độ luyện phát âm! Gửi thuật ngữ bạn muốn học cách đọc (ví dụ: "SQL"). 🎤',
      ChatMode.quiz: 'Quiz IT English bắt đầu! Gõ "bắt đầu" để chơi! 🧠',
    };

    setState(() {
      _messages.add(ChatMessage(
        text: '--- ${modeNames[mode]} ---\n\n${modeIntros[mode]}',
        isUser: false,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A1F35),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => CustomPaint(
            size: size,
            painter: _ChatBgPainter(_bgAnim.value, _activeColor),
          ),
        ),
        CustomPaint(size: size, painter: _GridPainter()),

        SafeArea(
          bottom: false,
          child: Column(children: [
            _buildHeader(),
            _buildModeSelector(),
            _buildMicLangSelector(),
            if (_isListening) _buildListeningBanner(),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) =>
                          _buildMessageBubble(_messages[i], i),
                    ),
            ),
            _buildInputBar(bottomPad),
          ]),
        ),
      ]),
    );
  }

  // ── Mic language selector ────────────────────────────────────────────────
  Widget _buildMicLangSelector() {
    final langs = [
      (MicLang.auto, '🔄', 'Tự động'),
      (MicLang.vietnamese, '🇻🇳', 'Tiếng Việt'),
      (MicLang.english, '🇺🇸', 'English'),
    ];

    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          Text('Mic:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ...langs.map((l) {
            final isActive = _micLang == l.$1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _micLang = l.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? _activeColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? _activeColor.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(l.$2, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    l.$3,
                    style: TextStyle(
                      color: isActive
                          ? _activeColor
                          : Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Listening banner ──────────────────────────────────────────────────────
  Widget _buildListeningBanner() {
    final langLabel = _micLang == MicLang.vietnamese
        ? '🇻🇳 Đang nghe tiếng Việt...'
        : _micLang == MicLang.english
            ? '🇺🇸 Listening in English...'
            : '🔄 Đang nghe... (VI/EN)';

    return AnimatedBuilder(
      animation: _micPulseAnim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              _activeColor.withOpacity(0.1 + _micPulseAnim.value * 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _activeColor.withOpacity(0.4), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mic_rounded, color: _activeColor, size: 16),
          const SizedBox(width: 8),
          Text(
            '$langLabel  •  Nhấn mic để gửi',
            style: TextStyle(
                color: _activeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        AnimatedBuilder(
          animation: _aiTypingAnim,
          builder: (_, __) {
            final glowOp =
                _isLoading ? (0.3 + _aiTypingAnim.value * 0.4) : 0.3;
            return Stack(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _activeColor.withOpacity(glowOp),
                        blurRadius: 16,
                        spreadRadius: 2)
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_activeColor, const Color(0xFF7B2FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 22),
              ),
              if (_isLoading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF94),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF080B1A), width: 2),
                    ),
                  ),
                ),
            ]);
          },
        ),

        const SizedBox(width: 12),

        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DevTalk AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isLoading
                    ? 'Đang suy nghĩ...'
                    : _isListening
                        ? '🎤 Đang nghe...'
                        : _isSpeaking
                            ? '🔊 Đang đọc...'
                            : 'VI 🇻🇳 + EN 🇺🇸 | Powered by Gemini',
                key: ValueKey(
                    '$_isLoading$_isListening$_isSpeaking'),
                style: TextStyle(
                    color: _activeColor.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),

        // TTS toggle
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (_isSpeaking) {
              await _tts.stop();
              setState(() => _isSpeaking = false);
            }
            setState(() => _ttsEnabled = !_ttsEnabled);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ttsEnabled
                  ? _activeColor.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _ttsEnabled
                      ? _activeColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1)),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(
                _ttsEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: _isSpeaking
                    ? _activeColor
                    : _ttsEnabled
                        ? _activeColor
                        : Colors.white.withOpacity(0.3),
                size: 18,
              ),
              if (_isSpeaking)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00FF94),
                        shape: BoxShape.circle),
                  ),
                ),
            ]),
          ),
        ),

        const SizedBox(width: 8),

        // Clear chat
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _messages.clear();
              _history.clear();
            });
            _addWelcomeMessage();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(Icons.refresh_rounded,
                color: Colors.white.withOpacity(0.5), size: 18),
          ),
        ),
      ]),
    );
  }

  // ── Mode selector ─────────────────────────────────────────────────────────
  Widget _buildModeSelector() {
    final modes = [
      (ChatMode.freeChat, '💬', 'Chat'),
      (ChatMode.vocabLearn, '📚', 'Từ vựng'),
      (ChatMode.pronunciation, '🎤', 'Phát âm'),
      (ChatMode.quiz, '🧠', 'Quiz'),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: modes.map((m) {
          final isActive = _mode == m.$1;
          final color = _modeColors[m.$1]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeMode(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withOpacity(0.18)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isActive
                          ? color.withOpacity(0.5)
                          : Colors.white.withOpacity(0.08)),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 8)
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.$2,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(m.$3,
                          style: TextStyle(
                            color: isActive
                                ? color
                                : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg, int index) {
    if (msg.isLoading) return _buildTypingIndicator();

    final isUser = msg.isUser;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.translate(
        offset: Offset(isUser ? (1 - v) * 40 : (1 - v) * -40, 0),
        child: Opacity(opacity: v, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_activeColor, const Color(0xFF7B2FFF)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: !isUser
                    ? () {
                        HapticFeedback.mediumImpact();
                        _speakSafe(msg.text);
                      }
                    : null,
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              _activeColor,
                              _activeColor.withOpacity(0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF131830),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isUser ? 18 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: _activeColor.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _activeColor.withOpacity(0.25)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(msg.text, isUser),
                      const SizedBox(height: 4),
                      Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.white.withOpacity(0.4),
                                fontSize: 10,
                              ),
                            ),
                            if (!isUser) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  if (_isSpeaking) {
                                    await _tts.stop();
                                    setState(
                                        () => _isSpeaking = false);
                                  } else {
                                    _speakSafe(msg.text);
                                  }
                                },
                                child: Icon(
                                  _isSpeaking
                                      ? Icons.stop_circle_rounded
                                      : Icons.volume_up_rounded,
                                  size: 14,
                                  color: _isSpeaking
                                      ? const Color(0xFF00FF94)
                                      : _activeColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ]),
                    ],
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white54, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      if (line.contains('**')) {
        final parts = line.split('**');
        for (int j = 0; j < parts.length; j++) {
          spans.add(TextSpan(
            text: parts[j],
            style: TextStyle(
              color: isUser
                  ? Colors.white
                  : Colors.white.withOpacity(0.9),
              fontWeight:
                  j % 2 == 1 ? FontWeight.w800 : FontWeight.w400,
              fontSize: 14.5,
              height: 1.5,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color:
                isUser ? Colors.white : Colors.white.withOpacity(0.88),
            fontSize: 14.5,
            height: 1.5,
          ),
        ));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  // ── Typing indicator ──────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_activeColor, const Color(0xFF7B2FFF)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(
                color: _activeColor.withOpacity(0.15)),
          ),
          child: AnimatedBuilder(
            animation: _aiTypingAnim,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase =
                    (_aiTypingAnim.value + i * 0.33) % 1.0;
                final v = math.sin(phase * math.pi);
                return Transform.translate(
                  offset: Offset(0, -v * 4),
                  child: Container(
                    width: 7,
                    height: 7,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _activeColor
                          .withOpacity(0.4 + v * 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _activeColor
                                .withOpacity(v * 0.4),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _bgAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(
                0, math.sin(_bgAnim.value * math.pi * 2) * 6),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_activeColor, const Color(0xFF7B2FFF)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _activeColor.withOpacity(0.35),
                      blurRadius: 28)
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Bắt đầu cuộc trò chuyện!',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 16)),
      ]),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12,
          12 + bottomPad + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E22).withOpacity(0.95),
        border: Border(
            top: BorderSide(
                color: Colors.white.withOpacity(0.06))),
        boxShadow: [
          BoxShadow(
              color: _activeColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(children: [
        _MicButton(
          isListening: _isListening,
          isAvailable: _speechAvailable,
          color: _activeColor,
          pulseAnim: _micPulseAnim,
          onTap: _toggleListening,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isListening
                    ? _activeColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
                width: _isListening ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.4),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isListening
                    ? (_micLang == MicLang.english
                        ? '🎤 Listening...'
                        : '🎤 Đang nghe...')
                    : 'Nhập hoặc nói (VI/EN)...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              cursorColor: _activeColor,
            ),
          ),
        ),

        const SizedBox(width: 10),

        _SendButton(
          isLoading: _isLoading,
          color: _activeColor,
          onTap: _sendMessage,
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MIC BUTTON
// ════════════════════════════════════════════════════════════════════════════
class _MicButton extends StatefulWidget {
  final bool isListening;
  final bool isAvailable;
  final Color color;
  final AnimationController pulseAnim;
  final VoidCallback onTap;

  const _MicButton({
    required this.isListening,
    required this.isAvailable,
    required this.color,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: widget.pulseAnim,
        builder: (_, __) {
          final pulse = widget.isListening ? widget.pulseAnim.value : 0.0;
          return Stack(alignment: Alignment.center, children: [
            if (widget.isListening)
              Transform.scale(
                scale: 1.0 + pulse * 0.5,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        widget.color.withOpacity((1 - pulse) * 0.25),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              transform: Matrix4.identity()
                ..scale(_pressed ? 0.92 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isListening
                    ? LinearGradient(colors: [
                        widget.color,
                        widget.color.withOpacity(0.7)
                      ])
                    : null,
                color: widget.isListening
                    ? null
                    : widget.isAvailable
                        ? Colors.white.withOpacity(0.07)
                        : Colors.red.withOpacity(0.1),
                border: Border.all(
                  color: widget.isListening
                      ? widget.color
                      : widget.isAvailable
                          ? Colors.white.withOpacity(0.12)
                          : Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: widget.isListening
                    ? [
                        BoxShadow(
                            color: widget.color.withOpacity(0.4),
                            blurRadius: 16)
                      ]
                    : null,
              ),
              child: Icon(
                widget.isListening
                    ? Icons.mic_rounded
                    : widget.isAvailable
                        ? Icons.mic_none_rounded
                        : Icons.mic_off_rounded,
                color: widget.isListening
                    ? Colors.white
                    : widget.isAvailable
                        ? Colors.white.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                size: 20,
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SEND BUTTON
// ════════════════════════════════════════════════════════════════════════════
class _SendButton extends StatefulWidget {
  final bool isLoading;
  final Color color;
  final VoidCallback onTap;

  const _SendButton({
    required this.isLoading,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800))
      ..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 44,
        height: 44,
        transform: Matrix4.identity()..scale(_pressed ? 0.9 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: widget.isLoading
            ? AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _spinCtrl.value * math.pi * 2,
                  child: CustomPaint(
                    size: const Size(24, 24),
                    painter: _MiniSpinPainter(widget.color),
                  ),
                ),
              )
            : const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
      ),
    );
  }
}

class _MiniSpinPainter extends CustomPainter {
  final Color color;
  _MiniSpinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      0,
      math.pi * 1.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════════════════
//  PAINTERS
// ════════════════════════════════════════════════════════════════════════════
class _ChatBgPainter extends CustomPainter {
  final double t;
  final Color accent;
  _ChatBgPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.screen;
    for (final o in [
      [0.1, 0.2, 0.5, accent, 0.7],
      [0.9, 0.6, 0.4, const Color(0xFF0047FF), 0.9],
      [0.5, 0.9, 0.35, const Color(0xFF7B2FFF), 0.6],
    ]) {
      final x = (o[0] as double) +
          math.sin(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final y = (o[1] as double) +
          math.cos(t * math.pi * 2 * (o[4] as double)) * 0.06;
      p.shader = RadialGradient(
        colors: [
          (o[3] as Color).withOpacity(0.12),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(x * size.width, y * size.height),
          radius: (o[2] as double) * size.width));
      canvas.drawCircle(Offset(x * size.width, y * size.height),
          (o[2] as double) * size.width, p);
    }
  }

  @override
  bool shouldRepaint(_ChatBgPainter o) =>
      o.t != t || o.accent != accent;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}