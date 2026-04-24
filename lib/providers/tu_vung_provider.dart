import 'package:flutter/foundation.dart';
import '../datas/repositories/tu_vung_repository.dart';
import '../models/devtalk_model.dart';

class TuVungProvider extends ChangeNotifier {
  final CDTuVungRepository _cdRepo = CDTuVungRepository();
  final TuVungRepository _tvRepo = TuVungRepository();
  final NguoiDungTuVungRepository _ndtvRepo = NguoiDungTuVungRepository();

  List<CDTuVung> _danhSachChuDe = [];
  List<TuVung> _tatCaTuVung = [];
  List<TuVung> _tuTheoChuDe = [];
  List<TuVung> _tuYeuThich = [];
  List<TuVung> _tuDaHoc = [];
  Map<int, NguoiDungTuVung> _ndtvMap = {}; // maTu -> NguoiDungTuVung
  bool _isLoading = false;
  String? _error;

  List<CDTuVung> get danhSachChuDe => _danhSachChuDe;
  List<TuVung> get tatCaTuVung => _tatCaTuVung;
  List<TuVung> get tuTheoChuDe => _tuTheoChuDe;
  List<TuVung> get tuYeuThich => _tuYeuThich;
  List<TuVung> get tuDaHoc => _tuDaHoc;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NguoiDungTuVung? getNguoiDungTuVung(int maTu) => _ndtvMap[maTu];

  Future<void> khoiTaoDuLieu() async {
    _isLoading = true;
    notifyListeners();
    try {
      _danhSachChuDe = await _cdRepo.layTatCa();
      _tatCaTuVung = await _tvRepo.layTatCa();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('[TuVungProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> layTheoChuDe(int maCD) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tuTheoChuDe = await _tvRepo.layTheoChuDe(maCD);
    } catch (e) {
      debugPrint('[TuVungProvider] layTheoChuDe error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      debugPrint('[TuVungProvider] layOnTap error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      debugPrint('[TuVungProvider] toggleYeuThich error: $e');
    }
  }

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
      debugPrint('[TuVungProvider] toggleDaHoc error: $e');
    }
  }
}