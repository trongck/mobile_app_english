import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../providers/bai_kt_provider.dart';
import '../providers/nguoi_dung_provider.dart';
import '../models/devtalk_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnim;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      context.read<BaiKTProvider>().khoiTao(nd?.maND);
    });
  }

  @override
  void dispose() { _headerAnim.dispose(); _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        AnimatedBuilder(
          animation: _headerAnim,
          builder: (_, child) => Opacity(opacity: _headerAnim.value, child: child),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kiểm Tra', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('Luyện tập & đánh giá năng lực', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)]), borderRadius: BorderRadius.circular(10)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.4),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: '📝 Đề Thi'), Tab(text: '📊 Lịch Sử')],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [_DanhSachDeTab(), _LichSuTab()],
          ),
        ),
      ]),
    );
  }
}

// ─── Danh sách đề tab ─────────────────────────────────────────────────────────
class _DanhSachDeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BaiKTProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FFF), strokeWidth: 2));
        if (p.danhSachBaiKT.isEmpty) return _Empty(msg: 'Chưa có đề thi nào');
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: p.danhSachBaiKT.length,
          itemBuilder: (_, i) => _BaiKTCard(baiKT: p.danhSachBaiKT[i]),
        );
      },
    );
  }
}

class _BaiKTCard extends StatefulWidget {
  final BaiKT baiKT;
  const _BaiKTCard({required this.baiKT});
  @override
  State<_BaiKTCard> createState() => _BaiKTCardState();
}

class _BaiKTCardState extends State<_BaiKTCard> {
  bool _pressed = false;
  static const _gradients = [
    [Color(0xFF7B2FFF), Color(0xFF00D4FF)],
    [Color(0xFF00D4FF), Color(0xFF00FF94)],
    [Color(0xFFFF6B35), Color(0xFFFF3CAC)],
    [Color(0xFFFFD700), Color(0xFFFF8C00)],
    [Color(0xFF00FF94), Color(0xFF00D4FF)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (widget.baiKT.maBKT ?? 0) % _gradients.length;
    final grad = _gradients[idx];
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.mediumImpact();
        final nd = context.read<NguoiDungProvider>().nguoiDung;
        if (nd == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập'))); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => LamBaiScreen(baiKT: widget.baiKT, maND: nd.maND!)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [grad[0].withOpacity(0.12), grad[1].withOpacity(0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: grad[0].withOpacity(0.3)),
          boxShadow: [BoxShadow(color: grad[0].withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(gradient: LinearGradient(colors: grad), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.baiKT.tieuDe, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(children: [
                _Badge('${widget.baiKT.tongDiem} điểm', grad[0]),
                const SizedBox(width: 8),
                if (widget.baiKT.tgLamPhut != null) _Badge('${widget.baiKT.tgLamPhut} phút', grad[1]),
              ]),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, color: grad[0], size: 16),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Lịch sử tab ──────────────────────────────────────────────────────────────
class _LichSuTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BaiKTProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FFF), strokeWidth: 2));
        if (p.lichSu.isEmpty) return _Empty(msg: 'Chưa có lịch sử làm bài');
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: p.lichSu.length,
          itemBuilder: (_, i) => _LichSuCard(ls: p.lichSu[i], provider: p),
        );
      },
    );
  }
}

class _LichSuCard extends StatefulWidget {
  final LSKiemTra ls;
  final BaiKTProvider provider;
  const _LichSuCard({required this.ls, required this.provider});
  @override
  State<_LichSuCard> createState() => _LichSuCardState();
}

class _LichSuCardState extends State<_LichSuCard> {
  bool _pressed = false;

  String get _diem {
    if (widget.ls.diem == null) return 'Chưa nộp';
    return '${widget.ls.diem} điểm';
  }

  Color get _diemColor {
    final d = widget.ls.diem ?? 0;
    if (d >= 80) return const Color(0xFF00FF94);
    if (d >= 50) return const Color(0xFFFFD700);
    return const Color(0xFFFF3CAC);
  }

