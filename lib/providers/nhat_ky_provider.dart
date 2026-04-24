import 'package:flutter/foundation.dart';
import '../datas/repositories/nhat_ky_repository.dart';
import '../models/devtalk_model.dart';

class NhatKyProvider extends ChangeNotifier {
  final NhatKyRepository _repo = NhatKyRepository();

  Map<String, int> _nhatKy7Ngay = {}; // key: 'yyyy-MM-dd', value: phut
  int _chuoiNgay = 0;
  bool _isLoading = false;
  DateTime? _sessionStart;
  int? _currentMaND;

  Map<String, int> get nhatKy7Ngay => _nhatKy7Ngay;
  int get chuoiNgay => _chuoiNgay;
  bool get isLoading => _isLoading;

  Future<void> layNhatKy7Ngay(int maND) async {
    _isLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final tuNgay = now.subtract(const Duration(days: 6));
      final tuNgayStr = _dateStr(tuNgay);
      final denNgayStr = _dateStr(now);
      final list = await _repo.layTheoKhoang(maND, tuNgayStr, denNgayStr);
      _nhatKy7Ngay = {for (final nk in list) nk.ngayHoc: nk.tgHoc};
      _tinhChuoiNgay(list);
    } catch (e) {
      debugPrint('[NhatKyProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void batDauSession(int maND) {
    _sessionStart = DateTime.now();
    _currentMaND = maND;
  }

  Future<void> ketThucSession() async {
    if (_sessionStart == null || _currentMaND == null) return;
    final end = DateTime.now();
    final phut = end.difference(_sessionStart!).inMinutes;
    if (phut < 1) { _sessionStart = null; return; }

    final ngay = _dateStr(DateTime.now());
    try {
      final existing = await _repo.layTheoNgay(_currentMaND!, ngay);
      if (existing != null && existing.maNK != null) {
        final updated = NhatKy(
          maNK: existing.maNK,
          maND: _currentMaND!,
          ngayHoc: ngay,
          tgOn: existing.tgOn,
          tgOff: end.toIso8601String(),
          tgHoc: existing.tgHoc + phut,
        );
        await _repo.capNhat(updated);
        _nhatKy7Ngay[ngay] = updated.tgHoc;
      } else {
        final nk = NhatKy(maND: _currentMaND!, ngayHoc: ngay, tgOn: _sessionStart!.toIso8601String(), tgOff: end.toIso8601String(), tgHoc: phut);
        await _repo.them(nk);
        _nhatKy7Ngay[ngay] = phut;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[NhatKyProvider] ketThucSession error: $e');
    }
    _sessionStart = null;
  }

  void _tinhChuoiNgay(List<NhatKy> list) {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i <= 30; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dateStr(d);
      if (list.any((nk) => nk.ngayHoc == key && nk.tgHoc > 0)) {
        streak++;
      } else {
        break;
      }
    }
    _chuoiNgay = streak;
  }

  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}