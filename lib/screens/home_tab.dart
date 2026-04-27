import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import '../providers/nhat_ky_provider.dart';
import '../providers/tu_vung_provider.dart';
import '../providers/bai_kt_provider.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _T {
  // Palette
  static const bg = Color(0xFF080B1A);
  static const surface1 = Color(0xFF0F1320);
  static const surface2 = Color(0xFF151A2E);
  static const cyan = Color(0xFF00D4FF);
  static const violet = Color(0xFF7B2FFF);
  static const emerald = Color(0xFF00FF94);
  static const amber = Color(0xFFFFB800);
  static const coral = Color(0xFFFF6058);
  static const pink = Color(0xFFFF3CAC);

  // Typography
  static const TextStyle displayLg = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    height: 1.1,
  );
  static const TextStyle displaySm = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.6,
    height: 1.2,
  );
  static const TextStyle labelMd = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static const TextStyle caption = TextStyle(
    color: Color(0xFF6B7A99),
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // Spacing (8dp rhythm)
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radius
  static const double rMd = 16;
  static const double rLg = 22;
  static const double rXl = 28;
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _entryAnim;
  late AnimationController _pulseAnim;
  late AnimationController _orbitAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _orbitAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      if (nd != null) {
        context.read<NhatKyProvider>().layNhatKy7Ngay(nd.maND!);
        context.read<TuVungProvider>().khoiTaoDuLieu();
        context.read<BaiKTProvider>().khoiTao(nd.maND);
      }
    });
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _pulseAnim.dispose();
    _orbitAnim.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.watch<NguoiDungProvider>().nguoiDung;
    final nkP = context.watch<NhatKyProvider>();
    final tvP = context.watch<TuVungProvider>();
    final bktP = context.watch<BaiKTProvider>();

    final firstName =
        nd?.hoTen?.split(' ').last ?? nd?.email.split('@').first ?? 'Dev';
    final goal = nd?.mucTieuPhut ?? 15;
    final todayMinutes = nkP.nhatKy7Ngay[_todayKey()] ?? 0;
    final pct = goal > 0 ? (todayMinutes / goal).clamp(0.0, 1.0) : 0.0;
    final streak = nkP.chuoiNgay;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: _entryAnim,
        builder: (_, child) => Opacity(
          opacity: Curves.easeOut.transform(_entryAnim.value),
          child: child,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _TopBar(
                firstName: firstName,
                nd: nd,
                anim: _entryAnim,
              ),
            ),

            // ── Hero Goal Tile ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    _T.s16, _T.s16, _T.s16, 0),
                child: _HeroGoalTile(
                  todayMinutes: todayMinutes,
                  goal: goal,
                  pct: pct,
                  streak: streak,
                  pulseAnim: _pulseAnim,
                  orbitAnim: _orbitAnim,
                ),
              ),
            ),

            // ── Bento Stats Row ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    _T.s16, _T.s12, _T.s16, 0),
                child: _BentoStatsRow(
                  streak: streak,
                  wordsLearned: tvP.tuDaHoc.length,
                  quizDone: bktP.lichSu.length,
                ),
              ),
            ),

            // ── Week Chart ────────────────────────────────────────
            Expanded(
              child: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      _T.s16, _T.s12, _T.s16, 0),
                  child: _WeekBarChart(
                    nhatKy7Ngay: nkP.nhatKy7Ngay,
                    goal: goal,
                  ),
                ),
              ),
            ),

            // ── Quick Actions Label ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(

                padding: const EdgeInsets.fromLTRB(
                    _T.s16, _T.s24, _T.s16, _T.s8),
                child: Row(children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_T.cyan, _T.violet],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: _T.s8),
                  const Text('Học nhanh', style: _T.displaySm),
                ]),
              ),
            ),

            // ── Quick Actions Bento Grid ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _T.s16),
                child: _QuickActionsBento(
                  vocabCount: tvP.tatCaTuVung.length,
                  quizCount: bktP.danhSachBaiKT.length,
                ),
              ),
            ),

            // ── Recent Results ────────────────────────────────────
            if (bktP.lichSu.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      _T.s16, _T.s24, _T.s16, _T.s8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_T.amber, _T.coral],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: _T.s8),
                        const Text('Kết quả gần đây',
                            style: _T.displaySm),
                      ]),
                      Text('${bktP.lichSu.length} bài',
                          style: _T.caption),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i >= 3) return null;
                    final ls = bktP.lichSu[i];
                    final baiKT = bktP.getBaiKT(ls.maBKT);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _T.s16, 0, _T.s16, _T.s8),
                      child: _ResultCard(
                        title: baiKT?.tieuDe ?? 'Bài kiểm tra',
                        score: ls.diem ?? 0,
                        date: ls.tgBatDau.substring(0, 10),
                        index: i,
                      ),
                    );
                  },
                  childCount: bktP.lichSu.length.clamp(0, 3),
                ),
              ),
            ],

            // ── Profile Summary ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    _T.s16, _T.s24, _T.s16, 0),
                child: _ProfileSummaryTile(nd: nd),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String firstName;
  final dynamic nd;
  final Animation<double> anim;

  const _TopBar(
      {required this.firstName, required this.nd, required this.anim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _T.s20, _T.s20, _T.s20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: _T.cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                const Text('Dashboard', style: _T.displayLg),
              ],
            ),
          ),
          // Avatar with notification dot
          Stack(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_T.violet, _T.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _T.violet.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  nd?.hoTen?.isNotEmpty == true
                      ? nd!.hoTen![0].toUpperCase()
                      : nd?.email[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _T.emerald,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _T.bg, width: 2),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng,';
    if (h < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }
}

