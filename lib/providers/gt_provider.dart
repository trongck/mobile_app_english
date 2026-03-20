import 'package:flutter/foundation.dart';
import '../datas/repositories/gt_repository.dart';
import '../../models/devtalk_model.dart';

class GTProvider extends ChangeNotifier {
  final GTRepository _repository = GTRepository();

  List<GT> _danhSachIntro = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<GT> get danhSachIntro => _danhSachIntro;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Khởi tạo dữ liệu (gọi 1 lần từ main hoặc khi app khởi động) ───────────

  Future<void> khoiTaoDuLieu() async {
    _setLoading(true);
    try {
      // Nạp dữ liệu cứng lần đầu nếu bảng trống
      await _repository.kiemTraVaNapDuLieuGoc();

      // Tải danh sách intro
      _danhSachIntro = await _repository.layDanhSachIntro();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu giới thiệu: $e';
      debugPrint('[GTProvider] Lỗi: $_errorMessage');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}