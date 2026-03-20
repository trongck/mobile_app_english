import '../database_helper.dart';
import '../../models/devtalk_model.dart';

class BaiKTRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(BaiKT bkt) async {
    final db = await _db.database;
    return await db.insert('BaiKT', bkt.toMap());
  }

  Future<List<BaiKT>> layTatCa() async {
    final db = await _db.database;
    final rows = await db.query('BaiKT', orderBy: 'MaBKT DESC');
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

  Future<int> capNhatDiem(int maLS, int diem, int tgLam, String tgNopBai) async {
    final db = await _db.database;
    return await db.update(
      'LSKiemTra',
      {'Diem': diem, 'TgLam': tgLam, 'TgNopBai': tgNopBai},
      where: 'MaLS = ?',
      whereArgs: [maLS],
    );
  }
}