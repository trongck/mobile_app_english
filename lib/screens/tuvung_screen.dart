import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  bool _searchFocused = false;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _searchFocus.addListener(() => setState(() => _searchFocused = _searchFocus.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TuVungProvider>();
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      p.khoiTaoDuLieu();
      if (nd != null) p.layOnTap(nd.maND!);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _headerAnim.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _search = '');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _search.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Column(children: [
        // ── Header ────────────────────────────────────────────
        AnimatedBuilder(
          animation: _headerAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, (1 - _headerAnim.value) * -20),
            child: Opacity(opacity: _headerAnim.value, child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: isSearching
                    ? const SizedBox.shrink()
                    : Row(children: [
                        const Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Từ Vựng IT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            Text('Từ điển kỹ thuật chuyên ngành', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
                          ]),
                        ),
                        Consumer<TuVungProvider>(
                          builder: (_, p, __) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                            ),
                            child: Text('${p.tatCaTuVung.length} từ', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ]),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: isSearching ? const SizedBox.shrink() : const SizedBox(height: 12),
              ),
              // ── Search bar ─────────────────────────────────
              Row(children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    decoration: BoxDecoration(
                      color: _searchFocused
                          ? Colors.white.withOpacity(0.09)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _searchFocused
                            ? const Color(0xFF00D4FF).withOpacity(0.4)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: const Color(0xFF00D4FF),
                      decoration: InputDecoration(
                        hintText: 'Tìm từ vựng (EN hoặc VI)...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: _searchFocused ? const Color(0xFF00D4FF) : Colors.white.withOpacity(0.3), size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? GestureDetector(
                                onTap: _clearSearch,
                                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                if (isSearching) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Text('Huỷ', style: TextStyle(color: const Color(0xFF00D4FF).withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ]),
          ),
        ),

        const SizedBox(height: 8),

        // ── Search results overlay ────────────────────────────
        if (isSearching)
          Expanded(child: _SearchResultsView(search: _search))
        else ...[
          // ── Tab bar ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
              tabs: const [Tab(text: '📂 Chủ đề'), Tab(text: '📖 Tất cả'), Tab(text: '⭐ Ôn tập')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ChuDeTab(),
                const _TatCaTab(),
                _OnTapTab(),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Global Search Results ────────────────────────────────────────────────────
class _SearchResultsView extends StatelessWidget {
  final String search;
  const _SearchResultsView({required this.search});

  @override
  Widget build(BuildContext context) {
    return Consumer<TuVungProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
        final q = search.toLowerCase();
        final list = p.tatCaTuVung.where((t) =>
          t.tu.toLowerCase().contains(q) ||
          (t.nghiaVI?.toLowerCase().contains(q) ?? false) ||
          t.nghiaEN.toLowerCase().contains(q)
        ).toList();

        if (list.isEmpty) return _EmptyState(msg: 'Không tìm thấy từ "$search"', icon: '🔍');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('${list.length} kết quả cho "$search"',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: list.length,
                itemBuilder: (_, i) => _TuVungCard(tu: list[i], highlight: search),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Chủ đề tab ──────────────────────────────────────────────────────────────
class _ChuDeTab extends StatelessWidget {
  static const _icons = ['💻', '🌐', '☁️', '🤖', '🔐', '🗄️', '📱', '🏗️', '🔄', '🌐'];
  static const _colors = [
    Color(0xFF00D4FF), Color(0xFF7B2FFF), Color(0xFF00FF94), Color(0xFFFF6B35),
    Color(0xFFFF3CAC), Color(0xFFFFD700), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFFFF8C00), Color(0xFF00D4FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TuVungProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
        if (p.danhSachChuDe.isEmpty) return const _EmptyState(msg: 'Chưa có chủ đề nào', icon: '📂');

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35,
          ),
          itemCount: p.danhSachChuDe.length,
          itemBuilder: (_, i) {
            final cd = p.danhSachChuDe[i];
            final idx = i % 10;
            return _ChuDeCard(chuDe: cd, color: _colors[idx], icon: _icons[idx]);
          },
        );
      },
    );
  }
}

class _ChuDeCard extends StatefulWidget {
  final CDTuVung chuDe;
  final Color color;
  final String icon;
  const _ChuDeCard({required this.chuDe, required this.color, required this.icon});
  @override
  State<_ChuDeCard> createState() => _ChuDeCardState();
}
class _ChuDeCardState extends State<_ChuDeCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => _TuVungChuDeScreen(chuDe: widget.chuDe, color: widget.color)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(widget.icon, style: const TextStyle(fontSize: 22))),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.chuDe.tenCD, style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Xem từ vựng →', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Tất cả tab ───────────────────────────────────────────────────────────────
class _TatCaTab extends StatelessWidget {
  const _TatCaTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<TuVungProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
        if (p.tatCaTuVung.isEmpty) return const _EmptyState(msg: 'Không có từ vựng nào', icon: '🔍');
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          itemCount: p.tatCaTuVung.length,
          itemBuilder: (_, i) => _TuVungCard(tu: p.tatCaTuVung[i]),
        );
      },
    );
  }
}