  @override
  Widget build(BuildContext context) {
    final baiKT = widget.provider.getBaiKT(widget.ls.maBKT);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => XemLaiScreen(ls: widget.ls, provider: widget.provider)));
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _diemColor.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: _diemColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(widget.ls.diem != null ? '${widget.ls.diem}' : '?', style: TextStyle(color: _diemColor, fontSize: 16, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(baiKT?.tieuDe ?? 'Bài kiểm tra #${widget.ls.maBKT}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Text(_diem, style: TextStyle(color: _diemColor, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(' · ', style: TextStyle(color: Colors.white.withOpacity(0.3))),
              Text(widget.ls.tgBatDau.substring(0, 10), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              if (widget.ls.tgLam != null) ...[
                Text(' · ', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                Text('${widget.ls.tgLam}s', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ]),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 20),
        ]),
      ),
    );
  }
}

// ─── Làm bài screen ────────────────────────────────────────────────────────────
class LamBaiScreen extends StatefulWidget {
  final BaiKT baiKT;
  final int maND;
  const LamBaiScreen({super.key, required this.baiKT, required this.maND});
  @override
  State<LamBaiScreen> createState() => _LamBaiScreenState();
}

class _LamBaiScreenState extends State<LamBaiScreen> with TickerProviderStateMixin {
  List<CauHoiKT> _cauHoi = [];
  Map<int, String> _dapAn = {};
  int _currentIdx = 0;
  Timer? _timer;
  int _tgConLai = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  late AnimationController _slideAnim;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _slideAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _loadCauHoi();
  }

  Future<void> _loadCauHoi() async {
    try {
      final p = context.read<BaiKTProvider>();
      _cauHoi = await p.layCauHoi(widget.baiKT.maBKT!);
      _tgConLai = (widget.baiKT.tgLamPhut ?? 30) * 60;
      _startTimer();
    } catch (e) {
      debugPrint('Load câu hỏi error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    _slideAnim.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_tgConLai > 0) {
          _tgConLai--;
        } else {
          t.cancel();
          _submit(autoSubmit: true);
        }
      });
    });
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final p = context.read<BaiKTProvider>();
    final totalSec = (widget.baiKT.tgLamPhut ?? 30) * 60 - _tgConLai;

    // Tính điểm
    int tongDiem = 0;
    int maxDiem = 0;
    for (final ch in _cauHoi) {
      maxDiem += ch.trongSo;
      final answer = _dapAn[ch.maCH];
      if (answer != null && answer.trim().toLowerCase() == ch.dapAn.trim().toLowerCase()) {
        tongDiem += ch.trongSo;
      }
    }
    final pct = maxDiem > 0 ? (tongDiem / maxDiem * widget.baiKT.tongDiem).round() : 0;

    final ls = LSKiemTra(
      maND: widget.maND,
      maBKT: widget.baiKT.maBKT!,
      cauTraLoi: _dapAn.map((k, v) => MapEntry(k.toString(), v)),
      diem: pct,
      tgLam: totalSec,
    );

    await p.luuKetQua(ls);

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => KetQuaScreen(ls: ls, cauHoi: _cauHoi, tongDiem: widget.baiKT.tongDiem, autoSubmit: autoSubmit),
      ));
    }
  }

  void _nextQuestion() async {
    if (_currentIdx < _cauHoi.length - 1) {
      await _slideAnim.reverse();
      setState(() => _currentIdx++);
      _textCtrl.text = _dapAn[_cauHoi[_currentIdx].maCH] ?? '';
      _slideAnim.forward();
    }
  }

  void _prevQuestion() async {
    if (_currentIdx > 0) {
      await _slideAnim.reverse();
      setState(() => _currentIdx--);
      _textCtrl.text = _dapAn[_cauHoi[_currentIdx].maCH] ?? '';
      _slideAnim.forward();
    }
  }

  String get _timerStr {
    final m = _tgConLai ~/ 60;
    final s = _tgConLai % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_tgConLai > 300) return const Color(0xFF00FF94);
    if (_tgConLai > 60) return const Color(0xFFFFD700);
    return const Color(0xFFFF3CAC);
  }

  @override
  void dispose() { _timer?.cancel(); _slideAnim.dispose(); _textCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(backgroundColor: const Color(0xFF080B1A), body: const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FFF), strokeWidth: 2)));
    if (_cauHoi.isEmpty) return Scaffold(backgroundColor: const Color(0xFF080B1A), appBar: AppBar(backgroundColor: const Color(0xFF080B1A), leading: const BackButton(color: Colors.white)), body: const Center(child: Text('Không có câu hỏi', style: TextStyle(color: Colors.white))));

    final ch = _cauHoi[_currentIdx];
    final answered = _dapAn.keys.length;

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF131830),
                  title: const Text('Thoát?', style: TextStyle(color: Colors.white)),
                  content: const Text('Bài làm sẽ không được lưu.', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                    TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Thoát', style: TextStyle(color: Colors.redAccent))),
                  ],
                )),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.baiKT.tieuDe, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text('$answered/${_cauHoi.length} câu đã trả lời', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _timerColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: _timerColor.withOpacity(0.4))),
                child: Text(_timerStr, style: TextStyle(color: _timerColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ]),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIdx + 1) / _cauHoi.length,
                minHeight: 4,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B2FFF)),
              ),
            ),
          ),
          // Question
          Expanded(
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(CurvedAnimation(parent: _slideAnim, curve: Curves.easeOut)),
              child: FadeTransition(
                opacity: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Câu ${_currentIdx + 1}/${_cauHoi.length}', style: TextStyle(color: const Color(0xFF7B2FFF), fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Text(ch.noiDung, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    _buildAnswerWidget(ch),
                  ]),
                ),
              ),
            ),
          ),
          // Navigation
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Row(children: [
              if (_currentIdx > 0)
                Expanded(child: GestureDetector(
                  onTap: _prevQuestion,
                  child: Container(height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18), SizedBox(width: 6), Text('Trước', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))])),
                  ),
                )),
              if (_currentIdx > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _currentIdx < _cauHoi.length - 1 ? _nextQuestion : () => _submit(),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF7B2FFF).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                    child: Center(child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(_currentIdx < _cauHoi.length - 1 ? 'Tiếp theo' : 'Nộp bài', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Icon(_currentIdx < _cauHoi.length - 1 ? Icons.arrow_forward_rounded : Icons.check_rounded, color: Colors.white, size: 18),
                        ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildAnswerWidget(CauHoiKT ch) {
    switch (ch.loai) {
      case 'tracnghiem':
        final opts = ch.luaChon ?? [];
        return Column(children: opts.map((o) {
          final ky = o['ky_hieu']?.toString() ?? '';
          final nd = o['noi_dung']?.toString() ?? '';
          final sel = _dapAn[ch.maCH] == ky;
          return GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); setState(() { _dapAn[ch.maCH!] = ky; }); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: [Color(0xFF7B2FFF), Color(0xFF00D4FF)]) : null,
                color: sel ? null : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.09)),
                boxShadow: sel ? [BoxShadow(color: const Color(0xFF7B2FFF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: sel ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                  child: Center(child: Text(ky, style: TextStyle(color: sel ? Colors.white : Colors.white.withOpacity(0.7), fontWeight: FontWeight.w800, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(nd, style: TextStyle(color: sel ? Colors.white : Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4))),
              ]),
            ),
          );
        }).toList());

      case 'dung_sai':
        return Column(children: [
          _DungSaiBtn(label: 'Đúng', value: 'Đúng', selected: _dapAn[ch.maCH], color: const Color(0xFF00FF94), onTap: () => setState(() => _dapAn[ch.maCH!] = 'Đúng')),
          const SizedBox(height: 10),
          _DungSaiBtn(label: 'Sai', value: 'Sai', selected: _dapAn[ch.maCH], color: const Color(0xFFFF3CAC), onTap: () => setState(() => _dapAn[ch.maCH!] = 'Sai')),
        ]);

      case 'dien_khuyet':
      default:
        return Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: TextField(
            controller: _textCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: const Color(0xFF7B2FFF),
            onChanged: (v) => _dapAn[ch.maCH!] = v,
            decoration: InputDecoration(
              hintText: 'Nhập câu trả lời của bạn...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        );
    }
  }
}

