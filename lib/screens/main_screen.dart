import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import '../providers/nhat_ky_provider.dart';
import 'home_tab.dart';
import 'splash_screen.dart';
import 'chatbot_screen.dart';
import 'tuvung_screen.dart';
import 'quiz_screen.dart';
import 'nguoidung_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 2;

  late AnimationController _bgAnim;
  late AnimationController _navEntryAnim;
  late AnimationController _tabAnim;
  late Animation<double> _tabFade;
  late Animation<double> _tabSlide;

  final List<AnimationController?> _rippleControllers = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _navEntryAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _tabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _tabFade = CurvedAnimation(parent: _tabAnim, curve: Curves.easeOut);
    _tabSlide = Tween<double>(begin: 24, end: 0).animate(CurvedAnimation(parent: _tabAnim, curve: Curves.easeOutCubic));
    _tabAnim.forward();
    for (int i = 0; i < 5; i++) {
      _rippleControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    }
    // Start learning session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      if (nd != null) context.read<NhatKyProvider>().batDauSession(nd.maND!);
    });
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _navEntryAnim.dispose();
    _tabAnim.dispose();
    for (final c in _rippleControllers) c?.dispose();
    // End session
    context.read<NhatKyProvider>().ketThucSession();
    super.dispose();
  }

  Future<void> _onTabTap(int index) async {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    _rippleControllers[index]?.reset();
    _rippleControllers[index]?.forward();
    await _tabAnim.reverse();
    setState(() => _selectedIndex = index);
    _tabAnim.forward();
  }

  static const _tabColors = [
    Color(0xFF00D4FF),
    Color(0xFF7B2FFF),
    Color(0xFFFFD700),
    Color(0xFF00FF94),
    Color(0xFFFF3CAC),
  ];

  static const _tabIcons = [
    Icons.style_rounded,
    Icons.quiz_outlined,
    Icons.home_rounded,
    Icons.smart_toy_outlined,
    Icons.person_outline_rounded,
  ];
  static const _tabActiveIcons = [
    Icons.style_rounded,
    Icons.quiz_rounded,
    Icons.home_rounded,
    Icons.smart_toy_rounded,
    Icons.person_rounded,
  ];
  static const _tabLabels = ['Từ Vựng', 'Quiz', 'Home', 'AI Chat', 'Hồ Sơ'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final activeColor = _tabColors[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: Stack(children: [
        AnimatedBuilder(animation: _bgAnim, builder: (_, __) => CustomPaint(size: size, painter: _MainBgPainter(_bgAnim.value, _selectedIndex))),
        CustomPaint(size: size, painter: GridPainter()),
        Column(children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _tabAnim,
              builder: (_, child) => Transform.translate(offset: Offset(0, _tabSlide.value), child: Opacity(opacity: _tabFade.value.clamp(0.0, 1.0), child: child)),
              child: _buildContent(_selectedIndex),
            ),
          ),
          SizedBox(height: 72 + bottomPad),
        ]),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomNav(bottomPad, activeColor)),
      ]),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0: return const TuVungScreen();
      case 1: return const QuizScreen();
      case 2: return const HomeTab();
      case 3: return const ChatbotScreen();
      case 4: return const NguoiDungScreen();
      default: return const SizedBox();
    }
  }

  Widget _buildBottomNav(double bottomPad, Color activeColor) {
    return AnimatedBuilder(
      animation: _navEntryAnim,
      builder: (_, child) => Transform.translate(offset: Offset(0, (1 - Curves.elasticOut.transform(_navEntryAnim.value)) * 80), child: child),
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E22).withOpacity(0.97),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: [
              BoxShadow(color: activeColor.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, -4)),
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(children: [
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [0, 1].map((i) => _NavItem(icon: _tabIcons[i], activeIcon: _tabActiveIcons[i], label: _tabLabels[i], color: _tabColors[i], isActive: _selectedIndex == i, rippleCtrl: _rippleControllers[i]!, onTap: () => _onTabTap(i))).toList())),
            _HomeButton(isActive: _selectedIndex == 2, rippleCtrl: _rippleControllers[2]!, onTap: () => _onTabTap(2)),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [3, 4].map((i) => _NavItem(icon: _tabIcons[i], activeIcon: _tabActiveIcons[i], label: _tabLabels[i], color: _tabColors[i], isActive: _selectedIndex == i, rippleCtrl: _rippleControllers[i]!, onTap: () => _onTabTap(i))).toList())),
          ]),
        ),
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  final bool isActive;
  final AnimationController rippleCtrl;
  final VoidCallback onTap;
  const _HomeButton({required this.isActive, required this.rippleCtrl, required this.onTap});
  @override State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pressScale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }
  @override void dispose() { _pressCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: SizedBox(
        width: 68,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: Listenable.merge([_pressCtrl, widget.rippleCtrl]),
            builder: (_, __) {
              final ripple = widget.rippleCtrl.value;
              return Stack(alignment: Alignment.center, children: [
                if (ripple > 0 && ripple < 1)
                  Transform.scale(scale: 1.0 + ripple * 0.6, child: Opacity(opacity: (1 - ripple) * 0.6,
                    child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFD700), width: 2))))),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Transform.scale(scale: _pressScale.value,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.isActive ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)] : [const Color(0xFF2A2F4A), const Color(0xFF1A1F35)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: widget.isActive ? const Color(0xFFFFD700).withOpacity(0.45) : Colors.black.withOpacity(0.4), blurRadius: widget.isActive ? 24 : 12, offset: const Offset(0, 6)),
                          if (widget.isActive) BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 40, spreadRadius: 2),
                        ],
                        border: Border.all(color: widget.isActive ? const Color(0xFFFFD700).withOpacity(0.6) : Colors.white.withOpacity(0.1), width: 1.5),
                      ),
                      child: Icon(widget.isActive ? Icons.home_rounded : Icons.home_outlined, color: widget.isActive ? const Color(0xFF080B1A) : Colors.white.withOpacity(0.5), size: 26),
                    ),
                  ),
                ),
              ]);
            },
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 10, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400, color: widget.isActive ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.3)),
              child: const Text('Home'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon, activeIcon;
  final String label;
  final Color color;
  final bool isActive;
  final AnimationController rippleCtrl;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.color, required this.isActive, required this.rippleCtrl, required this.onTap});
  @override State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    if (widget.isActive) _ctrl.forward();
  }
  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) { if (widget.isActive) _ctrl.forward(); else _ctrl.reverse(); }
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ctrl, widget.rippleCtrl]),
          builder: (_, __) {
            final ripple = widget.rippleCtrl.value;
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(alignment: Alignment.center, children: [
                if (ripple > 0 && ripple < 1)
                  Transform.scale(scale: 1.0 + ripple * 1.2, child: Opacity(opacity: (1 - ripple) * 0.4, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)))),
                Transform.scale(scale: _scale.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40, height: 36,
                    decoration: widget.isActive ? BoxDecoration(gradient: LinearGradient(colors: [widget.color.withOpacity(0.18), widget.color.withOpacity(0.04)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.color.withOpacity(0.35), width: 1)) : null,
                    child: Icon(widget.isActive ? widget.activeIcon : widget.icon, size: 22, color: widget.isActive ? widget.color : Colors.white.withOpacity(0.28)),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(fontSize: 10, fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400, color: widget.isActive ? widget.color : Colors.white.withOpacity(0.28), letterSpacing: 0.2),
                child: Text(widget.label),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _MainBgPainter extends CustomPainter {
  final double t;
  final int tabIdx;
  static const _colors = [Color(0xFF00D4FF), Color(0xFF7B2FFF), Color(0xFFFFD700), Color(0xFF00FF94), Color(0xFFFF3CAC)];
  _MainBgPainter(this.t, this.tabIdx);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.screen;
    final c = _colors[tabIdx];
    for (final o in [[0.15, 0.2, 0.55, c, 0.6], [0.85, 0.5, 0.4, const Color(0xFF0047FF), 0.9], [0.5, 0.85, 0.35, const Color(0xFF7B2FFF), 0.7]]) {
      final x = (o[0] as double) + math.sin(t * math.pi * 2 * (o[4] as double)) * 0.1;
      final y = (o[1] as double) + math.cos(t * math.pi * 2 * (o[4] as double)) * 0.08;
      p.shader = RadialGradient(colors: [(o[3] as Color).withOpacity(0.14), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: (o[2] as double) * size.width));
      canvas.drawCircle(Offset(x * size.width, y * size.height), (o[2] as double) * size.width, p);
    }
  }
  @override bool shouldRepaint(_MainBgPainter o) => o.t != t || o.tabIdx != tabIdx;
}