import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datas/repositories/nguoi_dung_repository.dart';
import '../models/devtalk_model.dart';
import '../providers/xac_thuc_provider.dart';

const String _kSessionKey = 'devtalk_logged_in_user_id';
const String _kAuthProvider = 'devtalk_auth_provider';

class NguoiDungProvider extends ChangeNotifier {
  final NguoiDungRepository _repo = NguoiDungRepository();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  NguoiDung? _nguoiDung;
  bool _isLoading = false;
  String? _error;
  String? _authProvider;

  // ── OTP state ─────────────────────────────────────────────────────────────
  String? _pendingOtp;
  DateTime? _otpExpiry;
  int? _pendingMaND;    // ID người dùng vừa đăng ký, chờ xác minh
  String? _pendingEmail; // Email tương ứng — fallback khi _pendingMaND bị null

  NguoiDung? get nguoiDung => _nguoiDung;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get daDangNhap => _nguoiDung != null;
  String? get authProvider => _authProvider;
  bool get hasOtpPending => _pendingOtp != null && _pendingMaND != null;

  // ─── Session persistence ─────────────────────────────────────────────────

  Future<bool> khoiPhucSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(_kSessionKey);
      final savedProvider = prefs.getString(_kAuthProvider);
      if (savedId == null) return false;
      final nd = await _repo.layTheoId(savedId);
      if (nd == null) {
        await _clearSession();
        return false;
      }
      _nguoiDung = nd;
      _authProvider = savedProvider;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[NguoiDungProvider] khoiPhucSession error: $e');
      return false;
    }
  }

  Future<void> _saveSession(int maND, String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSessionKey, maND);
    await prefs.setString(_kAuthProvider, provider);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
    await prefs.remove(_kAuthProvider);
  }

  // ─── Email auth ──────────────────────────────────────────────────────────

  /// Đăng ký email.
  /// Trả về:
  ///   1  = tạo tài khoản OK, đã gửi OTP  
  ///  -1  = email đã tồn tại  
  ///  -2  = lỗi khác  
  Future<int> dangKyEmail({
    required String email,
    required String matKhau,
    String? hoTen,
    required String trinhDo,
    required String mucTieuCapDo,
    String? hocVi,
    required int mucTieuPhut,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final existing = await _repo.layTheoEmail(email);
      if (existing != null) {
        _error = 'Email đã được sử dụng';
        return -1;
      }

      final nd = NguoiDung(
        email: email,
        matKhau: matKhau,
        hoTen: (hoTen?.isEmpty ?? true) ? null : hoTen,
        trinhDo: trinhDo,
        mucTieuCapDo: mucTieuCapDo,
        hocVi: hocVi,
        mucTieuPhut: mucTieuPhut,
        xacMinhEmail: false,
      );
      final id = await _repo.them(nd);
      if (id <= 0) return -2;

      // Lưu pending để sau khi xác minh OTP mới đăng nhập
      _pendingMaND = id;
      _pendingEmail = email;

      // Sinh và gửi OTP
      await _guiOtp(email: email, userName: hoTen);

      return 1;
    } catch (e) {
      _error = e.toString();
      return -2;
    } finally {
      _setLoading(false);
    }
  }

  /// Gửi lại OTP (resend)
  Future<bool> guiLaiOtp({required String email, String? userName, int? maND}) async {
    _setLoading(true);
    _error = null;
    try {
      _pendingEmail ??= email;
      if (maND != null) _pendingMaND ??= maND;
      await _guiOtp(email: email, userName: userName);
      return true;
    } catch (e) {
      _error = 'Không thể gửi OTP: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _guiOtp({required String email, String? userName}) async {
    final otp = EmailOtpService.generateOtp();
    _pendingOtp = otp;
    _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
    notifyListeners();

    try {
      final ok = await EmailOtpService.sendOtp(
        toEmail: email,
        otp: otp,
        userName: userName,
      );
      if (!ok) {
        _error = 'Gửi email thất bại, vui lòng thử lại';
      }
    } catch (e) {
      debugPrint('[NguoiDungProvider] _guiOtp error: $e');
      // Vẫn cho phép nhập OTP nếu gửi thất bại (dev mode: log OTP ra console)
      debugPrint('>>> [DEV] OTP for $email: $otp <<<');
    }
    notifyListeners();
  }

  /// Xác minh OTP. Trả về true nếu đúng và chưa hết hạn.
  Future<bool> xacMinhOtp(String otpNhap) async {
    _error = null;

    // Fallback: nếu _pendingMaND null nhưng còn _pendingEmail → lookup lại
    if (_pendingMaND == null && _pendingEmail != null) {
      final nd = await _repo.layTheoEmail(_pendingEmail!);
      if (nd?.maND != null) _pendingMaND = nd!.maND;
    }

    if (_pendingMaND == null) {
      _error = 'Phiên xác minh đã hết. Vui lòng gửi lại OTP.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final nd = await _repo.layTheoId(_pendingMaND!);
      if (nd == null) {
        _error = 'Không tìm thấy tài khoản';
        return false;
      }

      final isValid = await EmailOtpService.verifyOtp(nd.email, otpNhap.trim());
      if (!isValid) {
        _error = '❌ Mã OTP không đúng hoặc đã hết hạn (10 phút)';
        return false;
      }

      await _repo.capNhatXacMinhEmail(_pendingMaND!, true);
      _nguoiDung = await _repo.layTheoId(_pendingMaND!);
      _authProvider = 'email';
      await _saveSession(_nguoiDung!.maND!, 'email');
      _clearOtpState();
      return true;
    } catch (e) {
      _error = 'Lỗi: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _clearOtpState() {
    _pendingOtp = null;
    _otpExpiry = null;
    _pendingMaND = null;
    _pendingEmail = null;
  }

  void cancelOtpFlow() {
    _clearOtpState();
    notifyListeners();
  }

  /// Bỏ qua OTP → đăng nhập ngay, email chưa xác minh
  Future<void> dangNhapSauDangKy() async {
    if (_pendingMaND == null && _pendingEmail != null) {
      final nd = await _repo.layTheoEmail(_pendingEmail!);
      if (nd?.maND != null) _pendingMaND = nd!.maND;
    }
    if (_pendingMaND == null) return;
    _nguoiDung = await _repo.layTheoId(_pendingMaND!);
    _authProvider = 'email';
    if (_nguoiDung != null) await _saveSession(_nguoiDung!.maND!, 'email');
    _clearOtpState();
    notifyListeners();
  }

  /// Đăng nhập email. Trả về true nếu thành công.
  Future<bool> dangNhapEmail(String email, String matKhau) async {
    _setLoading(true);
    _error = null;
    try {
      final nd = await _repo.layTheoEmail(email);
      if (nd == null) {
        _error = 'Email không tồn tại';
        return false;
      }
      if (nd.matKhau != matKhau) {
        _error = 'Mật khẩu không đúng';
        return false;
      }
      _nguoiDung = nd;
      _authProvider = 'email';
      await _saveSession(nd.maND!, 'email');
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google auth ─────────────────────────────────────────────────────────

  Future<bool> dangNhapGoogle({
    String trinhDo = 'A1',
    String mucTieuCapDo = 'A2',
    String? hocVi,
    int mucTieuPhut = 15,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Đã hủy đăng nhập';
        return false;
      }

      final email = googleUser.email;
      final name = googleUser.displayName;

      var nd = await _repo.layTheoEmail(email);
      if (nd == null) {
        final id = await _repo.them(NguoiDung(
          email: email,
          matKhau: '',
          hoTen: name,
          trinhDo: trinhDo,
          mucTieuCapDo: mucTieuCapDo,
          hocVi: hocVi,
          mucTieuPhut: mucTieuPhut,
          xacMinhEmail: true,
        ));
        nd = await _repo.layTheoId(id);
      }
      if (nd == null) return false;

      _nguoiDung = nd;
      _authProvider = 'google';
      await _saveSession(nd.maND!, 'google');
      return true;
    } catch (e) {
      _error = 'Lỗi Google Sign-In: $e';
      debugPrint('[NguoiDungProvider] Google error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Facebook auth ───────────────────────────────────────────────────────

  Future<bool> dangNhapFacebook({
    String trinhDo = 'A1',
    String mucTieuCapDo = 'A2',
    String? hocVi,
    int mucTieuPhut = 15,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await FacebookAuth.instance.logOut();
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        _error = result.message ?? 'Đã hủy Facebook Login';
        return false;
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: 'name,email',
      );
      final email = userData['email'] as String?;
      final name = userData['name'] as String?;

      if (email == null) {
        _error = 'Facebook không cung cấp email. Hãy thử đăng nhập bằng email.';
        return false;
      }

      var nd = await _repo.layTheoEmail(email);
      if (nd == null) {
        final id = await _repo.them(NguoiDung(
          email: email,
          matKhau: '',
          hoTen: name,
          trinhDo: trinhDo,
          mucTieuCapDo: mucTieuCapDo,
          hocVi: hocVi,
          mucTieuPhut: mucTieuPhut,
          xacMinhEmail: true,
        ));
        nd = await _repo.layTheoId(id);
      }
      if (nd == null) return false;

      _nguoiDung = nd;
      _authProvider = 'facebook';
      await _saveSession(nd.maND!, 'facebook');
      return true;
    } catch (e) {
      _error = 'Lỗi Facebook Login: $e';
      debugPrint('[NguoiDungProvider] Facebook error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Đăng xuất ───────────────────────────────────────────────────────────

  Future<void> dangXuat() async {
    try {
      if (_authProvider == 'google') await _googleSignIn.signOut();
      if (_authProvider == 'facebook') await FacebookAuth.instance.logOut();
    } catch (_) {}
    _nguoiDung = null;
    _authProvider = null;
    _clearOtpState();
    await _clearSession();
    notifyListeners();
  }

  // ─── Cập nhật hồ sơ ─────────────────────────────────────────────────────

  Future<bool> capNhatHoSo(NguoiDung nd) async {
    _setLoading(true);
    try {
      final rows = await _repo.capNhat(nd);
      if (rows > 0) {
        _nguoiDung = nd;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}