import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/nguoi_dung_provider.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  final String trinhDo;
  final String mucTieuCapDo;
  final String? hocVi;
  final int mucTieuPhut;

  const AuthScreen({
    super.key,
    required this.trinhDo,
    required this.mucTieuCapDo,
    this.hocVi,
    required this.mucTieuPhut,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = false;
  bool _showEmailForm = false;
  bool _obscurePwd = true;

  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _bgAnim;
  late AnimationController _entryAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _entryAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _entryFade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _entryAnim.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
      (_) => false,
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.redAccent : const Color(0xFF00FF94), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: const Color(0xFF131830),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _loginGoogle() async {
    HapticFeedback.mediumImpact();
    final p = context.read<NguoiDungProvider>();
    final ok = await p.dangNhapGoogle(
      trinhDo: widget.trinhDo, mucTieuCapDo: widget.mucTieuCapDo,
      hocVi: widget.hocVi, mucTieuPhut: widget.mucTieuPhut,
    );
    if (!mounted) return;
    if (ok) { _showToast('Xin chào ${p.nguoiDung?.hoTen ?? ''}!'); await Future.delayed(const Duration(milliseconds: 500)); _navigateToMain(); }
    else { _showToast(p.error ?? 'Đăng nhập Google thất bại', isError: true); p.clearError(); }
  }

  Future<void> _loginFacebook() async {
    HapticFeedback.mediumImpact();
    final p = context.read<NguoiDungProvider>();
    final ok = await p.dangNhapFacebook(
      trinhDo: widget.trinhDo, mucTieuCapDo: widget.mucTieuCapDo,
      hocVi: widget.hocVi, mucTieuPhut: widget.mucTieuPhut,
    );
    if (!mounted) return;
    if (ok) { _showToast('Xin chào ${p.nguoiDung?.hoTen ?? ''}!'); await Future.delayed(const Duration(milliseconds: 500)); _navigateToMain(); }
    else { _showToast(p.error ?? 'Đăng nhập Facebook thất bại', isError: true); p.clearError(); }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    final p = context.read<NguoiDungProvider>();

    if (_isLogin) {
      // ── ĐĂNG NHẬP ──────────────────────────────────────────────
      final ok = await p.dangNhapEmail(_emailCtrl.text.trim(), _pwdCtrl.text);
      if (!mounted) return;
      if (ok) {
        _showToast('Đăng nhập thành công!');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToMain();
      } else {
        _showToast(p.error ?? 'Có lỗi xảy ra', isError: true);
        p.clearError();
      }
    } else {
      // ── ĐĂNG KÝ ────────────────────────────────────────────────
      final id = await p.dangKyEmail(
        email: _emailCtrl.text.trim(),
        matKhau: _pwdCtrl.text,
        hoTen: _nameCtrl.text.trim(),
        trinhDo: widget.trinhDo,
        mucTieuCapDo: widget.mucTieuCapDo,
        hocVi: widget.hocVi,
        mucTieuPhut: widget.mucTieuPhut,
      );
      if (!mounted) return;

      if (id == 1) {
        // Tài khoản tạo thành công → hiện dialog OTP
        _showToast('Mã OTP đã gửi đến ${_emailCtrl.text.trim()}');
        await _showOtpDialog(p);
        // Sau khi dialog đóng: nếu đã xác minh thì _nguoiDung != null
        if (!mounted) return;
        if (p.daDangNhap) {
          _navigateToMain();
        }
      } else if (id == -1) {
        _showToast(p.error ?? 'Email đã được sử dụng', isError: true);
        p.clearError();
      } else {
        _showToast(p.error ?? 'Có lỗi xảy ra', isError: true);
        p.clearError();
      }
    }
  }

  Future<void> _showOtpDialog(NguoiDungProvider provider) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpDialog(
        provider: provider,
        email: _emailCtrl.text.trim(),
        userName: _nameCtrl.text.trim(),
      ),
    );
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    _entryAnim.reset();
    setState(() { _isLogin = !_isLogin; _showEmailForm = false; });
    _entryAnim.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = context.watch<NguoiDungProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        AnimatedBuilder(animation: _bgAnim, builder: (_, __) => CustomPaint(size: size, painter: _BgPainter(_bgAnim.value))),
        CustomPaint(size: size, painter: _GridPainter()),

        SafeArea(
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 32),
                  // Logo
                  Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color.fromARGB(255, 58, 183, 199)]), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 16)]),
                      child:  Center(child: Image.asset(
                          'assets/icon/logo.png', // đường dẫn ảnh của bạn
                          width: 35, height: 35,
                          fit: BoxFit.fill,
                        ),)),
                    const SizedBox(width: 12),
                    const Text('DevTalk English', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 44),
                  Text(_isLogin ? 'Chào mừng\ntrở lại!' : 'Tạo tài khoản\ncủa bạn ',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(_isLogin ? 'Tiếp tục hành trình học tiếng Anh IT' : 'Chinh phục tiếng Anh IT ngay hôm nay',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
                  const SizedBox(height: 40),

                  if (!_showEmailForm) ...[
                    _SocialBtn(
                      child: Row(children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color.fromARGB(255, 255, 255, 255), shape: BoxShape.circle),
                          child:  Center(child:Center(child: Image.asset(
                          'assets/icon/logo_gg.jpg', // đường dẫn ảnh của bạn
                       
                          width: 20, height: 20,
                          fit: BoxFit.fill,
                        ),))),
                        const SizedBox(width: 16),
                        Text(_isLogin ? 'Tiếp tục với Google' : 'Đăng ký với Google',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                      glowColor: const Color(0xFFEA4335),
                      onTap: isLoading ? null : _loginGoogle,
                    ),
                    const SizedBox(height: 12),
                    _SocialBtn(
                      child: Row(children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
                          child: const Center(child: Text('f', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)))),
                        const SizedBox(width: 16),
                        Text(_isLogin ? 'Tiếp tục với Facebook' : 'Đăng ký với Facebook',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                      glowColor: const Color(0xFF1877F2),
                      onTap: isLoading ? null : _loginFacebook,
                    ),
                    const SizedBox(height: 12),
                    _SocialBtn(
                      child: Row(children: [
                        Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFF00D4FF), shape: BoxShape.circle),
                          child: const Icon(Icons.email_rounded, color: Colors.white, size: 15)),
                        const SizedBox(width: 16),
                        Text(_isLogin ? 'Đăng nhập bằng Email' : 'Đăng ký bằng Email',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                      glowColor: const Color(0xFF00D4FF),
                      onTap: isLoading ? null : () { setState(() => _showEmailForm = true); _entryAnim.reset(); _entryAnim.forward(); },
                    ),
                    const SizedBox(height: 40),
                    _Divider(text: _isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'),
                    const SizedBox(height: 20),
                    Center(child: GestureDetector(
                      onTap: isLoading ? null : _toggleMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Text(_isLogin ? 'Tạo tài khoản mới' : 'Đăng nhập',
                          style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    )),
                  ] else ...[
                    Form(key: _formKey, child: Column(children: [
                      if (!_isLogin) ...[
                        _Field(ctrl: _nameCtrl, label: 'Họ và tên (tuỳ chọn)', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                      ],
                      _Field(ctrl: _emailCtrl, label: 'Email', icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) { if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email không hợp lệ'; return null; }),
                      const SizedBox(height: 14),
                      _Field(ctrl: _pwdCtrl, label: 'Mật khẩu', icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePwd,
                        suffix: IconButton(
                          icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white38, size: 20),
                          onPressed: () => setState(() => _obscurePwd = !_obscurePwd)),
                        validator: (v) { if (v == null || v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự'; return null; }),
                    ])),
                    const SizedBox(height: 28),
                    _GradBtn(label: _isLogin ? 'Đăng nhập' : 'Tạo tài khoản', onTap: isLoading ? null : _submitEmail),
                    const SizedBox(height: 16),
                    Center(child: GestureDetector(
                      onTap: () { setState(() => _showEmailForm = false); _entryAnim.reset(); _entryAnim.forward(); },
                      child: Text('← Quay lại', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                    )),
                  ],
                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ),
        ),

        // Loading overlay
        if (isLoading)
          Container(color: Colors.black54,
            child: Center(child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: const Color(0xFF0D1128), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _Spinner(color: const Color(0xFF00D4FF)),
                const SizedBox(height: 16),
                Text('Đang xử lý...', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ]),
            )),
          ),
      ]),
    );
  }
}

