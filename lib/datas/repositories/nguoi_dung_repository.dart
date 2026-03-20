import '../database_helper.dart';
import '../../models/devtalk_model.dart';

class NguoiDungRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(NguoiDung nd) async {
    final db = await _db.database;
    return await db.insert('NguoiDung', nd.toMap());
  }

  Future<NguoiDung?> layTheoId(int maND) async {
    final db = await _db.database;
    final rows = await db.query(
      'NguoiDung',
      where: 'MaND = ?',
      whereArgs: [maND],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NguoiDung.fromMap(rows.first);
  }

  Future<NguoiDung?> layTheoEmail(String email) async {
    final db = await _db.database;
    final rows = await db.query(
      'NguoiDung',
      where: 'Email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NguoiDung.fromMap(rows.first);
  }

  Future<int> capNhat(NguoiDung nd) async {
    final db = await _db.database;
    return await db.update(
      'NguoiDung',
      nd.toMap(),
      where: 'MaND = ?',
      whereArgs: [nd.maND],
    );
  }

  Future<int> xoa(int maND) async {
    final db = await _db.database;
    return await db.delete('NguoiDung', where: 'MaND = ?', whereArgs: [maND]);
  }
}