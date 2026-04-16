import '../database_helper.dart';
import '../../models/devtalk_model.dart';

class CDTuVungRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(CDTuVung cd) async {
    final db = await _db.database;
    return await db.insert('CDTuVung', cd.toMap());
  }

  Future<List<CDTuVung>> layTatCa() async {
    final db = await _db.database;
    final rows = await db.query('CDTuVung', orderBy: 'TenCD ASC');
    return rows.map((r) => CDTuVung.fromMap(r)).toList();
  }

  Future<int> xoa(int maCD) async {
    final db = await _db.database;
    return await db.delete('CDTuVung', where: 'MaCD = ?', whereArgs: [maCD]);
  }
}

class TuVungRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> them(TuVung tv) async {
    final db = await _db.database;
    return await db.insert('TuVung', tv.toMap());
  }

  Future<List<TuVung>> layTheoChuDe(int maCD) async {
    final db = await _db.database;
    final rows = await db.query(
      'TuVung',
      where: 'MaCD = ?',
      whereArgs: [maCD],
    );
    return rows.map((r) => TuVung.fromMap(r)).toList();
  }

  Future<List<TuVung>> layYeuThich() async {
    final db = await _db.database;
    final rows = await db.query(
      'TuVung',
      where: 'YeuThich = ?',
      whereArgs: [1],
    );
    return rows.map((r) => TuVung.fromMap(r)).toList();
  }

  Future<int> capNhatYeuThich(int maTu, bool yeuThich) async {
    final db = await _db.database;
    return await db.update(
      'TuVung',
      {'YeuThich': yeuThich ? 1 : 0},
      where: 'MaTu = ?',
      whereArgs: [maTu],
    );
  }

  Future<int> capNhat(TuVung tv) async {
    final db = await _db.database;
    return await db.update(
      'TuVung',
      tv.toMap(),
      where: 'MaTu = ?',
      whereArgs: [tv.maTu],
    );
  }

  Future<int> xoa(int maTu) async {
    final db = await _db.database;
    return await db.delete('TuVung', where: 'MaTu = ?', whereArgs: [maTu]);
  }
}