// ─── Ôn tập tab ──────────────────────────────────────────────────────────────
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
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          _SubTab(ctrl: _sub, idx: 0, label: 'Yêu thích', color: const Color(0xFFFF3CAC)),
          const SizedBox(width: 8),
          _SubTab(ctrl: _sub, idx: 1, label: 'Đã học', color: const Color(0xFF00FF94)),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _sub,
          children: [
            Consumer<TuVungProvider>(builder: (_, p, __) {
              if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3CAC), strokeWidth: 2));
              if (p.tuYeuThich.isEmpty) return const _EmptyState(msg: 'Bạn chưa có từ yêu thích !', icon: '❤️');
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: p.tuYeuThich.length,
                itemBuilder: (_, i) => _TuVungCard(tu: p.tuYeuThich[i]),
              );
            }),
            Consumer<TuVungProvider>(builder: (_, p, __) {
              if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF94), strokeWidth: 2));
              if (p.tuDaHoc.isEmpty) return const _EmptyState(msg: 'Bạn chưa học từ nào !', icon: '📚');
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: p.tuDaHoc.length,
                itemBuilder: (_, i) => _TuVungCard(tu: p.tuDaHoc[i]),
              );
            }),
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
        return Expanded(child: GestureDetector(
          onTap: () => ctrl.animateTo(idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
            ),
            child: Center(child: Text(label, style: TextStyle(color: active ? color : Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w700))),
          ),
        ));
      },
    );
  }
}

// ─── Từ vựng Card ─────────────────────────────────────────────────────────────
// Uses Consumer so favorite/learned state always reflects provider updates.
class _TuVungCard extends StatefulWidget {
  final TuVung tu;
  final String? highlight;
  const _TuVungCard({required this.tu, this.highlight});
  @override
  State<_TuVungCard> createState() => _TuVungCardState();
}
class _TuVungCardState extends State<_TuVungCard> {
  bool _pressed = false;
  final FlutterTts _tts = FlutterTts();

  Future<void> _speak() async {
    HapticFeedback.lightImpact();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(widget.tu.tu);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TuVungProvider, NguoiDungProvider>(
      builder: (_, p, ndProvider, __) {
        final nd = ndProvider.nguoiDung;
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
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDaHoc ? const Color(0xFF00FF94).withOpacity(0.2) : Colors.white.withOpacity(0.07)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: _HighlightText(
                    text: widget.tu.tu,
                    query: widget.highlight ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    highlightStyle: const TextStyle(color: Color(0xFF00D4FF), fontSize: 16, fontWeight: FontWeight.w800, backgroundColor: Color(0x1A00D4FF)),
                  )),
                  if (widget.tu.phienAm != null) ...[
                    const SizedBox(width: 6),
                    Flexible(child: Text(widget.tu.phienAm!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12), overflow: TextOverflow.ellipsis)),
                  ],
                  if (isDaHoc) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFF00FF94).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: const Text('✓', style: TextStyle(color: Color(0xFF00FF94), fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                if (widget.tu.nghiaVI != null)
                  _HighlightText(
                    text: widget.tu.nghiaVI!,
                    query: widget.highlight ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                    highlightStyle: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, backgroundColor: const Color(0x1A00D4FF)),
                    maxLines: 1,
                  ),
                _HighlightText(
                  text: widget.tu.nghiaEN,
                  query: widget.highlight ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  highlightStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, backgroundColor: const Color(0x1A00D4FF)),
                  maxLines: 1,
                ),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _IconBtn(icon: Icons.volume_up_rounded, color: const Color(0xFF00D4FF), size: 18, onTap: _speak),
                _IconBtn(
                  icon: isDaHoc ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                  color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.2),
                  size: 20,
                  onTap: () {
                    if (nd == null) return;
                    HapticFeedback.lightImpact();
                    p.toggleDaHoc(nd.maND!, widget.tu.maTu!);
                  },
                ),
                _IconBtn(
                  icon: isYeuThich ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.2),
                  size: 20,
                  onTap: () {
                    if (nd == null) return;
                    HapticFeedback.lightImpact();
                    p.toggleYeuThich(nd.maND!, widget.tu.maTu!);
                  },
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Highlight Text Widget ────────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int? maxLines;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: maxLines != null ? TextOverflow.ellipsis : null);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx = lower.indexOf(q);
    while (idx != -1) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx), style: style));
      spans.add(TextSpan(text: text.substring(idx, idx + q.length), style: highlightStyle));
      start = idx + q.length;
      idx = lower.indexOf(q, start);
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start), style: style));
    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: color, size: size)),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────────
