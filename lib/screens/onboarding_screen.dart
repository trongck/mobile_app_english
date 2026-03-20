import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _cardFade;
  late Animation<double> _cardY;

  String? _trinhDo;
  String? _mucTieuCapDo;
  String? _hocVi;
  int _mucTieuPhut = 15;

  static const _questions = [
    {'icon': Icons.school_rounded, 'label': 'Trình độ tiếng Anh', 'sub': 'Bạn đang ở cấp độ nào?', 'field': 'trinhDo',
      'opts': [{'v': 'A1', 'l': 'A1 – Mới bắt đầu', 'e': '🌱'}, {'v': 'A2', 'l': 'A2 – Sơ cấp', 'e': '🌿'},
        {'v': 'B1', 'l': 'B1 – Trung cấp', 'e': '🌳'}, {'v': 'B2', 'l': 'B2 – Trên trung cấp', 'e': '🚀'},
        {'v': 'C1', 'l': 'C1 – Nâng cao', 'e': '⚡'}, {'v': 'C2', 'l': 'C2 – Thành thạo', 'e': '💎'}]},
    {'icon': Icons.track_changes_rounded, 'label': 'Mục tiêu cấp độ', 'sub': 'Bạn muốn đạt được cấp độ nào?', 'field': 'mucTieuCapDo',
      'opts': [{'v': 'A2', 'l': 'A2 – Sơ cấp', 'e': '🌿'}, {'v': 'B1', 'l': 'B1 – Trung cấp', 'e': '🌳'},
        {'v': 'B2', 'l': 'B2 – Trên trung cấp', 'e': '🚀'}, {'v': 'C1', 'l': 'C1 – Nâng cao', 'e': '⚡'},
        {'v': 'C2', 'l': 'C2 – Thành thạo', 'e': '💎'}]},
    {'icon': Icons.work_rounded, 'label': 'Lĩnh vực chuyên môn', 'sub': 'Bạn làm việc trong lĩnh vực nào?', 'field': 'hocVi',
      'opts': [{'v': 'developer', 'l': 'Developer / Lập trình viên', 'e': '💻'}, {'v': 'devops', 'l': 'DevOps / Cloud', 'e': '☁️'},
        {'v': 'ai_ml', 'l': 'AI / Machine Learning', 'e': '🤖'}, {'v': 'designer', 'l': 'UI/UX Designer', 'e': '🎨'},
        {'v': 'student', 'l': 'Sinh viên IT', 'e': '🎓'}, {'v': 'other', 'l': 'Khác', 'e': '✨'}]},
    {'icon': Icons.timer_rounded, 'label': 'Mục tiêu mỗi ngày', 'sub': 'Bạn có thể học bao nhiêu phút/ngày?', 'field': 'mucTieuPhut',
      'opts': [{'v': 5, 'l': '5 phút', 'e': '⚡', 'd': 'Nhẹ nhàng'}, {'v': 10, 'l': '10 phút', 'e': '🌱', 'd': 'Đều đặn'},
        {'v': 15, 'l': '15 phút', 'e': '🔥', 'd': 'Tiêu chuẩn'}, {'v': 30, 'l': '30 phút', 'e': '💪', 'd': 'Nghiêm túc'},
        {'v': 60, 'l': '60 phút', 'e': '🚀', 'd': 'Chuyên sâu'}]},
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardY = Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardCtrl.forward();
  }

  @override
  void dispose() { _bgCtrl.dispose(); _cardCtrl.dispose(); _particleCtrl.dispose(); super.dispose(); }

  void _select(dynamic value) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_step) {
        case 0: _trinhDo = value; break;
        case 1: _mucTieuCapDo = value; break;
        case 2: _hocVi = value; break;
        case 3: _mucTieuPhut = value; break;
      }
    });
  }

  dynamic get _cur { switch (_step) { case 0: return _trinhDo; case 1: return _mucTieuCapDo; case 2: return _hocVi; case 3: return _mucTieuPhut; default: return null; } }
  bool get _hasAnswer => _step == 3 ? true : _cur != null;

  Future<void> _next() async {
    if (!_hasAnswer) return;
    HapticFeedback.mediumImpact();
    if (_step < _questions.length - 1) {
      await _cardCtrl.reverse();
      setState(() => _step++);
      _cardCtrl.forward();
    } else {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, a, __) => AuthScreen(trinhDo: _trinhDo ?? 'A1', mucTieuCapDo: _mucTieuCapDo ?? 'A2', hocVi: _hocVi, mucTieuPhut: _mucTieuPhut),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    }
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _cardCtrl.reverse();
    setState(() => _step--);
    _cardCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final q = _questions[_step];
    const accentColor = Color(0xFF00D4FF);

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: Stack(children: [
        AnimatedBuilder(animation: _bgCtrl, builder: (_, __) => CustomPaint(size: size, painter: _ObgPainter(_bgCtrl.value))),
        AnimatedBuilder(animation: _particleCtrl, builder: (_, __) => CustomPaint(size: size, painter: _ParticlePainter(_particleCtrl.value))),
        CustomPaint(size: size, painter: _GridP()),

        SafeArea(child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: _back,
                child: AnimatedOpacity(
                  opacity: _step > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.3))),
                child: Text('${_step + 1} / ${_questions.length}',
                  style: const TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(children: [
              Container(height: 3, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(3))),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
                widthFactor: (_step + 1) / _questions.length,
                child: Container(height: 3, decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 8)],
                )),
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // Card
          Expanded(
            child: AnimatedBuilder(
              animation: _cardCtrl,
              builder: (_, child) => Transform.translate(offset: Offset(0, _cardY.value), child: Opacity(opacity: _cardFade.value, child: child)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Icon(q['icon'] as IconData, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 18),
                  Text(q['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2)),
                  const SizedBox(height: 6),
                  Text(q['sub'] as String, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                  const SizedBox(height: 24),
                  Expanded(child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildOpts(q),
                  )),
                ]),
              ),
            ),
          ),

          // Next button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
            child: GestureDetector(
              onTap: _hasAnswer ? _next : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 56,
                decoration: BoxDecoration(
                  gradient: _hasAnswer ? const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]) : null,
                  color: _hasAnswer ? null : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _hasAnswer ? [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))] : null,
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_step < _questions.length - 1 ? 'Tiếp theo' : 'Hoàn thành',
                    style: TextStyle(color: _hasAnswer ? Colors.white : Colors.white.withOpacity(0.3), fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Icon(_step < _questions.length - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                    color: _hasAnswer ? Colors.white : Colors.white.withOpacity(0.3), size: 20),
                ])),
              ),
            ),
          ),
        ])),
      ]),
    );
  }

  Widget _buildOpts(Map q) {
    final opts = q['opts'] as List;
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55),
      itemCount: opts.length,
      itemBuilder: (_, i) {
        final o = opts[i] as Map;
        final val = o['v'];
        final sel = _cur == val;
        return GestureDetector(
          onTap: () => _select(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: sel ? const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: sel ? null : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.09)),
              boxShadow: sel ? [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o['e'] as String, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(o['l'] as String, style: TextStyle(color: sel ? Colors.white : Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
              if (o['d'] != null) Text(o['d'] as String, style: TextStyle(color: sel ? Colors.white70 : Colors.white.withOpacity(0.35), fontSize: 10)),
            ]),
          ),
        );
      },
    );
  }
}

