import '../database_helper.dart';
import '../../models/devtalk_model.dart';

class NhatKyRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(NhatKy nk) async {
    final db = await _db.database;
    return await db.insert('NhatKy', nk.toMap());
  }

  Future<List<NhatKy>> layTheoND(int maND) async {
    final db = await _db.database;
    final rows = await db.query(
      'NhatKy',
      where: 'MaND = ?',
      whereArgs: [maND],
      orderBy: 'NgayHoc DESC',
    );
    return rows.map((r) => NhatKy.fromMap(r)).toList();
  }

  Future<NhatKy?> layTheoNgay(int maND, String ngayHoc) async {
    final db = await _db.database;
    final rows = await db.query(
      'NhatKy',
      where: 'MaND = ? AND NgayHoc = ?',
      whereArgs: [maND, ngayHoc],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NhatKy.fromMap(rows.first);
  }

  Future<List<NhatKy>> layTheoKhoang(
      int maND, String tuNgay, String denNgay) async {
    final db = await _db.database;
    final rows = await db.query(
      'NhatKy',
      where: 'MaND = ? AND NgayHoc BETWEEN ? AND ?',
      whereArgs: [maND, tuNgay, denNgay],
      orderBy: 'NgayHoc ASC',
    );
    return rows.map((r) => NhatKy.fromMap(r)).toList();
  }

  Future<int> capNhat(NhatKy nk) async {
    final db = await _db.database;
    return await db.update(
      'NhatKy',
      nk.toMap(),
      where: 'MaNK = ?',
      whereArgs: [nk.maNK],
    );
  }

  Future<int> tongPhutTheoThang(int maND, String thang) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(TgHoc) as tong FROM NhatKy WHERE MaND = ? AND NgayHoc LIKE ?',
      [maND, '$thang%'],
    );
    return (result.first['tong'] as int?) ?? 0;
  }

  Future<int> xoa(int maNK) async {
    final db = await _db.database;
    return await db.delete('NhatKy', where: 'MaNK = ?', whereArgs: [maNK]);
  }
}