import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import '../providers/tu_vung_provider.dart';
import '../providers/nguoi_dung_provider.dart';
import '../models/devtalk_model.dart';

class TuVungScreen extends StatefulWidget {
  const TuVungScreen({super.key});
  @override
  State<TuVungScreen> createState() => _TuVungScreenState();
}

class _TuVungScreenState extends State<TuVungScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _headerAnim;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TuVungProvider>();
      p.khoiTaoDuLieu();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _headerAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        // Header
        AnimatedBuilder(
          animation: _headerAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, (1 - _headerAnim.value) * -30),
            child: Opacity(opacity: _headerAnim.value, child: child),
          ),
          child: _buildHeader(),
        ),
        // Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.4),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Chủ đề'),
              Tab(text: 'Tất cả'),
              Tab(text: 'Ôn tập'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ChuDeTab(),
              _TatCaTab(search: _search),
              _OnTapTab(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Từ Vựng IT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('3,000+ từ chuyên ngành', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
        const SizedBox(height: 14),
        // Search bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color(0xFF00D4FF),
            decoration: InputDecoration(
              hintText: 'Tìm từ vựng...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Chủ đề tab ────────────────────────────────────────────────────────────────
class _ChuDeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TuVungProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
        if (p.danhSachChuDe.isEmpty) return _EmptyState(msg: 'Chưa có chủ đề nào');
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          ),
          itemCount: p.danhSachChuDe.length,
          itemBuilder: (_, i) => _ChuDeCard(chuDe: p.danhSachChuDe[i]),
        );
      },
    );
  }
}

class _ChuDeCard extends StatefulWidget {
  final CDTuVung chuDe;
  const _ChuDeCard({required this.chuDe});
  @override
  State<_ChuDeCard> createState() => _ChuDeCardState();
}

class _ChuDeCardState extends State<_ChuDeCard> {
  bool _pressed = false;
  static const _icons = ['💻', '☁️', '🤖', '🎨', '🔧', '📊', '🔐', '🌐', '📱', '🎯'];
  static const _colors = [Color(0xFF00D4FF), Color(0xFF7B2FFF), Color(0xFF00FF94), Color(0xFFFF6B35), Color(0xFFFFD700), Color(0xFFFF3CAC), Color(0xFF4ECDC4), Color(0xFF45B7D1), Color(0xFFFF8C00), Color(0xFF00D4FF)];

  @override
  Widget build(BuildContext context) {
    final idx = widget.chuDe.maCD != null ? (widget.chuDe.maCD! - 1) % 10 : 0;
    final color = _colors[idx];
    final icon = _icons[idx];
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => _TuVungChuDeScreen(chuDe: widget.chuDe, color: color)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.chuDe.tenCD, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Xem từ vựng →', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Tất cả tab ────────────────────────────────────────────────────────────────
class _TatCaTab extends StatelessWidget {
  final String search;
  const _TatCaTab({required this.search});
  @override
  Widget build(BuildContext context) {
    return Consumer<TuVungProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
        var list = p.tatCaTuVung;
        if (search.isNotEmpty) {
          list = list.where((t) => t.tu.toLowerCase().contains(search.toLowerCase()) || (t.nghiaVI?.toLowerCase().contains(search.toLowerCase()) ?? false)).toList();
        }
        if (list.isEmpty) return _EmptyState(msg: 'Không tìm thấy từ vựng');
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: list.length,
          itemBuilder: (_, i) => _TuVungCard(tu: list[i]),
        );
      },
    );
  }
}

// ─── Ôn tập tab ────────────────────────────────────────────────────────────────
class _OnTapTab extends StatefulWidget {
  @override
  State<_OnTapTab> createState() => _OnTapTabState();
}

