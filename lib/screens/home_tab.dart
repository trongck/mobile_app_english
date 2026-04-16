import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late AnimationController _bannerAnim;
  late AnimationController _pulseAnim;
  int _currentBanner = 0;
  final PageController _bannerCtrl = PageController();

  @override
  void initState() {
    super.initState();
    _bannerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    // Auto-scroll banners
    Future.delayed(const Duration(seconds: 3), _autoBanner);
  }

  void _autoBanner() {
    if (!mounted) return;
    final next = (_currentBanner + 1) % _banners.length;
    _bannerCtrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 4), _autoBanner);
  }

  @override
  void dispose() {
    _bannerAnim.dispose();
    _pulseAnim.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  static const _banners = [
    _BannerData(
      title: 'DevTalk PRO',
      subtitle: 'Mở khóa 10,000+ từ vựng & AI tutor không giới hạn',
      tag: '🔥 HOT DEAL',
      gradient: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
    ),
    _BannerData(
      title: 'Học miễn phí 7 ngày',
      subtitle: 'Trải nghiệm toàn bộ tính năng PRO không cần thẻ tín dụng',
      tag: '⚡ FREE TRIAL',
      gradient: [Color(0xFF00FF94), Color(0xFF00A8FF)],
    ),
    _BannerData(
      title: 'Cộng đồng IT lớn nhất',
      subtitle: '50,000+ developer đang học tiếng Anh cùng DevTalk',
      tag: '👥 COMMUNITY',
      gradient: [Color(0xFFFF6B35), Color(0xFFFF3CAC)],
    ),
  ];

  static const _notifications = [
    _NotifData(icon: Icons.emoji_events_rounded, color: Color(0xFFFFD700), title: 'Chuỗi học 7 ngày!', body: 'Bạn đã duy trì học liên tiếp 7 ngày. Tuyệt vời!', time: '2 phút trước', isNew: true),
    _NotifData(icon: Icons.school_rounded, color: Color(0xFF00D4FF), title: 'Bài kiểm tra mới', body: 'Quiz "Cloud Computing Basics" vừa được thêm vào.', time: '1 giờ trước', isNew: true),
    _NotifData(icon: Icons.tips_and_updates_rounded, color: Color(0xFF7B2FFF), title: 'Mẹo học hôm nay', body: 'Lặp lại 10 từ vựng đã học để củng cố trí nhớ.', time: '3 giờ trước', isNew: false),
    _NotifData(icon: Icons.celebration_rounded, color: Color(0xFF00FF94), title: 'Đạt mục tiêu!', body: 'Bạn đã hoàn thành mục tiêu 15 phút học hôm nay.', time: 'Hôm qua', isNew: false),
  ];

  static const _plans = [
    _PlanData(
      name: 'Free', price: '0đ', period: '/tháng',
      features: ['500 từ vựng cơ bản', '3 bài quiz/tuần', 'AI chat giới hạn'],
      color: Color(0xFF4A5568), isCurrent: true, isPro: false,
    ),
    _PlanData(
      name: 'PRO', price: '99K', period: '/tháng',
      features: ['10,000+ từ vựng IT', 'Quiz không giới hạn', 'AI tutor 24/7', 'Phát âm & luyện nói', 'Không quảng cáo'],
      color: Color(0xFF00D4FF), isCurrent: false, isPro: true,
    ),
    _PlanData(
      name: 'TEAM', price: '199K', period: '/tháng',
      features: ['Tất cả PRO', 'Quản lý nhóm 5 người', 'Báo cáo tiến độ', 'Hỗ trợ ưu tiên'],
      color: Color(0xFF7B2FFF), isCurrent: false, isPro: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final nd = context.watch<NguoiDungProvider>().nguoiDung;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Xin chào, ${nd?.hoTen?.split(' ').last ?? 'Dev'} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text('Hôm nay học gì nào?', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                ]),
                const Spacer(),
                _NotifBell(count: 2),
                const SizedBox(width: 12),
                _Avatar(name: nd?.hoTen ?? nd?.email ?? 'U'),
              ]),
            ),
          ),

          // ── Daily goal strip ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _DailyGoalCard(nd: nd, pulseAnim: _pulseAnim),
            ),
          ),

          // ── Banner carousel ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(children: [
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _bannerCtrl,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _currentBanner = i),
                  itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length, (i) {
                final isActive = i == _currentBanner;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF00D4FF) : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              })),
            ]),
          ),

          // ── Section: Thông báo ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(children: [
                const Text('Thông báo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('Xem tất cả', style: TextStyle(color: const Color(0xFF00D4FF), fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _NotifCard(data: _notifications[i]),
              childCount: _notifications.length,
            ),
          ),

          // ── Section: Gói dịch vụ ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('PREMIUM', style: TextStyle(color: Color(0xFF080B1A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(width: 10),
                const Text('Nâng cấp ngay', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _plans.length,
                itemBuilder: (_, i) => _PlanCard(data: _plans[i]),
              ),
            ),
          ),

          // ── Quick stats ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
              child: const Text('Thống kê của bạn', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _StatsGrid(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ─── Daily goal card ──────────────────────────────────────────────────────────
class _DailyGoalCard extends StatelessWidget {
  final dynamic nd;
  final AnimationController pulseAnim;

  const _DailyGoalCard({required this.nd, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final goal = nd?.mucTieuPhut ?? 15;
    const done = 7; // mock data
    final pct = (done / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.2)),
      ),
      child: Row(children: [
        // Circle progress
        SizedBox(
          width: 56, height: 56,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              color: Colors.white.withOpacity(0.06),
            ),
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => CircularProgressIndicator(
                value: pct,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(const Color(0xFF00D4FF), const Color(0xFF7B2FFF), pulseAnim.value)!,
                ),
              ),
            ),
            Text('${(pct * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mục tiêu hôm nay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('$done / $goal phút hoàn thành', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct, minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Học tiếp', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Banner card ──────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: data.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: data.gradient[0].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        // Decorative circle
        Positioned(right: -20, top: -20, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
        )),
        Positioned(right: 30, bottom: -30, child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
        )),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(data.tag, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 10),
            Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(data.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ]),
        ),
        Positioned(right: 18, bottom: 10, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Text('Xem ngay →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        )),
      ]),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────
