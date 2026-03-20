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
const _kGeminiKey = 'AIzaSyB1Gv8XR2D-nbS_kRTzExaNJMhZnqdMkeg';
const _kGeminiModel = 'gemini-3.1-pro-preview'; // latest stable
const _kGeminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$_kGeminiModel:generateContent?key=$_kGeminiKey';

// ════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ════════════════════════════════════════════════════════════════════════════
enum ChatMode { freeChat, vocabLearn, pronunciation, quiz }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? vocabWord;     // highlight vocab word if any
  final bool isLoading;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.vocabWord,
    this.isLoading = false,
  });
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

    // Build conversation turns
    final contents = <Map<String, dynamic>>[];

    // System instruction goes as first user turn with model ack
    contents.add({
      'role': 'user',
      'parts': [{'text': systemPrompt}],
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'Understood! I am ready to help you learn English.'}],
    });

    // Add conversation history
    for (final msg in history) {
      contents.add(msg);
    }

    // Add current message
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
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

    final response = await http.post(
      Uri.parse(_kGeminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
    } else {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }
  }

  static String _buildSystemPrompt(ChatMode mode) {
    switch (mode) {
      case ChatMode.freeChat:
        return '''You are DevTalk AI — a friendly English tutor specializing in IT vocabulary for Vietnamese developers.
Rules:
- Respond in a mix of Vietnamese explanation + English examples
- Correct grammar mistakes gently
- Provide IT-context examples (code, projects, meetings)
- Keep responses concise (2-4 sentences max unless explaining vocabulary)
- If user writes in Vietnamese, respond in Vietnamese + English
- Encourage the user frequently''';

      case ChatMode.vocabLearn:
        return '''You are DevTalk AI — a vocabulary teaching assistant for IT English.
Rules:
- When user gives a word/phrase, provide: meaning, pronunciation hint, part of speech, 2 IT-context example sentences
- Format: 
  📚 **[WORD]** /phonetic/  
  🔤 *[part of speech]* — [Vietnamese meaning]  
  💡 Example 1: [sentence]  
  💡 Example 2: [sentence]  
  🔥 Tip: [memory trick]
- Ask user to use the word in a sentence after teaching
- If user sends a sentence using the word, evaluate it and praise them
- Keep it engaging and fun''';

      case ChatMode.pronunciation:
        return '''You are DevTalk AI — a pronunciation coach for IT English.
Rules:
- Help users with pronunciation of technical terms (API, GUI, SQL, etc.)
- Provide phonetic spelling and pronunciation tips
- Give common mispronunciation warnings for Vietnamese speakers
- Format phonetics clearly: /æ/ /ɪ/ etc.
- Suggest mouth position tips when helpful
- Keep encouraging tone''';

      case ChatMode.quiz:
        return '''You are DevTalk AI — conducting an IT English vocabulary quiz.
Rules:
- Ask one question at a time
- Question types: multiple choice, fill-in-blank, translate to English, use in a sentence
- After each answer: give correct/incorrect feedback + explanation
- Keep score mentally and report after every 5 questions
- Questions should be about IT vocabulary: programming, cloud, AI, DevOps
- Make it fun and competitive''';
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
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _ttsEnabled = true;
  String _listeningText = '';

  // Speech & TTS
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  // Mode colors
  static const _modeColors = {
    ChatMode.freeChat: Color(0xFF00D4FF),
    ChatMode.vocabLearn: Color(0xFF7B2FFF),
    ChatMode.pronunciation: Color(0xFF00FF94),
    ChatMode.quiz: Color(0xFFFFD700),
  };

  Color get _activeColor => _modeColors[_mode]!;

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

    _initSpeech();
    _initTts();
    _addWelcomeMessage();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          if (_listeningText.isNotEmpty) {
            _inputCtrl.text = _listeningText;
            _listeningText = '';
          }
        }
      },
      onError: (error) {
        setState(() { _isListening = false; _listeningText = ''; });
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
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
              'Chọn chế độ học ở trên và bắt đầu nào! 🚀',
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
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  // ── Send message ────────────────────────────────────────────────────────
  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    HapticFeedback.lightImpact();
    _inputCtrl.clear();

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      // Add loading placeholder
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        time: DateTime.now(),
        isLoading: true,
      ));
    });

    _scrollToBottom();

    // Add to history
    _history.add({'role': 'user', 'parts': [{'text': text}]});

    try {
      final response = await GeminiService.sendMessage(
        history: List.from(_history)..removeLast(), // don't double-add
        userMessage: text,
        mode: _mode,
      );

      // Add AI response to history
      _history.add({'role': 'model', 'parts': [{'text': response}]});

      setState(() {
        // Remove loading placeholder
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Auto TTS for AI response
      if (_ttsEnabled) {
        await _speakText(_cleanForTts(response));
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: '⚠️ Lỗi kết nối: ${e.toString().replaceAll('Exception: ', '')}',
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _cleanForTts(String text) {
    // Remove markdown, emojis for TTS
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'\1')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) await _tts.stop();
    if (text.isNotEmpty) await _tts.speak(text);
  }

  void _toggleListening() async {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_listeningText.isNotEmpty) {
        _inputCtrl.text = _listeningText;
        _listeningText = '';
      }
    } else {
      if (!_speechAvailable) {
        _showSnack('Microphone không khả dụng trên thiết bị này');
        return;
      }
      setState(() { _isListening = true; _listeningText = ''; });
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _listeningText = result.recognizedWords;
            _inputCtrl.text = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _sendMessage(result.recognizedWords);
            setState(() { _isListening = false; _listeningText = ''; });
          }
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      ChatMode.freeChat: 'Chế độ trò chuyện tự do đã bật! Hãy viết hoặc nói bất kỳ điều gì bằng tiếng Anh. Tôi sẽ giúp bạn cải thiện. 💬',
      ChatMode.vocabLearn: 'Chế độ học từ vựng! Gửi cho tôi bất kỳ từ IT nào bạn muốn học (ví dụ: "microservice", "latency", "refactoring") và tôi sẽ dạy bạn chi tiết. 📚',
      ChatMode.pronunciation: 'Chế độ luyện phát âm! Gửi thuật ngữ kỹ thuật bạn không chắc cách đọc (ví dụ: "SQL", "API", "cache", "nginx"). 🎤',
      ChatMode.quiz: 'Quiz IT English bắt đầu! Tôi sẽ hỏi bạn các câu hỏi về từ vựng IT. Sẵn sàng chưa? Gõ "bắt đầu" để chơi! 🧠',
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A1F35),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
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
        // Background
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
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(),

            // ── Mode selector ────────────────────────────────────────────
            _buildModeSelector(),

            // ── Messages ─────────────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildMessageBubble(_messages[i], i),
                    ),
            ),

            // ── Input bar ────────────────────────────────────────────────
            _buildInputBar(bottomPad),
          ]),
        ),
      ]),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        // AI avatar with pulse
        AnimatedBuilder(
          animation: _aiTypingAnim,
          builder: (_, __) {
            final glowOp = _isLoading ? (0.3 + _aiTypingAnim.value * 0.4) : 0.3;
            return Stack(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _activeColor.withOpacity(glowOp), blurRadius: 16, spreadRadius: 2)],
                ),
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_activeColor, const Color(0xFF7B2FFF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
              ),
              if (_isLoading)
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF94), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF080B1A), width: 2),
                  ),
                )),
            ]);
          },
        ),

        const SizedBox(width: 12),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DevTalk AI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isLoading ? 'Đang suy nghĩ...' : _isListening ? '🎤 Đang nghe...' : 'Powered by Gemini',
              key: ValueKey(_isLoading.toString() + _isListening.toString()),
              style: TextStyle(color: _activeColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ])),

        // TTS toggle
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (_isSpeaking) await _tts.stop();
            setState(() => _ttsEnabled = !_ttsEnabled);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _ttsEnabled ? _activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ttsEnabled ? _activeColor.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _ttsEnabled ? _activeColor : Colors.white.withOpacity(0.3),
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Clear chat
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() { _messages.clear(); _history.clear(); });
            _addWelcomeMessage();
          },
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.5), size: 18),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: modes.map((m) {
        final isActive = _mode == m.$1;
        final color = _modeColors[m.$1]!;
        return Expanded(child: GestureDetector(
          onTap: () => _changeMode(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
              boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : null,
            ),
            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(m.$2, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(m.$3, style: TextStyle(
                color: isActive ? color : Colors.white.withOpacity(0.4),
                fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              )),
            ])),
          ),
        ));
      }).toList()),
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
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_activeColor, const Color(0xFF7B2FFF)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: GestureDetector(
                onLongPress: () {
                  // Long press to read aloud
                  HapticFeedback.mediumImpact();
                  if (!isUser) _speakText(_cleanForTts(msg.text));
                },
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [_activeColor, _activeColor.withOpacity(0.7)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF131830),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: _activeColor.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: isUser ? _activeColor.withOpacity(0.25) : Colors.black.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildFormattedText(msg.text, isUser),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: (isUser ? Colors.white : Colors.white.withOpacity(0.4)),
                          fontSize: 10,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _speakText(_cleanForTts(msg.text)),
                          child: Icon(Icons.volume_up_rounded, size: 12, color: _activeColor.withOpacity(0.6)),
                        ),
                      ],
                    ]),
                  ]),
                ),
              ),
            ),

            if (isUser) ...[
              const SizedBox(width: 8),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white54, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    // Simple markdown-like formatting
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(const TextSpan(text: '\n'));

      if (line.contains('**')) {
        // Bold text
        final parts = line.split('**');
        for (int j = 0; j < parts.length; j++) {
          spans.add(TextSpan(
            text: parts[j],
            style: TextStyle(
              color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
              fontWeight: j % 2 == 1 ? FontWeight.w800 : FontWeight.w400,
              fontSize: 14.5,
              height: 1.5,
            ),
          ));
        }
      } else {
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white.withOpacity(0.88),
            fontSize: 14.5, height: 1.5,
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_activeColor, const Color(0xFF7B2FFF)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF131830),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: _activeColor.withOpacity(0.15)),
          ),
          child: AnimatedBuilder(
            animation: _aiTypingAnim,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
              final phase = (_aiTypingAnim.value + i * 0.33) % 1.0;
              final v = math.sin(phase * math.pi);
              return Transform.translate(
                offset: Offset(0, -v * 4),
                child: Container(
                  width: 7, height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _activeColor.withOpacity(0.4 + v * 0.5),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _activeColor.withOpacity(v * 0.4), blurRadius: 6)],
                  ),
                ),
              );
            })),
          ),
        ),
      ]),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, math.sin(_bgAnim.value * math.pi * 2) * 6),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_activeColor, const Color(0xFF7B2FFF)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _activeColor.withOpacity(0.35), blurRadius: 28)],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('Bắt đầu cuộc trò chuyện!', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
    ]));
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomPad + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E22).withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        boxShadow: [BoxShadow(color: _activeColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        // Mic button
        _MicButton(
          isListening: _isListening,
          isAvailable: _speechAvailable,
          color: _activeColor,
          pulseAnim: _micPulseAnim,
          onTap: _toggleListening,
        ),

        const SizedBox(width: 10),

        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isListening ? _activeColor.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                width: _isListening ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isListening ? '🎤 Đang nghe bạn nói...' : 'Nhập tin nhắn hoặc từ vựng...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              cursorColor: _activeColor,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Send button
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
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
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
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity((1 - pulse) * 0.25),
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              transform: Matrix4.identity()..scale(_pressed ? 0.92 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isListening
                    ? LinearGradient(colors: [widget.color, widget.color.withOpacity(0.7)])
                    : null,
                color: widget.isListening ? null : Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: widget.isListening ? widget.color : Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
                boxShadow: widget.isListening ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 16)] : null,
              ),
              child: Icon(
                widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: widget.isListening ? Colors.white : Colors.white.withOpacity(0.5),
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

  const _SendButton({required this.isLoading, required this.color, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() { _spinCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); if (!widget.isLoading) widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 44, height: 44,
        transform: Matrix4.identity()..scale(_pressed ? 0.9 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [widget.color, widget.color.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
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
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
      0, math.pi * 1.5, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = Colors.white.withOpacity(0.8),
    );
  }
  @override bool shouldRepaint(_) => false;
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
      final x = (o[0] as double) + math.sin(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final y = (o[1] as double) + math.cos(t * math.pi * 2 * (o[4] as double)) * 0.06;
      p.shader = RadialGradient(colors: [(o[3] as Color).withOpacity(0.12), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: (o[2] as double) * size.width));
      canvas.drawCircle(Offset(x * size.width, y * size.height), (o[2] as double) * size.width, p);
    }
  }

  @override bool shouldRepaint(_ChatBgPainter o) => o.t != t || o.accent != accent;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.018)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}