// Uses Consumer2 so both "Đã học" and "Yêu thích" update reactively and save.
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
    _tts.setCompletionHandler(() { if (mounted) setState(() => _isSpeaking = false); });
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
    return Consumer2<TuVungProvider, NguoiDungProvider>(
      builder: (_, p, ndProvider, __) {
        final nd = ndProvider.nguoiDung;
        final ndTv = p.getNguoiDungTuVung(widget.tu.maTu!);
        final isYeuThich = ndTv?.yeuThich ?? false;
        final isDaHoc = ndTv?.daHoc ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF080B1A),
          body: SafeArea(
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic)),
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
                      title: Text(widget.tu.tu, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      actions: [
                        if (nd != null) ...[
                          // ── Đã học toggle ──────────────────────
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              p.toggleDaHoc(nd.maND!, widget.tu.maTu!);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDaHoc ? const Color(0xFF00FF94).withOpacity(0.15) : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDaHoc ? const Color(0xFF00FF94).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(isDaHoc ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                  color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.4), size: 15),
                                const SizedBox(width: 4),
                                Text(isDaHoc ? 'Đã học' : 'Học',
                                  style: TextStyle(color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ── Yêu thích toggle ──────────────────
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              p.toggleYeuThich(nd.maND!, widget.tu.maTu!);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isYeuThich ? const Color(0xFFFF3CAC).withOpacity(0.15) : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isYeuThich ? const Color(0xFFFF3CAC).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(isYeuThich ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.4), size: 15),
                                const SizedBox(width: 4),
                                Text(isYeuThich ? 'Yêu thích' : 'Thêm',
                                  style: TextStyle(color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                      pinned: true,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // ── Word header ──────────────────────────
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0D1535), Color(0xFF0A0E22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.2)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(widget.tu.tu, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
                                if (widget.tu.phienAm != null) ...[
                                  const SizedBox(height: 4),
                                  Text(widget.tu.phienAm!, style: TextStyle(color: const Color(0xFF00D4FF).withOpacity(0.8), fontSize: 18)),
                                ],
                                if (widget.tu.tuLoai != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B2FFF).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF7B2FFF).withOpacity(0.4)),
                                    ),
                                    child: Text(widget.tu.tuLoai!, style: const TextStyle(color: Color(0xFF7B2FFF), fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                                // ── Status badges ──────────────────
                                if (isDaHoc || isYeuThich) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    if (isDaHoc) Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00FF94).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF00FF94).withOpacity(0.3)),
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF00FF94), size: 11),
                                        SizedBox(width: 4),
                                        Text('Đã học', style: TextStyle(color: Color(0xFF00FF94), fontSize: 10, fontWeight: FontWeight.w700)),
                                      ]),
                                    ),
                                    if (isDaHoc && isYeuThich) const SizedBox(width: 6),
                                    if (isYeuThich) Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF3CAC).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFF3CAC).withOpacity(0.3)),
                                      ),
                                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.favorite_rounded, color: Color(0xFFFF3CAC), size: 11),
                                        SizedBox(width: 4),
                                        Text('Yêu thích', style: TextStyle(color: Color(0xFFFF3CAC), fontSize: 10, fontWeight: FontWeight.w700)),
                                      ]),
                                    ),
                                  ]),
                                ],
                              ])),
                              GestureDetector(
                                onTap: _isSpeaking ? null : _speak,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_isSpeaking ? 0.6 : 0.3), blurRadius: 20)],
                                  ),
                                  child: Icon(_isSpeaking ? Icons.volume_up_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                                ),
                              ),
                            ]),
                          ),

                          const SizedBox(height: 16),

                          // ── Meanings ─────────────────────────────
                          _DetailBlock('🇬🇧 Nghĩa tiếng Anh', widget.tu.nghiaEN, const Color(0xFF00D4FF)),
                          if (widget.tu.nghiaVI != null) ...[
                            const SizedBox(height: 12),
                            _DetailBlock('🇻🇳 Nghĩa tiếng Việt', widget.tu.nghiaVI!, const Color(0xFFFF6B35)),
                          ],
                          if (widget.tu.vdEN != null) ...[
                            const SizedBox(height: 12),
                            _DetailBlock('💡 Ví dụ (English)', widget.tu.vdEN!, const Color(0xFF7B2FFF), isItalic: true),
                          ],
                          if (widget.tu.vdVI != null) ...[
                            const SizedBox(height: 12),
                            _DetailBlock('💡 Ví dụ (Tiếng Việt)', widget.tu.vdVI!, const Color(0xFF00FF94), isItalic: true),
                          ],

                          const SizedBox(height: 24),

                          // ── Action Buttons ───────────────────────
                          if (nd != null) Row(children: [
                            Expanded(child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                p.toggleDaHoc(nd.maND!, widget.tu.maTu!);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDaHoc ? const Color(0xFF00FF94).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDaHoc ? const Color(0xFF00FF94).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                                ),
                                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(isDaHoc ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                    color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.5), size: 18),
                                  const SizedBox(width: 8),
                                  Text(isDaHoc ? 'Đã học' : 'Đánh dấu đã học',
                                    style: TextStyle(color: isDaHoc ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 13)),
                                ])),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                p.toggleYeuThich(nd.maND!, widget.tu.maTu!);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isYeuThich ? const Color(0xFFFF3CAC).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isYeuThich ? const Color(0xFFFF3CAC).withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                                ),
                                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(isYeuThich ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.5), size: 18),
                                  const SizedBox(width: 8),
                                  Text(isYeuThich ? 'Yêu thích' : 'Thêm yêu thích',
                                    style: TextStyle(color: isYeuThich ? const Color(0xFFFF3CAC) : Colors.white.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 13)),
                                ])),
                              ),
                            )),
                          ]),

                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String title, content;
  final Color color;
  final bool isItalic;
  const _DetailBlock(this.title, this.content, this.color, {this.isItalic = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(
          color: Colors.white.withOpacity(isItalic ? 0.75 : 0.9),
          fontSize: 15, height: 1.5,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        )),
      ]),
    );
  }
}

