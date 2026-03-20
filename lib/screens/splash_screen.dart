import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import '../providers/gt_provider.dart';
import 'main_screen.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoGlow;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_logoCtrl);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), _checkAndNavigate);
  }

  Future<void> _checkAndNavigate() async {
    final ndProvider = context.read<NguoiDungProvider>();
    final gtProvider = context.read<GTProvider>();

    final isLoggedIn = await ndProvider.khoiPhucSession();
    if (!mounted) return;

    if (isLoggedIn) {
      _navigateTo(const MainScreen());
    } else {
      await gtProvider.khoiTaoDuLieu();
      if (!mounted) return;
      _navigateTo(const IntroScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _bgCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: Stack(
        children: [
          // Animated mesh background
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _SplashBgPainter(_bgCtrl.value),
            ),
          ),

          // Grid lines
          CustomPaint(size: size, painter: GridPainter()),

          Center(
            child: AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo + ring zone ─────────────────────────────────
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing halo glow
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Opacity(
                            opacity: _logoGlow.value * 0.55,
                            child: Transform.scale(
                              scale: _pulse.value,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00D4FF)
                                          .withOpacity(0.28),
                                      blurRadius: 60,
                                      spreadRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Outer ring — spins forward
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: _ringCtrl.value * math.pi * 2,
                            child: CustomPaint(
                              size: const Size(148, 148),
                              painter: _SpinRingPainter(
                                color1: const Color(0xFF00D4FF),
                                color2: const Color(0xFF7B2FFF),
                                strokeWidth: 2.8,
                                arcFraction: 1.75,
                              ),
                            ),
                          ),
                        ),

                        // Inner ring — spins backward, slower
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: -_ringCtrl.value * math.pi * 2 * 0.55,
                            child: Opacity(
                              opacity: 0.38,
                              child: CustomPaint(
                                size: const Size(124, 124),
                                painter: _SpinRingPainter(
                                  color1: const Color(0xFF7B2FFF),
                                  color2: const Color(0xFF00D4FF),
                                  strokeWidth: 1.8,
                                  arcFraction: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── LOGO IMAGE ───────────────────────────────
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: _LogoImage(glowOpacity: _logoGlow.value),
                          ),
                        ),

                        // Corner sparkle dots
                        ..._cornerDots(_logoGlow.value),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App name
                  Opacity(
                    opacity: _logoFade.value,
                    child: const Text(
                      'DevTalk English',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Gradient tagline
                  Opacity(
                    opacity: _logoGlow.value,
                    child: ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                      ).createShader(b),
                      child: const Text(
                        'IT English Mastery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Loading indicators
                  Opacity(
                    opacity: _logoGlow.value,
                    child: Column(children: [
                      _LoadingBar(anim: _ringCtrl),
                      const SizedBox(height: 14),
                      _LoadingDots(anim: _ringCtrl),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cornerDots(double opacity) {
    const positions = [
      Offset(-56, -56),
      Offset(56, -56),
      Offset(-56, 56),
      Offset(56, 56),
    ];
    return positions.asMap().entries.map((e) {
      final delay = e.key * 0.25;
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final phase = (_pulseCtrl.value + delay) % 1.0;
          final op = opacity * (0.3 + math.sin(phase * math.pi) * 0.5);
          return Positioned(
            left: 80 + e.value.dx - 4,
            top: 80 + e.value.dy - 4,
            child: Opacity(
              opacity: op.clamp(0.0, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ─── Logo image widget ────────────────────────────────────────────────────────
class _LogoImage extends StatelessWidget {
  final double glowOpacity;

  const _LogoImage({required this.glowOpacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.32 * glowOpacity),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF7B2FFF).withOpacity(0.2 * glowOpacity),
            blurRadius: 48,
            spreadRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/icon/logo.png',     // ← đường dẫn logo của bạn
          width: 104,
          height: 104,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackLogo(),
        ),
      ),
    );
  }
}

/// Hiển thị khi ảnh chưa có / path sai — vẫn trông đẹp
class _FallbackLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'DT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

// ─── Loading bar ──────────────────────────────────────────────────────────────
class _LoadingBar extends StatelessWidget {
  final Animation<double> anim;
  const _LoadingBar({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final pos = (anim.value * 2) % 1.0;
        return SizedBox(
          width: 140,
          height: 3,
          child: Stack(children: [
            // Track
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Moving highlight
            FractionallySizedBox(
              widthFactor: (0.1 + pos * 0.9).clamp(0.1, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── Loading dots ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  final Animation<double> anim;
  const _LoadingDots({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (anim.value + i * 0.33) % 1.0;
          final v = (math.sin(phase * math.pi * 2) * 0.5 + 0.5);
          return Transform.scale(
            scale: 0.65 + v * 0.5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(v),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(v * 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Spin ring painter ────────────────────────────────────────────────────────
class _SpinRingPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double strokeWidth;
  final double arcFraction;

  const _SpinRingPainter({
    required this.color1,
    required this.color2,
    this.strokeWidth = 2.0,
    this.arcFraction = 1.7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color1, color2, color1.withOpacity(0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth,
        strokeWidth,
        size.width - strokeWidth * 2,
        size.height - strokeWidth * 2,
      ),
      0,
      math.pi * arcFraction,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinRingPainter o) =>
      o.color1 != color1 || o.arcFraction != arcFraction;
}

// ─── Background painter ───────────────────────────────────────────────────────
class _SplashBgPainter extends CustomPainter {
  final double t;
  _SplashBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (final o in [
      [0.5, 0.3, 0.6, const Color(0xFF00D4FF), 0.8],
      [0.8, 0.7, 0.45, const Color(0xFF7B2FFF), 1.1],
      [0.2, 0.8, 0.4, const Color(0xFF0047FF), 0.6],
    ]) {
      final x = (o[0] as double) +
          math.sin(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final y = (o[1] as double) +
          math.cos(t * math.pi * 2 * (o[4] as double)) * 0.06;
      final r = (o[2] as double) * size.width;
      final c = o[3] as Color;
      paint.shader = RadialGradient(
        colors: [c.withOpacity(0.18), Colors.transparent],
      ).createShader(
          Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: r));
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter o) => o.t != t;
}

// ─── Grid painter (exported — dùng lại ở các screen khác) ────────────────────
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.022)
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