class _ObgPainter extends CustomPainter {
  final double t;
  _ObgPainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.screen;
    for (final o in [[0.2, 0.1, 0.35, const Color(0xFF00D4FF), 1.0], [0.8, 0.3, 0.28, const Color(0xFF7B2FFF), 0.7], [0.5, 0.8, 0.3, const Color(0xFF0047FF), 1.3]]) {
      final x = (o[0] as double) + math.sin(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final y = (o[1] as double) + math.cos(t * math.pi * 2 * (o[4] as double)) * 0.06;
      p.shader = RadialGradient(colors: [(o[3] as Color).withOpacity(0.18), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: (o[2] as double) * size.width));
      canvas.drawCircle(Offset(x * size.width, y * size.height), (o[2] as double) * size.width, p);
    }
  }
  @override bool shouldRepaint(_ObgPainter o) => o.t != t;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(42);
  static final _ps = List.generate(20, (_) => [_rng.nextDouble(), _rng.nextDouble(), _rng.nextDouble()]);
  _ParticlePainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final pt in _ps) {
      final x = pt[0] * size.width;
      final y = ((pt[1] + t * (0.1 + pt[2] * 0.2)) % 1.0) * size.height;
      final op = (math.sin(t * math.pi * 2 + pt[2] * 10) * 0.5 + 0.5) * 0.35;
      p.color = const Color(0xFF00D4FF).withOpacity(op);
      canvas.drawCircle(Offset(x, y), 1.5, p);
    }
  }
  @override bool shouldRepaint(_ParticlePainter o) => o.t != t;
}

class _GridP extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}