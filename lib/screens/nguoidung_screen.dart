import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nguoi_dung_provider.dart';
import '../providers/nhat_ky_provider.dart';
import '../models/devtalk_model.dart';

class NguoiDungScreen extends StatefulWidget {
  const NguoiDungScreen({super.key});
  @override
  State<NguoiDungScreen> createState() => _NguoiDungScreenState();
}

class _NguoiDungScreenState extends State<NguoiDungScreen> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _editMode = false;
  final _hoTenCtrl = TextEditingController();
  final _trinhDoCtrl = TextEditingController();
  final _mucTieuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      final nkP = context.read<NhatKyProvider>();
      if (nd != null) {
        _hoTenCtrl.text = nd.hoTen ?? '';
        nkP.layNhatKy7Ngay(nd.maND!);
      }
    });
  }

  @override
  void dispose() { _anim.dispose(); _hoTenCtrl.dispose(); _trinhDoCtrl.dispose(); _mucTieuCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ndP = context.watch<NguoiDungProvider>();
    final nd = ndP.nguoiDung;
    if (nd == null) return const Center(child: Text('Chưa đăng nhập', style: TextStyle(color: Colors.white)));

    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  const Text('Hồ Sơ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_editMode) _saveProfile(nd, ndP);
                      setState(() => _editMode = !_editMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _editMode ? const Color(0xFF00FF94).withOpacity(0.15) : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _editMode ? const Color(0xFF00FF94).withOpacity(0.4) : Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(_editMode ? 'Lưu' : 'Chỉnh sửa', style: TextStyle(color: _editMode ? const Color(0xFF00FF94) : Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ),

            // Avatar + name
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Center(child: Column(children: [
                  Stack(children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF3CAC), Color(0xFF7B2FFF)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFFF3CAC).withOpacity(0.35), blurRadius: 24)],
                      ),
                      child: Center(child: Text(
                        (nd.hoTen?.isNotEmpty == true ? nd.hoTen![0].toUpperCase() : nd.email[0].toUpperCase()),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      )),
                    ),
                    if (_editMode)
                      Positioned(bottom: 0, right: 0, child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      )),
                  ]),
                  const SizedBox(height: 14),
                  _editMode
                    ? SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _hoTenCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          cursorColor: const Color(0xFF00D4FF),
                          decoration: InputDecoration(
                            hintText: 'Họ và tên',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.5))),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D4FF))),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      )
                    : Text(nd.hoTen ?? 'Người dùng', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(nd.email, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                ])),
              ),
            ),

            // Info cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(children: [
                  _InfoCard(label: 'Trình độ hiện tại', value: _trinhDoLabel(nd.trinhDo), icon: Icons.school_rounded, color: const Color(0xFF00D4FF),
                    trailing: _editMode ? _LevelPicker(current: nd.trinhDo, onChanged: (v) { setState(() {}); }) : null),
                  const SizedBox(height: 10),
                  _InfoCard(label: 'Mục tiêu cấp độ', value: _trinhDoLabel(nd.mucTieuCapDo), icon: Icons.flag_rounded, color: const Color(0xFF7B2FFF)),
                  const SizedBox(height: 10),
                  _InfoCard(label: 'Mục tiêu mỗi ngày', value: '${nd.mucTieuPhut} phút', icon: Icons.timer_rounded, color: const Color(0xFFFF6B35)),
                  if (nd.hocVi != null) ...[
                    const SizedBox(height: 10),
                    _InfoCard(label: 'Lĩnh vực', value: _hocViLabel(nd.hocVi!), icon: Icons.work_rounded, color: const Color(0xFF00FF94)),
                  ],
                ]),
              ),
            ),

            // Nhật ký học tập
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: const Text('Nhật ký 7 ngày gần nhất', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
            SliverToBoxAdapter(child: _NhatKyChart()),

            // Logout
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, MediaQuery.of(context).padding.bottom + 100),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF131830),
                      title: const Text('Đăng xuất?', style: TextStyle(color: Colors.white)),
                      content: const Text('Bạn sẽ cần đăng nhập lại.', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ));
                    if (confirm == true && context.mounted) {
                      await context.read<NguoiDungProvider>().dangXuat();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 15)),
                    ])),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile(NguoiDung nd, NguoiDungProvider p) async {
    final updated = nd.copyWith(hoTen: _hoTenCtrl.text.trim().isEmpty ? null : _hoTenCtrl.text.trim());
    await p.capNhatHoSo(updated);
  }

  String _trinhDoLabel(String v) {
    const map = {'A1': 'A1 – Mới bắt đầu', 'A2': 'A2 – Sơ cấp', 'B1': 'B1 – Trung cấp', 'B2': 'B2 – Trên trung cấp', 'C1': 'C1 – Nâng cao', 'C2': 'C2 – Thành thạo'};
    return map[v] ?? v;
  }

  String _hocViLabel(String v) {
    const map = {'developer': 'Developer / Lập trình viên', 'devops': 'DevOps / Cloud', 'ai_ml': 'AI / Machine Learning', 'designer': 'UI/UX Designer', 'student': 'Sinh viên IT', 'other': 'Khác'};
    return map[v] ?? v;
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  const _InfoCard({required this.label, required this.value, required this.icon, required this.color, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LevelPicker({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, backgroundColor: const Color(0xFF131830), builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((l) => ListTile(
            title: Text(l, style: const TextStyle(color: Colors.white)),
            trailing: current == l ? const Icon(Icons.check_rounded, color: Color(0xFF00D4FF)) : null,
            onTap: () { onChanged(l); Navigator.pop(context); },
          )).toList(),
        ));
      },
      child: Icon(Icons.edit_rounded, color: const Color(0xFF00D4FF).withOpacity(0.7), size: 18),
    );
  }
}

