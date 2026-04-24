import 'package:flutter/foundation.dart';
import '../datas/repositories/bai_kt_repository.dart';
import '../models/devtalk_model.dart';

class BaiKTProvider extends ChangeNotifier {
  final BaiKTRepository _baiKTRepo = BaiKTRepository();
  final CauHoiKTRepository _cauHoiRepo = CauHoiKTRepository();
  final LSKiemTraRepository _lsRepo = LSKiemTraRepository();

  List<BaiKT> _danhSachBaiKT = [];
  Map<int, List<CauHoiKT>> _cauHoiMap = {};
  List<LSKiemTra> _lichSu = [];
  bool _isLoading = false;
  String? _error;

  List<BaiKT> get danhSachBaiKT => _danhSachBaiKT;
  List<LSKiemTra> get lichSu => _lichSu;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BaiKT? getBaiKT(int maBKT) => _danhSachBaiKT.firstWhere((b) => b.maBKT == maBKT, orElse: () => BaiKT(tieuDe: 'Bài kiểm tra'));

  List<CauHoiKT> getCauHoi(int maBKT) => _cauHoiMap[maBKT] ?? [];

  Future<void> khoiTao(int? maND) async {
    _isLoading = true;
    notifyListeners();
    try {
      _danhSachBaiKT = await _baiKTRepo.layTatCa();
      if (maND != null) {
        _lichSu = await _lsRepo.layTheoND(maND);
        // Pre-load câu hỏi cho các bài đã làm
        for (final ls in _lichSu) {
          if (!_cauHoiMap.containsKey(ls.maBKT)) {
            _cauHoiMap[ls.maBKT] = await _cauHoiRepo.layTheoBai(ls.maBKT);
          }
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[BaiKTProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<CauHoiKT>> layCauHoi(int maBKT) async {
    if (_cauHoiMap.containsKey(maBKT)) return _cauHoiMap[maBKT]!;
    final list = await _cauHoiRepo.layTheoBai(maBKT);
    _cauHoiMap[maBKT] = list;
    return list;
  }

  Future<void> luuKetQua(LSKiemTra ls) async {
    try {
      final id = await _lsRepo.them(ls);
      final saved = LSKiemTra(
        maLS: id,
        maND: ls.maND,
        maBKT: ls.maBKT,
        cauTraLoi: ls.cauTraLoi,
        diem: ls.diem,
        tgLam: ls.tgLam,
        tgBatDau: ls.tgBatDau,
        tgNopBai: DateTime.now().toIso8601String(),
      );
      _lichSu.insert(0, saved);
      notifyListeners();
    } catch (e) {
      debugPrint('[BaiKTProvider] luuKetQua error: $e');
    }
  }
}