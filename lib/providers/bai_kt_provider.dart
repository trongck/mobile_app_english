import 'package:flutter/material.dart';
import 'dart:convert';
import '../datas/database_helper.dart';

class BaiKTProvider extends ChangeNotifier {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Danh sách bài kiểm tra
  List<Map<String, dynamic>> baiKTList = [];

  // Danh sách câu hỏi của bài kiểm tra đang làm
  List<Map<String, dynamic>> cauHoiList = [];

  // Map tạm lưu đáp án của người dùng {MaCH: DapAn}
  Map<int, String> dapAnTam = {};

  // Lịch sử làm bài của người dùng
  List<Map<String, dynamic>> lichSu = [];

  /// Load tất cả bài kiểm tra
  Future<void> loadBaiKT() async {
    baiKTList = await dbHelper.layBaiKT();
    notifyListeners();
  }

  /// Load danh sách câu hỏi theo mã bài kiểm tra
  Future<void> loadCauHoi(int maBKT) async {
    cauHoiList = await dbHelper.layCauHoiTheoBai(maBKT);
    dapAnTam = {}; // Reset đáp án tạm khi load câu hỏi mới
    notifyListeners();
  }

  /// Chọn đáp án tạm thời cho một câu hỏi
  void chonDapAn(int maCH, String dapAn) {
    dapAnTam[maCH] = dapAn;
    notifyListeners();
  }

  /// Nộp bài kiểm tra
  Future<void> nopBai({
    required int maND,
    required int maBKT,
    required int tgLam, // thời gian làm bài (giây)
    required DateTime tgBatDau,
  }) async {
    await dbHelper.nopBai(
      maND: maND,
      maBKT: maBKT,
      dapAnNguoiDung: dapAnTam,
      tgLam: tgLam,
      tgBatDau: tgBatDau,
    );
    dapAnTam = {}; // Reset sau khi nộp bài
    notifyListeners();
  }

  /// Load lịch sử làm bài của người dùng
  Future<void> loadLichSu(int maND) async {
    lichSu = await dbHelper.layLichSu(maND);
    notifyListeners();
  }

  /// Chuyển JSON câu trả lời trong LSKiemTra thành Map<int, String>
  Map<int, String> parseCauTraLoi(String jsonStr) {
    final Map<String, dynamic> tmp = jsonDecode(jsonStr);
    return tmp.map((key, value) => MapEntry(int.parse(key), value.toString()));
  }

  /// Lấy điểm từng câu (đúng/sai) để hiển thị màu xanh/đỏ
  Map<int, bool> diemTungCau(String cauTraLoiJson, List<Map<String, dynamic>> cauHoi) {
    final Map<int, String> dapAnND = parseCauTraLoi(cauTraLoiJson);
    Map<int, bool> ketQua = {};

    for (var ch in cauHoi) {
      int maCH = ch['MaCH'] as int;
      String dapAnDung = (ch['DapAn'] as String).trim().toLowerCase();
      String? cauTraLoiCuaND = dapAnND[maCH]?.trim().toLowerCase();

      // So sánh chuẩn hóa chuỗi
      ketQua[maCH] = (cauTraLoiCuaND != null && cauTraLoiCuaND == dapAnDung);
    }
    return ketQua;
  }
}