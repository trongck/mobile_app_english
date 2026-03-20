import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import '../providers/gt_provider.dart';
import 'main_screen.dart';
import 'intro_screen.dart';

/// Màn hình splash: kiểm tra session → route đến đúng màn hình.
/// - Nếu đã đăng nhập → MainScreen
/// - Nếu chưa → IntroScreen (giới thiệu + onboarding + đăng ký)
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
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.08), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.6));

    _logoGlow = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _logoCtrl.forward();

    // Sau 2 giây thì check session và navigate
    Future.delayed(const Duration(milliseconds: 2200), _checkAndNavigate);
  }

  Future<void> _checkAndNavigate() async {
    final ndProvider = context.read<NguoiDungProvider>();
    final gtProvider = context.read<GTProvider>();

    // Kiểm tra session đã lưu
    final isLoggedIn = await ndProvider.khoiPhucSession();

    if (!mounted) return;

    if (isLoggedIn) {
      // Đã đăng nhập → thẳng vào MainScreen
      _navigateTo(const MainScreen(), replace: true);
    } else {
      // Chưa đăng nhập → IntroScreen
      await gtProvider.khoiTaoDuLieu();
      if (!mounted) return;
      _navigateTo(const IntroScreen(), replace: true);
    }
  }

  void _navigateTo(Widget screen, {bool replace = false}) {
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
                  // Rotating ring + logo
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Opacity(
                          opacity: _logoGlow.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4FF).withOpacity(0.35),
                                  blurRadius: 48,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Spinning ring
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: _ringCtrl.value * math.pi * 2,
                            child: CustomPaint(
                              size: const Size(110, 110),
                              painter: _SpinRingPainter(),
                            ),
                          ),
                        ),

                        // Logo container
                        Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'DT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Opacity(
                    opacity: _logoFade.value,
                    child: const Text(
                      'DevTalk English',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Opacity(
                    opacity: _logoGlow.value,
                    child: Text(
                      'IT English Mastery',
                      style: TextStyle(
                        color: const Color(0xFF00D4FF).withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading dots
                  Opacity(
                    opacity: _logoGlow.value,
                    child: _LoadingDots(anim: _ringCtrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withOpacity(opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(opacity * 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SpinRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF00D4FF),
          const Color(0xFF7B2FFF),
          const Color(0xFF00D4FF).withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawArc(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      0,
      math.pi * 1.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SplashBgPainter extends CustomPainter {
  final double t;
  _SplashBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    final orbs = [
      [0.5, 0.3, 0.6, const Color(0xFF00D4FF), 0.8],
      [0.8, 0.7, 0.45, const Color(0xFF7B2FFF), 1.1],
      [0.2, 0.8, 0.4, const Color(0xFF0047FF), 0.6],
    ];
    for (final o in orbs) {
      final x = (o[0] as double) + math.sin(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final y = (o[1] as double) + math.cos(t * math.pi * 2 * (o[4] as double)) * 0.06;
      final r = (o[2] as double) * size.width;
      final c = o[3] as Color;
      paint.shader = RadialGradient(
        colors: [c.withOpacity(0.18), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: r));
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter o) => o.t != t;
}

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