// ─── OTP Dialog ──────────────────────────────────────────────────────────────

class _OtpDialog extends StatefulWidget {
  final NguoiDungProvider provider;
  final String email;
  final String userName;
  const _OtpDialog({required this.provider, required this.email, required this.userName});

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (_, __) {
        final isLoading = widget.provider.isLoading;
        final error = widget.provider.error;

        return AlertDialog(
          backgroundColor: const Color(0xFF131830),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Xác thực Email',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Nhập mã OTP 6 số được gửi đến\n${widget.email}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 8,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ]),
          ),
          actions: [
            // Bỏ qua → đăng nhập luôn dù chưa xác minh email
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Load user vào provider và đăng nhập
                      await widget.provider.dangNhapSauDangKy();
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text('Bỏ qua', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
            // Gửi lại
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      await widget.provider.guiLaiOtp(
                        email: widget.email,
                        userName: widget.userName,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(widget.provider.error == null
                              ? '📧 Đã gửi lại OTP!'
                              : 'Gửi thất bại'),
                          backgroundColor: const Color(0xFF131830),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
              child: const Text('Gửi lại', style: TextStyle(color: Color(0xFF00D4FF))),
            ),
            // Xác nhận
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      final success =
                          await widget.provider.xacMinhOtp(_otpCtrl.text.trim());
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF080B1A)))
                  : const Text('Xác nhận',
                      style: TextStyle(
                          color: Color(0xFF080B1A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SocialBtn extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final VoidCallback? onTap;
  const _SocialBtn({required this.child, required this.glowColor, this.onTap});
  @override State<_SocialBtn> createState() => _SocialBtnState();
}
class _SocialBtnState extends State<_SocialBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) { setState(() => _p = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        transform: Matrix4.identity()..scale(_p ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        height: 54, padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _p ? widget.glowColor.withOpacity(0.1) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _p ? widget.glowColor.withOpacity(0.5) : Colors.white.withOpacity(0.09)),
          boxShadow: _p ? [BoxShadow(color: widget.glowColor.withOpacity(0.18), blurRadius: 16)] : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.label, required this.icon,
    this.keyboardType, this.obscureText = false, this.suffix, this.validator});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType, obscureText: obscureText,
      validator: validator, style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF00D4FF),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20), suffixIcon: suffix,
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: _border(), enabledBorder: _border(),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
  OutlineInputBorder _border() => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.09)));
}