// ─── Hero Goal Tile ───────────────────────────────────────────────────────────
class _HeroGoalTile extends StatelessWidget {
  final int todayMinutes, goal, streak;
  final double pct;
  final AnimationController pulseAnim, orbitAnim;

  const _HeroGoalTile({
    required this.todayMinutes,
    required this.goal,
    required this.pct,
    required this.streak,
    required this.pulseAnim,
    required this.orbitAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = pct >= 1.0;
    final accentColor = isComplete ? _T.emerald : _T.cyan;

    return Container(
      height: 186,
      decoration: BoxDecoration(
        color: _T.surface1,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(
          color: accentColor.withOpacity(0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.rXl),
        child: Stack(children: [
          // Background noise texture via paint
          AnimatedBuilder(
            animation: orbitAnim,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 186),
              painter: _HeroBgPainter(orbitAnim.value, accentColor),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(_T.s20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: text + bar ──────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isComplete
                              ? 'MỤC TIÊU HOÀN THÀNH'
                              : 'MỤC TIÊU HÔM NAY',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: _T.s12),

                      // Big number
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '$todayMinutes',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: '/$goal',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: ' phút',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]),
                      ),

                      const Spacer(),

                      // Progress bar (segmented)
                      _SegmentedBar(pct: pct, color: accentColor),

                      const SizedBox(height: 6),

                      Text(
                        '${(pct * 100).round()}% hoàn thành',
                        style: _T.caption,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: _T.s16),

                // ── Right: ring + streak ──────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Ring progress
                    AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (_, __) => SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _RingPainter(
                            progress: pct,
                            pulseValue: pulseAnim.value,
                            color: accentColor,
                          ),
                          child: Center(
                            child: isComplete
                                ? Icon(Icons.check_rounded,
                                    color: accentColor, size: 28)
                                : Text(
                                    '${(pct * 100).round()}%',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Streak badge
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _T.coral.withOpacity(0.9),
                              _T.amber.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$streak ngày',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Segmented progress bar ────────────────────────────────────────────────────
class _SegmentedBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _SegmentedBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    const segments = 12;
    final filled = (pct * segments).round().clamp(0, segments);
    return Row(
      children: List.generate(segments, (i) {
        final active = i < filled;
        return Expanded(
          child: Container(
            height: 4,
            margin:
                EdgeInsets.only(right: i < segments - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: active
                  ? color
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Bento Stats Row ──────────────────────────────────────────────────────────
class _BentoStatsRow extends StatelessWidget {
  final int streak, wordsLearned, quizDone;
  const _BentoStatsRow(
      {required this.streak,
      required this.wordsLearned,
      required this.quizDone});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatTile(
        value: '$streak',
        label: 'Streak',
        icon: Icons.local_fire_department_rounded,
        color: _T.coral,
        flex: 2,
      ),
      const SizedBox(width: _T.s8),
      _StatTile(
        value: '$wordsLearned',
        label: 'Từ học',
        icon: Icons.auto_stories_rounded,
        color: _T.cyan,
        flex: 3,
      ),
      const SizedBox(width: _T.s8),
      _StatTile(
        value: '$quizDone',
        label: 'Quiz',
        icon: Icons.quiz_rounded,
        color: _T.violet,
        flex: 2,
      ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final int flex;
  const _StatTile(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color,
      required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: _T.s12, vertical: _T.s12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(_T.rMd),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: _T.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(label, style: _T.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Week Bar Chart ────────────────────────────────────────────────────────────
class _WeekBarChart extends StatelessWidget {
  final Map<String, int> nhatKy7Ngay;
  final int goal;
  const _WeekBarChart(
      {required this.nhatKy7Ngay, required this.goal});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final maxMin = [
      ...nhatKy7Ngay.values,
      goal.toDouble().toInt()
    ].fold<int>(0, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          _T.s16, _T.s16, _T.s16, _T.s12),
      decoration: BoxDecoration(
        color: _T.surface1,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Tuần này', style: _T.labelMd),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _T.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Mục tiêu $goal phút/ngày',
                style: const TextStyle(
                  color: _T.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: _T.s16),
          SizedBox(
            height: 88,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.asMap().entries.map((e) {
                final day = e.value;
                final key =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final phut = nhatKy7Ngay[key] ?? 0;
                final heightPct = maxMin > 0
                    ? (phut / maxMin).clamp(0.0, 1.0)
                    : 0.0;
                final goalPct = maxMin > 0 && goal > 0
                    ? (goal / maxMin).clamp(0.0, 1.0)
                    : 0.7;
                final isToday =
                    day.day == now.day && day.month == now.month;
                final reachedGoal = phut >= goal && goal > 0;
                final barColor = reachedGoal
                    ? _T.emerald
                    : phut > 0
                        ? _T.cyan
                        : Colors.white.withOpacity(0.06);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: [
                        // Value label
                        if (phut > 0)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 3),
                            child: Text(
                              '${phut}m',
                              style: TextStyle(
                                color: barColor ==
                                        Colors.white.withOpacity(0.06)
                                    ? Colors.transparent
                                    : barColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        // Bar
                        Expanded(
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Track
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.05),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                              ),
                              // Fill
                              AnimatedFractionallySizedBox(
                                alignment:
                                    Alignment.bottomCenter,
                                heightFactor: heightPct
                                    .clamp(0.04, 1.0),
                                duration: const Duration(
                                    milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    boxShadow: phut > 0
                                        ? [
                                            BoxShadow(
                                              color: barColor
                                                  .withOpacity(
                                                      0.4),
                                              blurRadius: 8,
                                              offset:
                                                  const Offset(
                                                      0, -2),
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                              // Goal line
                              Align(
                                alignment: FractionalOffset(
                                    0.5, 1 - goalPct),
                                child: Container(
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    color: _T.amber
                                        .withOpacity(0.5),
                                    borderRadius:
                                        BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Day label
                        Text(
                          labels[day.weekday % 7],
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : Colors.white
                                    .withOpacity(0.3),
                            fontSize: 9,
                            fontWeight: isToday
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        // Today dot
                        Container(
                          margin: const EdgeInsets.only(
                              top: 3),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isToday
                                ? _T.cyan
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Bento ─────────────────────────────────────────────────────
class _QuickActionsBento extends StatelessWidget {
  final int vocabCount, quizCount;
  const _QuickActionsBento(
      {required this.vocabCount, required this.quizCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Từ vựng — tall left card
        Expanded(
          flex: 5,
          child: _ActionCard(
            icon: Icons.auto_stories_rounded,
            title: 'Từ vựng',
            subtitle: '$vocabCount từ có sẵn',
            badge: 'IT Terms',
            color: _T.cyan,
            tall: true,
          ),
        ),
        const SizedBox(width: _T.s8),
        // Right column: 2 small stacked
        Expanded(
          flex: 4,
          child: Column(children: [
            _ActionCard(
              icon: Icons.quiz_rounded,
              title: 'Quiz',
              subtitle: '$quizCount đề thi',
              badge: null,
              color: _T.violet,
              tall: false,
            ),
            const SizedBox(height: _T.s8),
            _ActionCard(
              icon: Icons.smart_toy_rounded,
              title: 'AI Chat',
              subtitle: 'Luyện hội thoại',
              badge: 'Live',
              color: _T.emerald,
              tall: false,
            ),
          ]),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final Color color;
  final bool tall;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.badge,
      required this.color,
      required this.tall});
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: widget.tall ? 180 : 86,
        padding: const EdgeInsets.all(_T.s12),
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(
              color: widget.color.withOpacity(0.2)),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_T.s4),
          child: widget.tall
              ? Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon + badge
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.color
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Icon(widget.icon,
                                color: widget.color,
                                size: 22),
                          ),
                          if (widget.badge != null)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.color
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.badge!,
                                style: TextStyle(
                                  color: widget.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Text
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(widget.subtitle,
                              style: _T.caption),
                          const SizedBox(height: _T.s8),
                          Row(children: [
                            Text(
                              'Xem ngay',
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                                Icons
                                    .arrow_forward_rounded,
                                color: widget.color,
                                size: 12),
                          ]),
                        ],
                      ),
                    ],
                  ),
              )
              : Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.color
                            .withOpacity(0.14),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon,
                          color: widget.color,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            if (widget.badge != null) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 5,
                                        vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color
                                      .withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                ),
                                child: Text(
                                  widget.badge!,
                                  style: TextStyle(
                                    color: widget.color,
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ]),
                          Text(widget.subtitle,
                              style: _T.caption,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Padding constant missing in _T — define here
extension _TPadding on _T {
  static const double s14 = 14;
}

const double _s14 = 14;

// ─── Result Card ─────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final String title, date;
  final int score, index;
  const _ResultCard(
      {required this.title,
      required this.score,
      required this.date,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final Color scoreColor;
    final String grade;
    if (score >= 80) {
      scoreColor = _T.emerald;
      grade = 'A';
    } else if (score >= 60) {
      scoreColor = _T.amber;
      grade = 'B';
    } else if (score >= 40) {
      scoreColor = _T.coral;
      grade = 'C';
    } else {
      scoreColor = _T.pink;
      grade = 'D';
    }

    return Container(
      padding: const EdgeInsets.all(_s14),
      decoration: BoxDecoration(
        color: _T.surface1,
        borderRadius: BorderRadius.circular(_T.rMd),
        border: Border.all(
            color: scoreColor.withOpacity(0.15)),
      ),
      child: Row(children: [
        // Grade badge
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: scoreColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              grade,
              style: TextStyle(
                color: scoreColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: _T.s12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(date, style: _T.caption),
            ],
          ),
        ),
        // Score pill
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              color: scoreColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Profile Summary Tile ─────────────────────────────────────────────────────
class _ProfileSummaryTile extends StatelessWidget {
  final dynamic nd;
  const _ProfileSummaryTile({required this.nd});

  static const _levelMap = {
    'A1': 'Mới bắt đầu',
    'A2': 'Sơ cấp',
    'B1': 'Trung cấp',
    'B2': 'Trên trung cấp',
    'C1': 'Nâng cao',
    'C2': 'Thành thạo',
  };

  @override
  Widget build(BuildContext context) {
    if (nd == null) return const SizedBox();
    final trinhDo = nd.trinhDo ?? 'A1';
    final mucTieu = nd.mucTieuCapDo ?? 'A2';
    final phut = nd.mucTieuPhut ?? 15;

    // Progress between levels
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final curIdx = levels.indexOf(trinhDo);
    final goalIdx = levels.indexOf(mucTieu);
    final levelPct = (goalIdx > curIdx && goalIdx > 0)
        ? (curIdx / (levels.length - 1))
        : (curIdx / (levels.length - 1));

    return Container(
      padding: const EdgeInsets.all(_T.s16),
      decoration: BoxDecoration(
        color: _T.surface1,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Hồ sơ học tập',
                style: _T.labelMd),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _T.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trinhDo,
                style: const TextStyle(
                  color: _T.violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ]),
          const SizedBox(height: _T.s16),
          // Level progress visual
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$trinhDo → $mucTieu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _levelMap[trinhDo] ?? trinhDo,
                        style: _T.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: levelPct,
                      minHeight: 6,
                      backgroundColor:
                          _T.violet.withOpacity(0.1),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                              _T.violet),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: _T.s12),
          // Info chips row
          Row(children: [
            _InfoChip(
              icon: Icons.timer_outlined,
              label: '${phut}p/ngày',
              color: _T.amber,
            ),
            const SizedBox(width: _T.s8),
            _InfoChip(
              icon: Icons.flag_rounded,
              label: 'Đạt $mucTieu',
              color: _T.violet,
            ),
            const SizedBox(width: _T.s8),
            if (nd.hocVi != null)
              _InfoChip(
                icon: Icons.work_outline_rounded,
                label: _shortHocVi(nd.hocVi),
                color: _T.cyan,
              ),
          ]),
        ],
      ),
    );
  }

  String _shortHocVi(String? v) {
    const map = {
      'developer': 'Dev',
      'devops': 'DevOps',
      'ai_ml': 'AI/ML',
      'designer': 'Design',
      'student': 'Sinh viên',
      'other': 'Khác',
    };
    return map[v] ?? v ?? '';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

// ── Custom Painters ────────────────────────────────────────────────────────────

class _HeroBgPainter extends CustomPainter {
  final double t;
  final Color accent;
  _HeroBgPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Subtle moving blobs
    for (final o in [
      [0.85, 0.2, 0.55, accent, 0.7],
      [0.15, 0.8, 0.45, _T.violet, 1.0],
    ]) {
      final x = (o[0] as double) +
          math.sin(t * math.pi * 2 * (o[4] as double)) * 0.06;
      final y = (o[1] as double) +
          math.cos(t * math.pi * 2 * (o[4] as double)) * 0.08;
      final r = (o[2] as double) * size.width;
      paint.shader = RadialGradient(
        colors: [
          (o[3] as Color).withOpacity(0.1),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(x * size.width, y * size.height),
          radius: r));
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_HeroBgPainter o) => o.t != t;
}

class _RingPainter extends CustomPainter {
  final double progress, pulseValue;
  final Color color;
  _RingPainter(
      {required this.progress,
      required this.pulseValue,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 6;

    // Track
    canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = color.withOpacity(0.12));

    if (progress <= 0) return;

    // Arc
    final sweepAngle = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.2), color],
        stops: const [0.0, 1.0],
        transform:
            GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: radius));

    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Glow dot at end
    if (progress > 0.02) {
      final angle = -math.pi / 2 + sweepAngle;
      final dotX = cx + radius * math.cos(angle);
      final dotY = cy + radius * math.sin(angle);
      canvas.drawCircle(
          Offset(dotX, dotY),
          5 + pulseValue * 2,
          Paint()
            ..color = color.withOpacity(0.9)
            ..maskFilter = const MaskFilter.blur(
                BlurStyle.normal, 4));
      canvas.drawCircle(
          Offset(dotX, dotY),
          3.5,
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.pulseValue != pulseValue;
}