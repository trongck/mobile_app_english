import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/nguoi_dung_provider.dart';
import '../providers/nhat_ky_provider.dart';
import '../providers/tu_vung_provider.dart';
import '../providers/bai_kt_provider.dart';
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

  String? _selectedTrinhDo;
  String? _selectedMucTieu;
  int? _selectedPhut;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nd = context.read<NguoiDungProvider>().nguoiDung;
      if (nd != null) {
        _hoTenCtrl.text = nd.hoTen ?? '';
        _selectedTrinhDo = nd.trinhDo;
        _selectedMucTieu = nd.mucTieuCapDo;
        _selectedPhut = nd.mucTieuPhut;
        context.read<NhatKyProvider>().layNhatKy7Ngay(nd.maND!);
        context.read<TuVungProvider>().layOnTap(nd.maND!);
        context.read<BaiKTProvider>().khoiTao(nd.maND);
      }
    });
  }

  @override
  void dispose() { _anim.dispose(); _hoTenCtrl.dispose(); super.dispose(); }

  Future<void> _saveProfile() async {
    final ndP = context.read<NguoiDungProvider>();
    final nd = ndP.nguoiDung;
    if (nd == null) return;
    final updated = nd.copyWith(
      hoTen: _hoTenCtrl.text.trim().isEmpty ? null : _hoTenCtrl.text.trim(),
      trinhDo: _selectedTrinhDo,
      mucTieuCapDo: _selectedMucTieu,
      mucTieuPhut: _selectedPhut,
    );
    final ok = await ndP.capNhatHoSo(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Đã lưu hồ sơ!' : 'Lưu thất bại'),
      backgroundColor: ok ? const Color.fromARGB(255, 0, 255, 149).withOpacity(1) : Colors.redAccent.withOpacity(1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
    setState(() => _editMode = false);
  }

  Future<void> _showOtpDialog(BuildContext context, NguoiDungProvider provider, NguoiDung nd) async {
    final otpController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131830), // Khớp với theme của app
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Xác thực Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vui lòng nhập mã OTP 6 số vừa được gửi đến email của bạn.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '------',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00D4FF)), borderRadius: BorderRadius.circular(12)),
                      counterText: '', // Ẩn bộ đếm ký tự
                    ),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 8),
                    Text(provider.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    provider.cancelOtpFlow();
                    Navigator.pop(context);
                  },
                  child: Text('Hủy', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isVerifying ? null : () async {
                    setState(() => isVerifying = true);
                    final success = await provider.xacMinhOtp(otpController.text);
                    setState(() => isVerifying = false);
                    
                    if (success) {
                      if (context.mounted) {
                        Navigator.pop(context); // Đóng dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Xác minh email thành công!', style: TextStyle(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF00FF94).withOpacity(0.2),
                            behavior: SnackBarBehavior.floating,
                          )
                        );
                        // Force UI refresh
                        setState(() {});
                      }
                    }
                  },
                  child: isVerifying 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080B1A))) 
                      : const Text('Xác nhận', style: TextStyle(color: Color(0xFF080B1A), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ndP = context.watch<NguoiDungProvider>();
    final nd = ndP.nguoiDung;
    if (nd == null) return const Center(child: Text('Chưa đăng nhập', style: TextStyle(color: Colors.white)));

    final nkP = context.watch<NhatKyProvider>();
    final tvP = context.watch<TuVungProvider>();
    final bktP = context.watch<BaiKTProvider>();

    final totalWords = tvP.tuDaHoc.length;
    final totalFav = tvP.tuYeuThich.length;
    final totalQuiz = bktP.lichSu.length;
    final avgScore = bktP.lichSu.isEmpty ? 0 : (bktP.lichSu.map((l) => l.diem ?? 0).fold(0, (a, b) => a + b) / bktP.lichSu.length).round();

    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  const Text('Hồ Sơ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (_editMode) {
                        _saveProfile();
                      } else {
                        setState(() => _editMode = true);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _editMode ? const LinearGradient(colors: [Color(0xFF00FF94), Color(0xFF00D4FF)]) : null,
                        color: _editMode ? null : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: _editMode ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_editMode ? Icons.check_rounded : Icons.edit_rounded,
                          color: _editMode ? const Color(0xFF080B1A) : Colors.white.withOpacity(0.7), size: 14),
                        const SizedBox(width: 6),
                        Text(_editMode ? 'Lưu' : 'Sửa',
                          style: TextStyle(
                            color: _editMode ? const Color(0xFF080B1A) : Colors.white.withOpacity(0.7),
                            fontSize: 13, fontWeight: FontWeight.w700,
                          )),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Avatar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Center(child: Column(children: [
                  Stack(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF3CAC), Color(0xFF7B2FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFFF3CAC).withOpacity(0.3), blurRadius: 24)],
                      ),
                      child: Center(child: Text(
                        (nd.hoTen?.isNotEmpty == true ? nd.hoTen![0] : nd.email[0]).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                      )),
                    ),
                    if (_editMode)
                      Positioned(bottom: 0, right: 0, child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                      )),
                  ]),
                  const SizedBox(height: 14),
                  _editMode
                    ? SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _hoTenCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          cursorColor: const Color(0xFF00D4FF),
                          decoration: InputDecoration(
                            hintText: 'Nhập họ tên...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00D4FF).withOpacity(0.5))),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D4FF))),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      )
                    : Text(nd.hoTen ?? 'Người dùng DevTalk', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(nd.email, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
                  const SizedBox(height: 6),
                  // THAY THẾ KHỐI CONAINER CŨ BẰNG ĐOẠN NÀY
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: nd.xacMinhEmail ? null : () async {
                      HapticFeedback.lightImpact();
                      final provider = context.read<NguoiDungProvider>();
                      
                      // Bật loading mờ nếu cần (tùy chọn)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang gửi mã OTP...'), duration: Duration(seconds: 1)),
                      );

                      // Gửi OTP
                      final ok = await provider.guiLaiOtp(
                        email: nd.email, 
                        userName: nd.hoTen,
                        maND: nd.maND, // Đảm bảo truyền mã ND
                      );
                      
                      if (ok && context.mounted) {
                        _showOtpDialog(context, provider, nd);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? 'Gửi OTP thất bại'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: nd.xacMinhEmail ? const Color(0xFF00FF94).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: nd.xacMinhEmail ? const Color(0xFF00FF94).withOpacity(0.4) : Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nd.xacMinhEmail ? 'Đã xác minh email' : 'Chưa xác minh (Bấm để xác nhận)',
                            style: TextStyle(
                              color: nd.xacMinhEmail ? const Color(0xFF00FF94) : Colors.orange,
                              fontSize: 11, fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!nd.xacMinhEmail) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.orange),
                          ]
                        ],
                      ),
                    ),
                  ),
                ])),
              ),
            ),

            // ── Stats Grid ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                  children: [
                    _StatCard('🔥', '${nkP.chuoiNgay}', 'Ngày streak', const Color(0xFFFF6B35)),
                    _StatCard('📚', '$totalWords', 'Từ đã học', const Color(0xFF00D4FF)),
                    _StatCard('❤️', '$totalFav', 'Từ yêu thích', const Color(0xFFFF3CAC)),
                    _StatCard('🏆', '$avgScore', 'Điểm TB Quiz', const Color(0xFFFFD700)),
                  ],
                ),
              ),
            ),

            // ── Info Cards ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Thông tin học tập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _editMode
                    ? _EditInfoSection(
                        trinhDo: _selectedTrinhDo ?? nd.trinhDo,
                        mucTieu: _selectedMucTieu ?? nd.mucTieuCapDo,
                        mucTieuPhut: _selectedPhut ?? nd.mucTieuPhut,
                        onTrinhDoChanged: (v) => setState(() => _selectedTrinhDo = v),
                        onMucTieuChanged: (v) => setState(() => _selectedMucTieu = v),
                        onPhutChanged: (v) => setState(() => _selectedPhut = v),
                      )
                    : Column(children: [
                        _InfoRow(Icons.school_rounded, 'Trình độ hiện tại', _levelLabel(nd.trinhDo), const Color(0xFF00D4FF)),
                        const SizedBox(height: 8),
                        _InfoRow(Icons.flag_rounded, 'Mục tiêu cấp độ', _levelLabel(nd.mucTieuCapDo), const Color(0xFF7B2FFF)),
                        const SizedBox(height: 8),
                        _InfoRow(Icons.timer_rounded, 'Mục tiêu mỗi ngày', '${nd.mucTieuPhut} phút', const Color(0xFFFF6B35)),
                        if (nd.hocVi != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(Icons.work_rounded, 'Lĩnh vực', _hocViLabel(nd.hocVi!), const Color(0xFF00FF94)),
                        ],
                        const SizedBox(height: 8),
                        _InfoRow(Icons.calendar_today_rounded, 'Ngày tham gia', nd.ngayTao.substring(0, 10), Colors.white.withOpacity(0.5)),
                      ]),
                ]),
              ),
            ),

            // ── 7-day chart ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nhật ký học tập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _NhatKyChart(nhatKy7Ngay: nkP.nhatKy7Ngay, goal: nd.mucTieuPhut, chuoiNgay: nkP.chuoiNgay),
                ]),
              ),
            ),

            // ── Logout ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, MediaQuery.of(context).padding.bottom + 100),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF131830),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Đăng xuất?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        content: const Text('Bạn sẽ cần đăng nhập lại.', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<NguoiDungProvider>().dangXuat();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                      }
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
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

  String _levelLabel(String v) {
    const map = {'A1': 'A1 – Mới bắt đầu', 'A2': 'A2 – Sơ cấp', 'B1': 'B1 – Trung cấp', 'B2': 'B2 – Trên trung cấp', 'C1': 'C1 – Nâng cao', 'C2': 'C2 – Thành thạo'};
    return map[v] ?? v;
  }
  String _hocViLabel(String v) {
    const map = {'developer': 'Developer / Lập trình viên', 'devops': 'DevOps / Cloud', 'ai_ml': 'AI / Machine Learning', 'designer': 'UI/UX Designer', 'student': 'Sinh viên IT', 'other': 'Khác'};
    return map[v] ?? v;
  }
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatCard(this.emoji, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ])),
      ]),
    );
  }
}

