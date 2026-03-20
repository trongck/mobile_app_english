import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'devtalk_database.db');
    return await openDatabase(
      path,
       version: 1,
        onCreate: _onCreate,
        onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        },
    );
  }

  Future<void> _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE GT (
        MaGT      INTEGER PRIMARY KEY AUTOINCREMENT,
        PhienBan  TEXT    NOT NULL DEFAULT '1.0',
        TT        INTEGER NOT NULL,
        TieuDe    TEXT    NOT NULL,
        MoTa      TEXT,
        Anh       TEXT,
        UNIQUE (PhienBan, TT)
      )
    ''');
 
    await db.execute('''
      CREATE TABLE NguoiDung (
        MaND          INTEGER PRIMARY KEY AUTOINCREMENT,
        Email         TEXT    NOT NULL UNIQUE,
        MatKhau       TEXT    NOT NULL,
        HoTen         TEXT,
        NgaySinh      TEXT,
        TrinhDo       TEXT    NOT NULL DEFAULT 'A1',
        MucTieuCapDo  TEXT    NOT NULL DEFAULT 'A2',
        HocVi         TEXT,
        MucTieuPhut   INTEGER NOT NULL DEFAULT 15,
        XacMinhEmail  INTEGER NOT NULL DEFAULT 0,
        NgayTao       TEXT    NOT NULL
      )
    ''');
 
    await db.execute('''
      CREATE TABLE CDTuVung (
        MaCD   INTEGER PRIMARY KEY AUTOINCREMENT,
        TenCD  TEXT    NOT NULL
      )
    ''');
 
    await db.execute('''
      CREATE TABLE TuVung (
        MaTu      INTEGER PRIMARY KEY AUTOINCREMENT,
        Tu        TEXT    NOT NULL,
        PhienAm   TEXT,
        AmThanh   TEXT,
        NghiaEN   TEXT    NOT NULL,
        NghiaVI   TEXT,
        VdEN      TEXT,
        VdVI      TEXT,
        TuLoai    TEXT,
        MaCD      INTEGER,
        YeuThich  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (MaCD) REFERENCES CDTuVung(MaCD)
      )
    ''');
 
    await db.execute('''
      CREATE TABLE BaiKT (
        MaBKT      INTEGER PRIMARY KEY AUTOINCREMENT,
        TieuDe     TEXT    NOT NULL,
        TgLamPhut  INTEGER,
        TongDiem   INTEGER NOT NULL DEFAULT 100
      )
    ''');
 
    await db.execute('''
      CREATE TABLE CauHoiKT (
        MaCH       INTEGER PRIMARY KEY AUTOINCREMENT,
        MaBKT      INTEGER NOT NULL,
        Loai       TEXT    NOT NULL,
        NoiDung    TEXT    NOT NULL,
        LuaChon    TEXT,
        DapAn      TEXT    NOT NULL,
        GiaiThich  TEXT,
        TrongSo    INTEGER NOT NULL DEFAULT 1,
        ThuTu      INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (MaBKT) REFERENCES BaiKT(MaBKT) ON DELETE CASCADE
      )
    ''');
 
    await db.execute('''
      CREATE TABLE LSKiemTra (
        MaLS       INTEGER PRIMARY KEY AUTOINCREMENT,
        MaND       INTEGER NOT NULL,
        MaBKT      INTEGER NOT NULL,
        CauTraLoi  TEXT    NOT NULL,
        Diem       INTEGER,
        TgLam      INTEGER,
        TgBatDau   TEXT    NOT NULL,
        TgNopBai   TEXT,
        FOREIGN KEY (MaND)  REFERENCES NguoiDung(MaND) ON DELETE CASCADE,
        FOREIGN KEY (MaBKT) REFERENCES BaiKT(MaBKT)
      )
    ''');
 
    await db.execute('''
      CREATE TABLE NhatKy (
        MaNK     INTEGER PRIMARY KEY AUTOINCREMENT,
        MaND     INTEGER NOT NULL,
        NgayHoc  TEXT    NOT NULL,
        TgOn     TEXT    NOT NULL,
        TgOff    TEXT    NOT NULL,
        TgHoc    INTEGER NOT NULL,
        FOREIGN KEY (MaND) REFERENCES NguoiDung(MaND) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> dongDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
 
}