class _DungSaiBtn extends StatelessWidget {
  final String label, value;
  final String? selected;
  final Color color;
  final VoidCallback onTap;
  const _DungSaiBtn({required this.label, required this.value, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color : Colors.white.withOpacity(0.09)),
        ),
        child: Center(child: Text(label, style: TextStyle(color: sel ? color : Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 15))),
      ),
    );
  }
}

// ─── Kết quả screen ────────────────────────────────────────────────────────────
class KetQuaScreen extends StatefulWidget {
  final LSKiemTra ls;
  final List<CauHoiKT> cauHoi;
  final int tongDiem;
  final bool autoSubmit;
  const KetQuaScreen({super.key, required this.ls, required this.cauHoi, required this.tongDiem, required this.autoSubmit});
  @override
  State<KetQuaScreen> createState() => _KetQuaScreenState();
}

class _KetQuaScreenState extends State<KetQuaScreen> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() { super.initState(); _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward(); }
  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Color get _scoreColor {
    final d = widget.ls.diem ?? 0;
    if (d >= 80) return const Color(0xFF00FF94);
    if (d >= 50) return const Color(0xFFFFD700);
    return const Color(0xFFFF3CAC);
  }

  String get _scoreEmoji {
    final d = widget.ls.diem ?? 0;
    if (d >= 80) return '🎉';
    if (d >= 50) return '👍';
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _anim,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.home_rounded, color: Colors.white70, size: 20)),
                ),
                const Spacer(),
                const Text('Kết quả', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                const SizedBox(width: 44),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const SizedBox(height: 20),
                  Text(_scoreEmoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text('${widget.ls.diem ?? 0}/${widget.tongDiem}', style: TextStyle(color: _scoreColor, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2)),
                  const SizedBox(height: 8),
                  Text(widget.autoSubmit ? '⏰ Hết giờ - tự động nộp bài' : 'Hoàn thành!', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(child: _StatCard('Thời gian', '${((widget.ls.tgLam ?? 0) / 60).toStringAsFixed(1)} phút', const Color(0xFF00D4FF))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard('Đã trả lời', '${widget.ls.cauTraLoi.length}/${widget.cauHoi.length}', const Color(0xFF7B2FFF))),
                  ]),
                  const SizedBox(height: 28),
                  const Align(alignment: Alignment.centerLeft, child: Text('Chi tiết câu hỏi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                  const SizedBox(height: 12),
                  ...widget.cauHoi.asMap().entries.map((e) => _CauHoiKetQua(idx: e.key, ch: e.value, dapAnUser: widget.ls.cauTraLoi[e.value.maCH.toString()])),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ]),
    );
  }
}