class _EditInfoSection extends StatelessWidget {
  final String trinhDo, mucTieu;
  final int mucTieuPhut;
  final ValueChanged<String> onTrinhDoChanged, onMucTieuChanged;
  final ValueChanged<int> onPhutChanged;
  const _EditInfoSection({required this.trinhDo, required this.mucTieu, required this.mucTieuPhut, required this.onTrinhDoChanged, required this.onMucTieuChanged, required this.onPhutChanged});

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _phuts = [5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _DropdownField(
        label: 'Trình độ hiện tại',
        value: trinhDo,
        items: _levels,
        color: const Color(0xFF00D4FF),
        onChanged: onTrinhDoChanged,
      ),
      const SizedBox(height: 8),
      _DropdownField(
        label: 'Mục tiêu cấp độ',
        value: mucTieu,
        items: _levels,
        color: const Color(0xFF7B2FFF),
        onChanged: onMucTieuChanged,
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mục tiêu mỗi ngày: $mucTieuPhut phút', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: _phuts.map((p) {
            final isSelected = p == mucTieuPhut;
            return GestureDetector(
              onTap: () => onPhutChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF6B35).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? const Color(0xFFFF6B35) : Colors.white.withOpacity(0.1)),
                ),
                child: Text('$p', style: TextStyle(color: isSelected ? const Color(0xFFFF6B35) : Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            );
          }).toList()),
        ]),
      ),
    ]);
  }
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final Color color;
  final ValueChanged<String> onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF131830),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          icon: Icon(Icons.expand_more_rounded, color: color),
          hint: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4))),
          items: items.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _NhatKyChart extends StatelessWidget {
  final Map<String, int> nhatKy7Ngay;
  final int goal, chuoiNgay;
  const _NhatKyChart({required this.nhatKy7Ngay, required this.goal, required this.chuoiNgay});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final totalMin = nhatKy7Ngay.values.fold(0, (a, b) => a + b);
    final daysReached = nhatKy7Ngay.values.where((v) => v >= goal).length;

    return Column(children: [
      Container(
        height: 130,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
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
                width: 28,
                height: pct > 0 ? (pct * 66).clamp(4.0, 66.0) : 4,
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
                fontSize: 9, fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
              )),
            ]);
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _NKStat('Tổng tuần', '$totalMin phút', const Color(0xFF00D4FF)),
        const SizedBox(width: 8),
        _NKStat('Đạt mục tiêu', '$daysReached/7 ngày', const Color(0xFF00FF94)),
        const SizedBox(width: 8),
        _NKStat('Streak', '$chuoiNgay ngày', const Color(0xFFFFD700)),
      ]),
    ]);
  }
}

class _NKStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NKStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9), textAlign: TextAlign.center),
      ]),
    ));
  }
}