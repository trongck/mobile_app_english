import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import '../providers/nhat_ky_provider.dart';
import '../providers/tu_vung_provider.dart';
import '../providers/bai_kt_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _bgAnim;
  late AnimationController _pulseAnim;
  late AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _entryAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();

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
    _bgAnim.dispose();
    _pulseAnim.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.watch<NguoiDungProvider>().nguoiDung;
    final nkP = context.watch<NhatKyProvider>();
    final tvP = context.watch<TuVungProvider>();
    final bktP = context.watch<BaiKTProvider>();

    final firstName = nd?.hoTen?.split(' ').last ?? nd?.email.split('@').first ?? 'Dev';
    final goal = nd?.mucTieuPhut ?? 15;
    final today = _todayKey();
    final todayMinutes = nkP.nhatKy7Ngay[today] ?? 0;
    final pct = goal > 0 ? (todayMinutes / goal).clamp(0.0, 1.0) : 0.0;

    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _entryAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Xin chào, ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15)),
                        Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        const Text(' 👋', style: TextStyle(fontSize: 15)),
                      ]),
                      const SizedBox(height: 2),
                      const Text('Hôm nay học gì nào?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ]),
                  ),
                  _Avatar(name: nd?.hoTen ?? nd?.email ?? 'U'),
                ]),
              ),
            ),

            // ── Daily Goal Card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _DailyGoalCard(
                  todayMinutes: todayMinutes,
                  goal: goal,
                  pct: pct,
                  streak: nkP.chuoiNgay,
                  pulseAnim: _pulseAnim,
                ),
              ),
            ),

            // ── Stats Row ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _StatChip(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B35),
                    value: '${nkP.chuoiNgay}',
                    label: 'ngày streak',
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.style_rounded,
                    color: const Color(0xFF00D4FF),
                    value: '${tvP.tuDaHoc.length}',
                    label: 'từ đã học',
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFF7B2FFF),
                    value: '${bktP.lichSu.length}',
                    label: 'bài đã làm',
                  ),
                ]),
              ),
            ),

            // ── 7-day chart ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _WeeklyChart(nhatKy7Ngay: nkP.nhatKy7Ngay, goal: goal),
              ),
            ),

            // ── Quick Actions ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: const Text('Học nhanh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickCard(icon: '📚', title: 'Từ vựng mới', subtitle: '${tvP.tatCaTuVung.length} từ có sẵn', color: const Color(0xFF00D4FF)),
                    _QuickCard(icon: '🧠', title: 'Làm quiz', subtitle: '${bktP.danhSachBaiKT.length} bài kiểm tra', color: const Color(0xFF7B2FFF)),
                    _QuickCard(icon: '🤖', title: 'Chat AI', subtitle: 'Luyện hội thoại', color: const Color(0xFF00FF94)),
                    _QuickCard(icon: '🎤', title: 'Phát âm', subtitle: 'Luyện nói cùng AI', color: const Color(0xFFFF6B35)),
                  ],
                ),
              ),
            ),

            // ── Recent Quiz History ───────────────────────────────
            if (bktP.lichSu.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Row(children: [
                    const Text('Kết quả gần đây', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${bktP.lichSu.length} bài', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  ]),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i >= 3) return null;
                    final ls = bktP.lichSu[i];
                    final baiKT = bktP.getBaiKT(ls.maBKT);
                    final d = ls.diem ?? 0;
                    final color = d >= 80 ? const Color(0xFF00FF94) : d >= 50 ? const Color(0xFFFFD700) : const Color(0xFFFF3CAC);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text('$d', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(baiKT?.tieuDe ?? 'Bài kiểm tra', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(ls.tgBatDau.substring(0, 10), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('$d/100', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                    );
                  },
                  childCount: bktP.lichSu.length.clamp(0, 3),
                ),
              ),
            ],

            // ── Trình độ & mục tiêu ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _ProfileSummaryCard(nd: nd),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ─── Daily Goal Card ──────────────────────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final int todayMinutes, goal;
  final double pct;
  final int streak;
  final AnimationController pulseAnim;
  const _DailyGoalCard({required this.todayMinutes, required this.goal, required this.pct, required this.streak, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final Color progressColor = pct >= 1.0 ? const Color(0xFF00FF94) : const Color(0xFF00D4FF);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D1535), const Color(0xFF0A0E22)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: progressColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: progressColor.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 64, height: 64,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: 1.0, strokeWidth: 5, color: Colors.white.withOpacity(0.06)),
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => CircularProgressIndicator(
                  value: pct, strokeWidth: 5, strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 1.0 ? const Color(0xFF00FF94) : Color.lerp(const Color(0xFF00D4FF), const Color(0xFF7B2FFF), pulseAnim.value)!,
                  ),
                ),
              ),
              pct >= 1.0
                  ? const Text('✅', style: TextStyle(fontSize: 20))
                  : Text('${(pct * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              pct >= 1.0 ? '🎉 Đạt mục tiêu hôm nay!' : 'Mục tiêu hôm nay',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text('$todayMinutes / $goal phút hoàn thành', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct, minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ])),
        ]),
        if (streak > 1) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Chuỗi $streak ngày học liên tiếp! Tuyệt vời!',
                style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _StatChip({required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10), textAlign: TextAlign.center),
      ]),
    ));
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final Map<String, int> nhatKy7Ngay;
  final int goal;
  const _WeeklyChart({required this.nhatKy7Ngay, required this.goal});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Nhật ký 7 ngày', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('Mục tiêu: $goal phút/ngày', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.asMap().entries.map((e) {
              final day = e.value;
              final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final phut = nhatKy7Ngay[key] ?? 0;
              final pct = goal > 0 ? (phut / goal).clamp(0.0, 1.0) : 0.0;
              final isToday = day.day == now.day && day.month == now.month;
              final color = pct >= 1.0 ? const Color(0xFF00FF94) : pct > 0.5 ? const Color(0xFFFFD700) : const Color(0xFF00D4FF);
              return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (phut > 0) Text('${phut}m', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 26,
                  height: pct > 0 ? (pct * 56).clamp(4.0, 56.0) : 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: pct > 0 ? [color, color.withOpacity(0.4)] : [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.06)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(dayLabels[day.weekday % 7], style: TextStyle(
                  color: isToday ? Colors.white : Colors.white.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                )),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Quick Card ───────────────────────────────────────────────────────────────
class _QuickCard extends StatefulWidget {
  final String icon, title, subtitle;
  final Color color;
  const _QuickCard({required this.icon, required this.title, required this.subtitle, required this.color});
  @override
  State<_QuickCard> createState() => _QuickCardState();
}
class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); HapticFeedback.lightImpact(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        width: 140,
        margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.icon, style: const TextStyle(fontSize: 28)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(widget.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ]),
      ),
    );
  }
}

// ─── Profile Summary Card ─────────────────────────────────────────────────────
class _ProfileSummaryCard extends StatelessWidget {
  final dynamic nd;
  const _ProfileSummaryCard({required this.nd});
  @override
  Widget build(BuildContext context) {
    if (nd == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Hồ sơ học tập', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          _ProfileItem('📊', 'Trình độ', nd.trinhDo ?? 'A1', const Color(0xFF00D4FF)),
          const SizedBox(width: 10),
          _ProfileItem('🎯', 'Mục tiêu', nd.mucTieuCapDo ?? 'A2', const Color(0xFF7B2FFF)),
          const SizedBox(width: 10),
          _ProfileItem('⏱️', 'Mỗi ngày', '${nd.mucTieuPhut ?? 15}p', const Color(0xFFFF6B35)),
        ]),
      ]),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _ProfileItem(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
      ]),
    ));
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 12)],
      ),
      child: Center(child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
      )),
    );
  }
}