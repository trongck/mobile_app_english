import 'package:flutter/material.dart';
import '../datas/repositories/bai_kt_repository.dart';
import '../models/devtalk_model.dart';

class BaiKTProvider with ChangeNotifier {
  final BaiKTRepository _repo = BaiKTRepository();

  List<BaiKT> _danhSach = [];
  bool _isLoading = false;
  bool _isDisposed = false; // Kiểm tra xem Provider còn tồn tại không

  List<BaiKT> get danhSach => _danhSach;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> layDuLieu() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ép nạp dữ liệu từ JSON
      await _repo.seedDataFromJson();

      // 2. Chờ 1 chút để DB kịp phản hồi (Android đôi khi cần độ trễ nhỏ)
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. Lấy dữ liệu
      _danhSach = await _repo.layTatCa();
      debugPrint("✅ Số lượng bài thi load được: ${_danhSach.length}");
    } catch (e) {
      debugPrint("❌ Lỗi load dữ liệu: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}