class _CauHoiKetQua extends StatelessWidget {
  final int idx;
  final CauHoiKT ch;
  final String? dapAnUser;
  const _CauHoiKetQua({required this.idx, required this.ch, required this.dapAnUser});

  bool get _correct => dapAnUser?.trim().toLowerCase() == ch.dapAn.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final color = _correct ? const Color(0xFF00FF94) : const Color(0xFFFF3CAC);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Câu ${idx + 1}: ${ch.noiDung}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
        if (!_correct) ...[
          const SizedBox(height: 8),
          Text('Bạn chọn: ${dapAnUser ?? 'Chưa trả lời'}', style: TextStyle(color: const Color(0xFFFF3CAC).withOpacity(0.8), fontSize: 12)),
          Text('Đáp án đúng: ${ch.dapAn}', style: const TextStyle(color: Color(0xFF00FF94), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
        if (ch.giaiThich != null) ...[
          const SizedBox(height: 6),
          Text('💡 ${ch.giaiThich}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }
}

// ─── Xem lại screen ────────────────────────────────────────────────────────────
class XemLaiScreen extends StatelessWidget {
  final LSKiemTra ls;
  final BaiKTProvider provider;
  const XemLaiScreen({super.key, required this.ls, required this.provider});

  @override
  Widget build(BuildContext context) {
    final baiKT = provider.getBaiKT(ls.maBKT);
    final cauHoi = provider.getCauHoi(ls.maBKT);
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B1A),
        leading: const BackButton(color: Colors.white),
        title: Text(baiKT?.tieuDe ?? 'Xem lại', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: cauHoi.length,
        itemBuilder: (_, i) => _CauHoiKetQua(idx: i, ch: cauHoi[i], dapAnUser: ls.cauTraLoi[cauHoi[i].maCH.toString()]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📭', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
    ]));
  }
}