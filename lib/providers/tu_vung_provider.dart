import 'package:flutter/foundation.dart';
import '../datas/repositories/tu_vung_repository.dart';
import '../models/devtalk_model.dart';

/// Quản lý trạng thái từ vựng, chủ đề học tập, danh sách yêu thích và từ đã học.
class TuVungProvider extends ChangeNotifier {
  final CDTuVungRepository _cdRepo = CDTuVungRepository();
  final TuVungRepository _tvRepo = TuVungRepository();
  final NguoiDungTuVungRepository _ndtvRepo = NguoiDungTuVungRepository();

  List<CDTuVung> _danhSachChuDe = [];
  List<TuVung> _tatCaTuVung = [];
  List<TuVung> _tuTheoChuDe = [];
  List<TuVung> _tuYeuThich = [];
  List<TuVung> _tuDaHoc = [];
  
  /// Bản đồ lưu trạng thái học tập của người dùng đối với từng từ vựng: maTu -> NguoiDungTuVung
  Map<int, NguoiDungTuVung> _ndtvMap = {};
  bool _isLoading = false;
  String? _error;

  List<CDTuVung> get danhSachChuDe => _danhSachChuDe;
  List<TuVung> get tatCaTuVung => _tatCaTuVung;
  List<TuVung> get tuTheoChuDe => _tuTheoChuDe;
  List<TuVung> get tuYeuThich => _tuYeuThich;
  List<TuVung> get tuDaHoc => _tuDaHoc;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Lấy bản ghi trạng thái học tập (yêu thích/đã học) của một từ vựng cụ thể.
  NguoiDungTuVung? getNguoiDungTuVung(int maTu) => _ndtvMap[maTu];

  /// Khởi tạo dữ liệu chủ đề và toàn bộ danh sách từ vựng từ Supabase.
  Future<void> khoiTaoDuLieu() async {
    _isLoading = true;
    notifyListeners();
    try {
      _danhSachChuDe = await _cdRepo.layTatCa();
      _tatCaTuVung = await _tvRepo.layTatCa();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TuVungProvider] Lỗi khởi tạo dữ liệu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải danh sách từ vựng thuộc về một chủ đề cụ thể (maCD).
  Future<void> layTheoChuDe(int maCD) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tuTheoChuDe = await _tvRepo.layTheoChuDe(maCD);
    } catch (e) {
      debugPrint('[TuVungProvider] Lỗi layTheoChuDe: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải thông tin ôn tập (từ yêu thích và từ đã học) của người dùng hiện tại (maND).
  Future<void> layOnTap(int maND) async {
    _isLoading = true;
    notifyListeners();
    try {
      final yeuThichIds = await _ndtvRepo.layYeuThich(maND);
      final daHocIds = await _ndtvRepo.layDaHoc(maND);
      for (final r in yeuThichIds) {
        _ndtvMap[r.maTu] = r;
      }
      for (final r in daHocIds) {
        _ndtvMap[r.maTu] = r;
      }
      _tuYeuThich = _tatCaTuVung.where((t) => _ndtvMap[t.maTu]?.yeuThich == true).toList();
      _tuDaHoc = _tatCaTuVung.where((t) => _ndtvMap[t.maTu]?.daHoc == true).toList();
    } catch (e) {
      debugPrint('[TuVungProvider] Lỗi layOnTap: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thay đổi trạng thái "Yêu thích" của từ vựng cho người dùng.
  Future<void> toggleYeuThich(int maND, int maTu) async {
    final cur = _ndtvMap[maTu];
    final newVal = !(cur?.yeuThich ?? false);
    try {
      if (cur == null) {
        final record = NguoiDungTuVung(maND: maND, maTu: maTu, yeuThich: newVal);
        await _ndtvRepo.upsert(record);
        _ndtvMap[maTu] = record;
      } else {
        final updated = NguoiDungTuVung(maND: maND, maTu: maTu, yeuThich: newVal, daHoc: cur.daHoc);
        await _ndtvRepo.upsert(updated);
        _ndtvMap[maTu] = updated;
      }
      _tuYeuThich = _tatCaTuVung.where((t) => _ndtvMap[t.maTu]?.yeuThich == true).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TuVungProvider] Lỗi toggleYeuThich: $e');
    }
  }

  /// Thay đổi trạng thái "Đã học" của từ vựng cho người dùng.
  Future<void> toggleDaHoc(int maND, int maTu) async {
    final cur = _ndtvMap[maTu];
    final newVal = !(cur?.daHoc ?? false);
    try {
      if (cur == null) {
        final record = NguoiDungTuVung(maND: maND, maTu: maTu, daHoc: newVal);
        await _ndtvRepo.upsert(record);
        _ndtvMap[maTu] = record;
      } else {
        final updated = NguoiDungTuVung(maND: maND, maTu: maTu, daHoc: newVal, yeuThich: cur.yeuThich);
        await _ndtvRepo.upsert(updated);
        _ndtvMap[maTu] = updated;
      }
      _tuDaHoc = _tatCaTuVung.where((t) => _ndtvMap[t.maTu]?.daHoc == true).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[TuVungProvider] Lỗi toggleDaHoc: $e');
    }
  }
}