// ─── Chủ đề detail screen ─────────────────────────────────────────────────────
class _TuVungChuDeScreen extends StatefulWidget {
  final CDTuVung chuDe;
  final Color color;
  const _TuVungChuDeScreen({required this.chuDe, required this.color});
  @override
  State<_TuVungChuDeScreen> createState() => _TuVungChuDeScreenState();
}
class _TuVungChuDeScreenState extends State<_TuVungChuDeScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TuVungProvider>().layTheoChuDe(widget.chuDe.maCD!);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B1A),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.color, size: 18), onPressed: () => Navigator.pop(context)),
        title: Text(widget.chuDe.tenCD, style: TextStyle(color: widget.color, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          Consumer<TuVungProvider>(builder: (_, p, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${p.tuTheoChuDe.length} từ', style: TextStyle(color: widget.color.withOpacity(0.7), fontSize: 12))),
          )),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: Color(widget.color.value),
                decoration: InputDecoration(
                  hintText: 'Tìm trong chủ đề...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: widget.color.withOpacity(0.6), size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _search = ''); },
                          child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3), size: 16),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<TuVungProvider>(
        builder: (_, p, __) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2));
          var list = p.tuTheoChuDe;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            list = list.where((t) =>
              t.tu.toLowerCase().contains(q) ||
              (t.nghiaVI?.toLowerCase().contains(q) ?? false) ||
              t.nghiaEN.toLowerCase().contains(q)
            ).toList();
          }
          if (list.isEmpty) return _EmptyState(msg: _search.isNotEmpty ? 'Không tìm thấy từ "$_search"' : 'Chưa có từ vựng trong chủ đề này', icon: _search.isNotEmpty ? '🔍' : '📂');
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _TuVungCard(tu: list[i], highlight: _search.isNotEmpty ? _search : null),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String msg, icon;
  const _EmptyState({required this.msg, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14), textAlign: TextAlign.center),
    ]));
  }
}