// ─── Nhật ký chart ─────────────────────────────────────────────────────────────
class _NhatKyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NhatKyProvider>(
      builder: (_, p, __) {
        if (p.isLoading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2)));
        
        final data = p.nhatKy7Ngay;
        final now = DateTime.now();
        final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            // Bar chart
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days.asMap().entries.map((e) {
                  final day = e.value;
                  final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final phut = data[key] ?? 0;
                  final nd = context.read<NguoiDungProvider>().nguoiDung;
                  final goal = nd?.mucTieuPhut ?? 15;
                  final pct = goal > 0 ? (phut / goal).clamp(0.0, 1.0) : 0.0;
                  final isToday = day.day == now.day && day.month == now.month;
                  final color = pct >= 1.0 ? const Color(0xFF00FF94) : pct > 0.5 ? const Color(0xFFFFD700) : const Color(0xFF00D4FF);
                  return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (phut > 0) Text('${phut}m', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 28,
                      height: (pct * 60).clamp(4.0, 60.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(6),
                        border: isToday ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_dayLabel(day), style: TextStyle(color: isToday ? Colors.white : Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Summary
            Row(children: [
              _NhatKyStat('Tổng tuần', '${data.values.fold(0, (a, b) => a + b)} phút', const Color(0xFF00D4FF)),
              const SizedBox(width: 10),
              _NhatKyStat('Ngày đạt goal', '${data.values.where((v) { final nd = context.read<NguoiDungProvider>().nguoiDung; return v >= (nd?.mucTieuPhut ?? 15); }).length}/7', const Color(0xFF00FF94)),
              const SizedBox(width: 10),
              _NhatKyStat('Chuỗi ngày', '${p.chuoiNgay} ngày', const Color(0xFFFFD700)),
            ]),
          ]),
        );
      },
    );
  }

  String _dayLabel(DateTime d) {
    const short = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return short[d.weekday % 7];
  }
}

class _NhatKyStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NhatKyStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10), textAlign: TextAlign.center),
      ]),
    ));
  }
}