class _GradBtn extends StatefulWidget {
  final String label; final VoidCallback? onTap;
  const _GradBtn({required this.label, this.onTap});
  @override State<_GradBtn> createState() => _GradBtnState();
}
class _GradBtnState extends State<_GradBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) { setState(() => _p = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedContainer(duration: const Duration(milliseconds: 110),
        transform: Matrix4.identity()..scale(_p ? 0.97 : 1.0), transformAlignment: Alignment.center,
        height: 56, decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(_p ? 0.2 : 0.32), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Center(child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String text;
  const _Divider({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.07))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13))),
      Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.07))),
    ]);
  }
}

class _Spinner extends StatefulWidget {
  final Color color;
  const _Spinner({required this.color});
  @override State<_Spinner> createState() => _SpinnerState();
}
class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (_, __) => Transform.rotate(angle: _c.value * math.pi * 2,
      child: CustomPaint(size: const Size(40, 40), painter: _RingP(widget.color))));
  }
}
class _RingP extends CustomPainter {
  final Color c;
  _RingP(this.c);
  @override void paint(Canvas canvas, Size size) {
    canvas.drawArc(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), 0, math.pi * 1.75, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round
        ..shader = SweepGradient(colors: [c, c.withOpacity(0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }
  @override bool shouldRepaint(_) => false;
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.screen;
    for (final o in [[0.85, 0.12, 0.45, const Color(0xFF7B2FFF), 0.8], [0.15, 0.65, 0.4, const Color(0xFF00D4FF), 1.1], [0.6, 0.9, 0.3, const Color(0xFF0047FF), 0.6]]) {
      final x = (o[0] as double) + math.sin(t * math.pi * 2 * (o[4] as double)) * 0.1;
      final y = (o[1] as double) + math.cos(t * math.pi * 2 * (o[4] as double)) * 0.08;
      p.shader = RadialGradient(colors: [(o[3] as Color).withOpacity(0.18), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(x * size.width, y * size.height), radius: (o[2] as double) * size.width));
      canvas.drawCircle(Offset(x * size.width, y * size.height), (o[2] as double) * size.width, p);
    }
  }
  @override bool shouldRepaint(_BgPainter o) => o.t != t;
}

class _GridPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}