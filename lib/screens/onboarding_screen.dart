import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _accentCtrl;
  late Animation<double> _cardFade;
  late Animation<double> _cardY;
  late Animation<double> _accentScale;

  String? _trinhDo;
  String? _mucTieuCapDo;
  String? _hocVi;
  int _mucTieuPhut = 15;

  static const _questions = [
    {
      'label': 'Trình độ\nhiện tại',
      'sub': 'Bạn đang đứng ở đâu?',
      'field': 'trinhDo',
      'accent': Color(0xFF00D4FF),
      'opts': [
        {'v': 'A1', 'l': 'A1', 'desc': 'Mới bắt đầu', 'icon': Icons.spa_outlined},
        {'v': 'A2', 'l': 'A2', 'desc': 'Sơ cấp', 'icon': Icons.local_florist_outlined},
        {'v': 'B1', 'l': 'B1', 'desc': 'Trung cấp', 'icon': Icons.filter_vintage_outlined},
        {'v': 'B2', 'l': 'B2', 'desc': 'Trên trung cấp', 'icon': Icons.bolt_outlined},
        {'v': 'C1', 'l': 'C1', 'desc': 'Nâng cao', 'icon': Icons.star_outline_rounded},
        {'v': 'C2', 'l': 'C2', 'desc': 'Thành thạo', 'icon': Icons.diamond_outlined},
      ]
    },
    {
      'label': 'Mục tiêu\ncần đạt',
      'sub': 'Bạn muốn leo lên cấp nào?',
      'field': 'mucTieuCapDo',
      'accent': Color(0xFF7B2FFF),
      'opts': [
        {'v': 'A2', 'l': 'A2', 'desc': 'Sơ cấp', 'icon': Icons.local_florist_outlined},
        {'v': 'B1', 'l': 'B1', 'desc': 'Trung cấp', 'icon': Icons.filter_vintage_outlined},
        {'v': 'B2', 'l': 'B2', 'desc': 'Trên trung cấp', 'icon': Icons.bolt_outlined},
        {'v': 'C1', 'l': 'C1', 'desc': 'Nâng cao', 'icon': Icons.star_outline_rounded},
        {'v': 'C2', 'l': 'C2', 'desc': 'Thành thạo', 'icon': Icons.diamond_outlined},
      ]
    },
    {
      'label': 'Lĩnh vực\nchuyên môn',
      'sub': 'Bạn làm việc trong ngành gì?',
      'field': 'hocVi',
      'accent': Color(0xFF00FF94),
      'opts': [
        {'v': 'developer', 'l': 'Developer', 'desc': 'Lập trình viên', 'icon': Icons.code_rounded},
        {'v': 'devops', 'l': 'DevOps', 'desc': 'Cloud & Infrastructure', 'icon': Icons.cloud_outlined},
        {'v': 'ai_ml', 'l': 'AI / ML', 'desc': 'Machine Learning', 'icon': Icons.psychology_outlined},
        {'v': 'designer', 'l': 'Designer', 'desc': 'UI/UX & Product', 'icon': Icons.palette_outlined},
        {'v': 'student', 'l': 'Sinh viên', 'desc': 'Đang học IT', 'icon': Icons.school_outlined},
        {'v': 'other', 'l': 'Khác', 'desc': 'Lĩnh vực khác', 'icon': Icons.more_horiz_rounded},
      ]
    },
    {
      'label': 'Thời gian\nmỗi ngày',
      'sub': 'Bạn dành bao lâu để học?',
      'field': 'mucTieuPhut',
      'accent': Color(0xFFFF6B35),
      'opts': [
        {'v': 5, 'l': '5 phút', 'desc': 'Nhẹ nhàng', 'icon': Icons.coffee_outlined},
        {'v': 10, 'l': '10 phút', 'desc': 'Đều đặn', 'icon': Icons.timer_outlined},
        {'v': 15, 'l': '15 phút', 'desc': 'Tiêu chuẩn', 'icon': Icons.local_fire_department_outlined},
        {'v': 30, 'l': '30 phút', 'desc': 'Nghiêm túc', 'icon': Icons.fitness_center_outlined},
        {'v': 60, 'l': '60 phút', 'desc': 'Chuyên sâu', 'icon': Icons.rocket_launch_outlined},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))..repeat();
    _accentCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardY = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _accentScale = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _accentCtrl, curve: Curves.easeInOut));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _accentCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    final colors = [
      const Color(0xFF00D4FF),
      const Color(0xFF7B2FFF),
      const Color(0xFF00FF94),
      const Color(0xFFFF6B35),
    ];
    return colors[_step];
  }

  void _select(dynamic value) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_step) {
        case 0: _trinhDo = value as String?; break;
        case 1: _mucTieuCapDo = value as String?; break;
        case 2: _hocVi = value as String?; break;
        case 3: _mucTieuPhut = value as int; break;
      }
    });
  }

  dynamic get _cur {
    switch (_step) {
      case 0: return _trinhDo;
      case 1: return _mucTieuCapDo;
      case 2: return _hocVi;
      case 3: return _mucTieuPhut;
      default: return null;
    }
  }

  bool get _hasAnswer => _step == 3 ? true : _cur != null;

  Future<void> _next() async {
    if (!_hasAnswer) return;
    HapticFeedback.mediumImpact();
    if (_step < _questions.length - 1) {
      await _cardCtrl.reverse();
      setState(() => _step++);
      _cardCtrl.forward();
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => AuthScreen(
            trinhDo: _trinhDo ?? 'A1',
            mucTieuCapDo: _mucTieuCapDo ?? 'A2',
            hocVi: _hocVi,
            mucTieuPhut: _mucTieuPhut,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _back() async {
    if (_step == 0) return;
    HapticFeedback.lightImpact();
    await _cardCtrl.reverse();
    setState(() => _step--);
    _cardCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final q = _questions[_step];
    final accent = _accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF06080F),
      body: Stack(children: [
        // ── Ambient background blobs ─────────────────────────
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            size: size,
            painter: _AmbientPainter(_bgCtrl.value, accent),
          ),
        ),

        // ── Dot grid texture ─────────────────────────────────
        CustomPaint(size: size, painter: _DotGridPainter()),

        SafeArea(
          child: Column(children: [
            // ── Top bar ──────────────────────────────────────
            _TopBar(
              step: _step,
              total: _questions.length,
              accent: accent,
              onBack: _back,
            ),

            const SizedBox(height: 8),

            // ── Progress strip ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ProgressStrip(
                step: _step,
                total: _questions.length,
                accent: accent,
              ),
            ),

            const SizedBox(height: 32),

            // ── Content card ──────────────────────────────────
            Expanded(
              child: AnimatedBuilder(
                animation: _cardCtrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _cardY.value),
                  child: Opacity(opacity: _cardFade.value, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Big number indicator ──────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '0${_step + 1}',
                            style: TextStyle(
                              color: accent.withOpacity(0.25),
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -4,
                            ),
                          ),
                          const Spacer(),
                          // Step dots
                          Row(
                            children: List.generate(_questions.length, (i) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(left: 6),
                                width: i == _step ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _step
                                      ? accent
                                      : i < _step
                                          ? accent.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ── Question title ────────────────────
                      Text(
                        q['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -1.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Subtitle with accent line ─────────
                      Row(children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          q['sub'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // ── Options ───────────────────────────
                      Expanded(
                        child: _step == 3
                            ? _TimeOptions(
                                opts: q['opts'] as List,
                                selected: _cur,
                                accent: accent,
                                onSelect: _select,
                              )
                            : _GridOptions(
                                opts: q['opts'] as List,
                                selected: _cur,
                                accent: accent,
                                onSelect: _select,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom CTA ────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
              child: _CtaButton(
                label: _step < _questions.length - 1
                    ? 'Tiếp theo'
                    : 'Bắt đầu học',
                isLast: _step == _questions.length - 1,
                enabled: _hasAnswer,
                accent: accent,
                onTap: _next,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int step, total;
  final Color accent;
  final VoidCallback onBack;

  const _TopBar({
    required this.step,
    required this.total,
    required this.accent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(children: [
        AnimatedOpacity(
          opacity: step > 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: step > 0 ? onBack : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        const Spacer(),
        // Brand mark
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accent.withOpacity(0.6), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'DevTalk',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Progress strip ─────────────────────────────────────────────────────────────
class _ProgressStrip extends StatelessWidget {
  final int step, total;
  final Color accent;

  const _ProgressStrip({
    required this.step,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: i == step ? 3 : 2,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= step
                  ? (i == step ? accent : accent.withOpacity(0.4))
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(2),
              boxShadow: i == step
                  ? [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ── Grid options (for text options) ───────────────────────────────────────────
class _GridOptions extends StatelessWidget {
  final List opts;
  final dynamic selected;
  final Color accent;
  final Function(dynamic) onSelect;

  const _GridOptions({
    required this.opts,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(opts.length, (i) {
          final o = opts[i] as Map;
          final val = o['v'];
          final sel = selected == val;
          return _OptionChip(
            value: val,
            label: o['l'] as String,
            desc: o['desc'] as String,
            icon: o['icon'] as IconData,
            selected: sel,
            accent: accent,
            onSelect: onSelect,
          );
        }),
      ),
    );
  }
}

class _OptionChip extends StatefulWidget {
  final dynamic value;
  final String label, desc;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Function(dynamic) onSelect;

  const _OptionChip({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  @override
  State<_OptionChip> createState() => _OptionChipState();
}

class _OptionChipState extends State<_OptionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 48 - 10) / 2;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onSelect(widget.value);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: w,
        padding: const EdgeInsets.all(16),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.selected
              ? widget.accent.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.selected
                ? widget.accent
                : Colors.white.withOpacity(0.08),
            width: widget.selected ? 1.5 : 1,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(children: [
          // Icon container
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: widget.selected
                  ? widget.accent
                  : Colors.white.withOpacity(0.4),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.desc,
                  style: TextStyle(
                    color: widget.selected
                        ? widget.accent.withOpacity(0.8)
                        : Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.selected)
            Icon(Icons.check_circle_rounded, color: widget.accent, size: 16),
        ]),
      ),
    );
  }
}

// ── Time options (step 3 - special layout) ────────────────────────────────────
class _TimeOptions extends StatelessWidget {
  final List opts;
  final dynamic selected;
  final Color accent;
  final Function(dynamic) onSelect;

  const _TimeOptions({
    required this.opts,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: List.generate(opts.length, (i) {
          final o = opts[i] as Map;
          final val = o['v'];
          final sel = selected == val;
          return _TimeChip(
            value: val,
            label: o['l'] as String,
            desc: o['desc'] as String,
            icon: o['icon'] as IconData,
            selected: sel,
            accent: accent,
            onSelect: onSelect,
            index: i,
            total: opts.length,
          );
        }),
      ),
    );
  }
}

class _TimeChip extends StatefulWidget {
  final dynamic value;
  final String label, desc;
  final IconData icon;
  final bool selected;
  final Color accent;
  final Function(dynamic) onSelect;
  final int index, total;

  const _TimeChip({
    required this.value,
    required this.label,
    required this.desc,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onSelect,
    required this.index,
    required this.total,
  });

  @override
  State<_TimeChip> createState() => _TimeChipState();
}

class _TimeChipState extends State<_TimeChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Progress bar width proportional to minutes
    final values = [5, 10, 15, 30, 60];
    final pct = (widget.value is int)
        ? (widget.value as int) / 60.0
        : 0.25;
    final clampedPct = pct.clamp(0.1, 1.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onSelect(widget.value);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: EdgeInsets.only(bottom: widget.index < widget.total - 1 ? 10 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.selected
              ? widget.accent.withOpacity(0.1)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.selected
                ? widget.accent
                : Colors.white.withOpacity(0.08),
            width: widget.selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: widget.selected
                  ? widget.accent
                  : Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Label + bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.desc,
                    style: TextStyle(
                      color: widget.selected
                          ? widget.accent.withOpacity(0.7)
                          : Colors.white.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Stack(children: [
                  Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 400),
                    widthFactor: widget.selected ? clampedPct : clampedPct * 0.5,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.accent
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: widget.selected
                            ? [BoxShadow(color: widget.accent.withOpacity(0.5), blurRadius: 4)]
                            : null,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Check indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.selected
                  ? widget.accent
                  : Colors.white.withOpacity(0.06),
              border: Border.all(
                color: widget.selected
                    ? widget.accent
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: widget.selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ── CTA Button ─────────────────────────────────────────────────────────────────
class _CtaButton extends StatefulWidget {
  final String label;
  final bool isLast, enabled;
  final Color accent;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.isLast,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.enabled ? widget.accent : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          boxShadow: widget.enabled && !_pressed
              ? [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: widget.enabled
                    ? const Color(0xFF06080F)
                    : Colors.white.withOpacity(0.25),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              widget.isLast
                  ? Icons.rocket_launch_rounded
                  : Icons.arrow_forward_rounded,
              color: widget.enabled
                  ? const Color(0xFF06080F)
                  : Colors.white.withOpacity(0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────────
class _AmbientPainter extends CustomPainter {
  final double t;
  final Color accent;

  _AmbientPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.screen;

    final blobs = [
      [0.15, 0.08, 0.5, accent, 0.7],
      [0.85, 0.25, 0.4, const Color(0xFF7B2FFF), 1.1],
      [0.5, 0.75, 0.45, const Color(0xFF0047FF), 0.8],
    ];

    for (final o in blobs) {
      final x = (o[0] as double) +
          math.sin(t * math.pi * 2 * (o[4] as double)) * 0.07;
      final y = (o[1] as double) +
          math.cos(t * math.pi * 2 * (o[4] as double)) * 0.05;
      final r = (o[2] as double) * size.width;
      final c = o[3] as Color;

      p.shader = RadialGradient(
        colors: [c.withOpacity(0.14), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(x * size.width, y * size.height),
        radius: r,
      ));
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, p);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter o) => o.t != t || o.accent != accent;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.0;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}