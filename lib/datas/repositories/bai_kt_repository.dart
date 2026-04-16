import '../database_helper.dart';
import '../../models/devtalk_model.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

class BaiKTRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> seedDataFromJson() async {
    final db = await _db.database;

    // 1. Kiểm tra xem đã có dữ liệu chưa để tránh trùng lặp
    List<Map<String, dynamic>> existing = await db.query('BaiKT');
    if (existing.isNotEmpty) return;

    try {
      // 2. Đọc file JSON từ assets
      final String response = await rootBundle.loadString('assets/data/Test.json');
      final List<dynamic> data = json.decode(response);

      await db.transaction((txn) async {
        for (var test in data) {
          // 3. Chèn thông tin bài kiểm tra vào bảng BaiKT
          int maBKT = await txn.insert('BaiKT', {
            'TieuDe': test['TieuDe'],
            'TgLamPhut': test['TgLamPhut'],
            'TongDiem': test['TongDiem'],
          });

          // 4. Chèn danh sách câu hỏi tương ứng vào bảng CauHoiKT
          List<dynamic> questions = test['CauHoi'];
          int thuTu = 1;
          for (var q in questions) {
            await txn.insert('CauHoiKT', {
              'MaBKT': maBKT,
              'Loai': 'TracNghiem',
              'NoiDung': q['NoiDung'],
              'LuaChon': q['LuaChon'], // Giữ nguyên dạng chuỗi JSON của lựa chọn
              'DapAn': q['DapAn'],
              'GiaiThich': q['GiaiThich'],
              'ThuTu': thuTu++,
              'TrongSo': 1
            });
          }
        }
      });
      print("--- ✅ Đã nạp dữ liệu từ JSON thành công! ---");
    } catch (e) {
      print("--- ❌ Lỗi khi đọc file JSON: $e ---");
    }
  }

  Future<int> them(BaiKT bkt) async {
    final db = await _db.database;
    return await db.insert('BaiKT', bkt.toMap());
  }

  Future<List<BaiKT>> layTatCa() async {
    final db = await _db.database;
    // Sắp xếp ASC để bài 1 hiện lên trước cho dễ nhìn
    final rows = await db.query('BaiKT', orderBy: 'MaBKT ASC');
    return rows.map((r) => BaiKT.fromMap(r)).toList();
  }

  Future<BaiKT?> layTheoId(int maBKT) async {
    final db = await _db.database;
    final rows = await db.query(
      'BaiKT',
      where: 'MaBKT = ?',
      whereArgs: [maBKT],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BaiKT.fromMap(rows.first);
  }

  Future<int> xoa(int maBKT) async {
    final db = await _db.database;
    return await db.delete('BaiKT', where: 'MaBKT = ?', whereArgs: [maBKT]);
  }
}

class CauHoiKTRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(CauHoiKT ch) async {
    final db = await _db.database;
    return await db.insert('CauHoiKT', ch.toMap());
  }

  Future<List<CauHoiKT>> layTheoBai(int maBKT) async {
    final db = await _db.database;
    final rows = await db.query(
      'CauHoiKT',
      where: 'MaBKT = ?',
      whereArgs: [maBKT],
      orderBy: 'ThuTu ASC',
    );
    return rows.map((r) => CauHoiKT.fromMap(r)).toList();
  }

  Future<int> xoa(int maCH) async {
    final db = await _db.database;
    return await db.delete('CauHoiKT', where: 'MaCH = ?', whereArgs: [maCH]);
  }
}

class LSKiemTraRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(LSKiemTra ls) async {
    final db = await _db.database;
    return await db.insert('LSKiemTra', ls.toMap());
  }

  Future<LSKiemTra?> layLichSuMoiNhat(int maBKT) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'LSKiemTra',
      where: 'MaBKT = ?',
      whereArgs: [maBKT],
      orderBy: 'TgNopBai DESC', // Lấy bản ghi có thời gian nộp mới nhất
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LSKiemTra.fromMap(maps.first);
  }

  Future<List<LSKiemTra>> layTheoND(int maND) async {
    final db = await _db.database;
    final rows = await db.query(
      'LSKiemTra',
      where: 'MaND = ?',
      whereArgs: [maND],
      orderBy: 'TgBatDau DESC',
    );
    return rows.map((r) => LSKiemTra.fromMap(r)).toList();
  }

  Future<LSKiemTra?> layTheoId(int maLS) async {
    final db = await _db.database;
    final rows = await db.query(
      'LSKiemTra',
      where: 'MaLS = ?',
      whereArgs: [maLS],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LSKiemTra.fromMap(rows.first);
  }

  Future<int> luuLichSu(LSKiemTra ls) async {
    final db = await _db.database;
    // Phải gọi ls.toMap() và đảm bảo trong toMap() các key khớp với tên cột DB
    return await db.insert('LSKiemTra', ls.toMap());
  }
  // Sửa lại kiểu dữ liệu của điểm thành double vì điểm thi thường có số lẻ (0.5)
  Future<int> capNhatDiem(int maLS, double diem, int tgLam, String tgNopBai) async {
    final db = await _db.database;
    return await db.update(
      'LSKiemTra',
      {'Diem': diem, 'TgLam': tgLam, 'TgNopBai': tgNopBai},
      where: 'MaLS = ?',
      whereArgs: [maLS],
    );
  }


}