class _OnTapTabState extends State<_OnTapTab> with SingleTickerProviderStateMixin {
  late TabController _sub;
  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      if (nd != null) context.read<TuVungProvider>().layOnTap(nd.maND!);
    });
  }
  @override
  void dispose() { _sub.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          _SubTab(ctrl: _sub, idx: 0, label: '❤️ Yêu thích', color: const Color(0xFFFF3CAC)),
          const SizedBox(width: 8),
          _SubTab(ctrl: _sub, idx: 1, label: '✅ Đã học', color: const Color(0xFF00FF94)),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _sub,
          children: [
            Consumer<TuVungProvider>(
              builder: (_, p, __) => p.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3CAC), strokeWidth: 2))
                  : p.tuYeuThich.isEmpty ? _EmptyState(msg: 'Chưa có từ yêu thích') : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: p.tuYeuThich.length,
                      itemBuilder: (_, i) => _TuVungCard(tu: p.tuYeuThich[i]),
                    ),
            ),
            Consumer<TuVungProvider>(
              builder: (_, p, __) => p.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF94), strokeWidth: 2))
                  : p.tuDaHoc.isEmpty ? _EmptyState(msg: 'Chưa có từ đã học') : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: p.tuDaHoc.length,
                      itemBuilder: (_, i) => _TuVungCard(tu: p.tuDaHoc[i]),
                    ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _SubTab extends StatelessWidget {
  final TabController ctrl;
  final int idx;
  final String label;
  final Color color;
  const _SubTab({required this.ctrl, required this.idx, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final active = ctrl.index == idx;
        return GestureDetector(
          onTap: () => ctrl.animateTo(idx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
            ),
            child: Text(label, style: TextStyle(color: active ? color : Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }
}

// ─── Từ vựng card ──────────────────────────────────────────────────────────────
class _TuVungCard extends StatefulWidget {
  final TuVung tu;
  const _TuVungCard({required this.tu});
  @override
  State<_TuVungCard> createState() => _TuVungCardState();
}

class _TuVungCardState extends State<_TuVungCard> {
  bool _pressed = false;
  final FlutterTts _tts = FlutterTts();

  Future<void> _speak() async {
    HapticFeedback.lightImpact();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.7);
    await _tts.speak(widget.tu.tu);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<TuVungProvider>();
    final nd = context.read<NguoiDungProvider>().nguoiDung;
    final ndTv = p.getNguoiDungTuVung(widget.tu.maTu!);
    final isYeuThich = ndTv?.yeuThich ?? false;
    final isDaHoc = ndTv?.daHoc ?? false;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(context, MaterialPageRoute(builder: (_) => TuVungDetailScreen(tu: widget.tu)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.tu.tu, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                if (widget.tu.phienAm != null)
                  Text(widget.tu.phienAm!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                const SizedBox(width: 4),
                if (isDaHoc)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF00FF94).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('✓ Đã học', style: TextStyle(color: Color(0xFF00FF94), fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
              ]),
              const SizedBox(height: 4),
              if (widget.tu.nghiaVI != null)
                Text(widget.tu.nghiaVI!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.tu.nghiaEN, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Row(children: [
            GestureDetector(onTap: _speak, child: Container(padding: const EdgeInsets.all(8), child: Icon(Icons.volume_up_rounded, color: const Color(0xFF00D4FF).withOpacity(0.7), size: 18))),
            GestureDetector(
              onTap: () {
                if (nd == null) return;
                HapticFeedback.lightImpact();
                p.toggleDaHoc(nd.maND!, widget.tu.maTu!);
              },
              child: Container(padding: const EdgeInsets.all(8), child: Icon(Icons.check_circle_rounded, color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.2), size: 20)),
            ),
            GestureDetector(
              onTap: () {
                if (nd == null) return;
                HapticFeedback.lightImpact();
                p.toggleYeuThich(nd.maND!, widget.tu.maTu!);
              },
              child: Container(padding: const EdgeInsets.all(8), child: Icon(isYeuThich ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.2), size: 20)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Detail screen ─────────────────────────────────────────────────────────────
class TuVungDetailScreen extends StatefulWidget {
  final TuVung tu;
  const TuVungDetailScreen({super.key, required this.tu});
  @override
  State<TuVungDetailScreen> createState() => _TuVungDetailScreenState();
}

class _TuVungDetailScreenState extends State<TuVungDetailScreen> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late AnimationController _anim;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  @override
  void dispose() { _anim.dispose(); _tts.stop(); super.dispose(); }

  Future<void> _speak() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSpeaking = true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.65);
    await _tts.speak(widget.tu.tu);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<TuVungProvider>();
    final nd = context.read<NguoiDungProvider>().nguoiDung;
    final ndTv = p.getNguoiDungTuVung(widget.tu.maTu!);
    final isYeuThich = ndTv?.yeuThich ?? false;
    final isDaHoc = ndTv?.daHoc ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _anim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF080B1A),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (nd != null) ...[
                      IconButton(
                        icon: Icon(isDaHoc ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.4)),
                        onPressed: () { HapticFeedback.lightImpact(); p.toggleDaHoc(nd.maND!, widget.tu.maTu!); setState(() {}); },
                      ),
                      IconButton(
                        icon: Icon(isYeuThich ? Icons.favorite_rounded : Icons.favorite_outline_rounded, color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.4)),
                        onPressed: () { HapticFeedback.lightImpact(); p.toggleYeuThich(nd.maND!, widget.tu.maTu!); setState(() {}); },
                      ),
                    ],
                    const SizedBox(width: 8),
                  ],
                  pinned: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Word + pronunciation
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.tu.tu, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            if (widget.tu.phienAm != null) ...[
                              const SizedBox(height: 4),
                              Text(widget.tu.phienAm!, style: TextStyle(color: const Color(0xFF00D4FF).withOpacity(0.8), fontSize: 18)),
                            ],
                            if (widget.tu.tuLoai != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF7B2FFF).withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF7B2FFF).withOpacity(0.4))),
                                child: Text(widget.tu.tuLoai!, style: const TextStyle(color: Color(0xFF7B2FFF), fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                        ),
                        GestureDetector(
                          onTap: _isSpeaking ? null : _speak,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [const Color(0xFF00D4FF), const Color(0xFF7B2FFF)]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_isSpeaking ? 0.5 : 0.3), blurRadius: 20)],
                            ),
                            child: Icon(_isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      // Meanings
                      _DetailSection(title: '🇬🇧 Nghĩa tiếng Anh', content: widget.tu.nghiaEN, color: const Color(0xFF00D4FF)),
                      if (widget.tu.nghiaVI != null) ...[
                        const SizedBox(height: 16),
                        _DetailSection(title: '🇻🇳 Nghĩa tiếng Việt', content: widget.tu.nghiaVI!, color: const Color(0xFFFF6B35)),
                      ],
                      if (widget.tu.vdEN != null) ...[
                        const SizedBox(height: 16),
                        _DetailSection(title: '💡 Ví dụ tiếng Anh', content: widget.tu.vdEN!, color: const Color(0xFF7B2FFF), isExample: true),
                      ],
                      if (widget.tu.vdVI != null) ...[
                        const SizedBox(height: 16),
                        _DetailSection(title: '💡 Ví dụ tiếng Việt', content: widget.tu.vdVI!, color: const Color(0xFF00FF94), isExample: true),
                      ],
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title, content;
  final Color color;
  final bool isExample;
  const _DetailSection({required this.title, required this.content, required this.color, this.isExample = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(color: Colors.white.withOpacity(isExample ? 0.8 : 0.95), fontSize: 15, height: 1.5, fontStyle: isExample ? FontStyle.italic : FontStyle.normal)),
      ]),
    );
  }
}

// ─── Screen chủ đề ─────────────────────────────────────────────────────────────
class _TuVungChuDeScreen extends StatefulWidget {
  final CDTuVung chuDe;
  final Color color;
  const _TuVungChuDeScreen({required this.chuDe, required this.color});
  @override
  State<_TuVungChuDeScreen> createState() => _TuVungChuDeScreenState();
}

class _TuVungChuDeScreenState extends State<_TuVungChuDeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TuVungProvider>().layTheoChuDe(widget.chuDe.maCD!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B1A),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.color, size: 18), onPressed: () => Navigator.pop(context)),
        title: Text(widget.chuDe.tenCD, style: TextStyle(color: widget.color, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Consumer<TuVungProvider>(
        builder: (_, p, __) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
          if (p.tuTheoChuDe.isEmpty) return _EmptyState(msg: 'Chưa có từ vựng trong chủ đề này');
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: p.tuTheoChuDe.length,
            itemBuilder: (_, i) => _TuVungCard(tu: p.tuTheoChuDe[i]),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('📭', style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
    ]));
  }
}