class _NotifCard extends StatefulWidget {
  final _NotifData data;
  const _NotifCard({required this.data});
  @override State<_NotifCard> createState() => _NotifCardState();
}
class _NotifCardState extends State<_NotifCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); HapticFeedback.lightImpact(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _pressed ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.data.isNew ? widget.data.color.withOpacity(0.3) : Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: widget.data.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(widget.data.icon, color: widget.data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(widget.data.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              if (widget.data.isNew) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text(widget.data.body, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Text(widget.data.time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ]),
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatefulWidget {
  final _PlanData data;
  const _PlanCard({required this.data});
  @override State<_PlanCard> createState() => _PlanCardState();
}
class _PlanCardState extends State<_PlanCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  @override void initState() { super.initState(); _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.data.isPro;
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isPro
              ? LinearGradient(colors: [widget.data.color.withOpacity(0.18), widget.data.color.withOpacity(0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isPro ? null : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPro ? widget.data.color.withOpacity(0.5) : Colors.white.withOpacity(0.09),
            width: isPro ? 1.5 : 1,
          ),
          boxShadow: isPro ? [BoxShadow(color: widget.data.color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.data.name, style: TextStyle(
              color: isPro ? widget.data.color : Colors.white,
              fontSize: 18, fontWeight: FontWeight.w900,
            )),
            if (isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.data.color, widget.data.color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 11)),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(widget.data.price, style: TextStyle(
              color: isPro ? widget.data.color : Colors.white,
              fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1,
            )),
            Text(widget.data.period, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          ...widget.data.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, size: 14, color: isPro ? widget.data.color : Colors.white.withOpacity(0.4)),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
            ]),
          )),
          const Spacer(),
          Container(
            width: double.infinity, height: 40,
            decoration: BoxDecoration(
              gradient: widget.data.isCurrent ? null : LinearGradient(
                colors: [widget.data.color, widget.data.color.withOpacity(0.7)],
              ),
              color: widget.data.isCurrent ? Colors.white.withOpacity(0.06) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(
              widget.data.isCurrent ? 'Đang dùng' : 'Chọn gói',
              style: TextStyle(
                color: widget.data.isCurrent ? Colors.white.withOpacity(0.4) : Colors.white,
                fontWeight: FontWeight.w700, fontSize: 13,
              ),
            )),
          ),
        ]),
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      {'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF6B35), 'value': '7', 'label': 'Ngày liên tiếp'},
      {'icon': Icons.style_rounded, 'color': const Color(0xFF00D4FF), 'value': '124', 'label': 'Từ đã học'},
      {'icon': Icons.quiz_rounded, 'color': const Color(0xFF7B2FFF), 'value': '12', 'label': 'Bài quiz'},
      {'icon': Icons.timer_rounded, 'color': const Color(0xFF00FF94), 'value': '3.2h', 'label': 'Tổng thời gian'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.7,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (s['color'] as Color).withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: (s['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(s['value'] as String, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              Text(s['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
            ]),
          ]),
        );
      },
    );
  }
}

// ─── Notification bell ────────────────────────────────────────────────────────
class _NotifBell extends StatefulWidget {
  final int count;
  const _NotifBell({required this.count});
  @override State<_NotifBell> createState() => _NotifBellState();
}
class _NotifBellState extends State<_NotifBell> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); Future.delayed(const Duration(seconds: 2), () { if (mounted) _c.repeat(reverse: true); }); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.rotate(
        angle: math.sin(_c.value * math.pi) * 0.2,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08))),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
          if (widget.count > 0)
            Positioned(top: -3, right: -3, child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(color: Color(0xFFFF3CAC), shape: BoxShape.circle),
              child: Center(child: Text('${widget.count}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
            )),
        ]),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 10)],
      ),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _BannerData {
  final String title, subtitle, tag;
  final List<Color> gradient;
  const _BannerData({required this.title, required this.subtitle, required this.tag, required this.gradient});
}

class _NotifData {
  final IconData icon;
  final Color color;
  final String title, body, time;
  final bool isNew;
  const _NotifData({required this.icon, required this.color, required this.title, required this.body, required this.time, required this.isNew});
}

class _PlanData {
  final String name, price, period;
  final List<String> features;
  final Color color;
  final bool isCurrent, isPro;
  const _PlanData({required this.name, required this.price, required this.period, required this.features, required this.color, required this.isCurrent, required this.isPro});
}