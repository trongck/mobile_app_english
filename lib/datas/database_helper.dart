import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

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
      CREATE TABLE XacThucEmail (
        Email           TEXT PRIMARY KEY,
        MaOTP           TEXT NOT NULL,
        ThoiGianHetHan  TEXT NOT NULL
      )
    ''');

    // Bảng trung gian lưu trạng thái từ vựng cá nhân hóa cho từng Người dùng
    await db.execute('''
      CREATE TABLE NguoiDung_TuVung (
        MaND      INTEGER NOT NULL,
        MaTu      INTEGER NOT NULL,
        DaHoc     INTEGER NOT NULL DEFAULT 0,
        YeuThich  INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (MaND, MaTu),
        FOREIGN KEY (MaND) REFERENCES NguoiDung(MaND) ON DELETE CASCADE,
        FOREIGN KEY (MaTu) REFERENCES TuVung(MaTu) ON DELETE CASCADE
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

    //Thêm
    await db.execute('''
    INSERT INTO BaiKT (MaBKT, TieuDe, TgLamPhut, TongDiem) VALUES
    (1, 'Test 1 - Beginner', 10, 100),
    (2, 'Test 2 - Intermediate', 15, 100),
    (3, 'Test 3 - Advanced', 20, 100),
    (4, 'Test 4 - Vocabulary', 15, 100),
    (5, 'Test 5 - Grammar', 15, 100)
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
    //Thêm
    await seedCauHoiKT(db);

 
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
//Thêm
  Future<void> seedCauHoiKT(Database db) async {
    // Danh sách 5 bài
    final List<int> maBai = [1, 2, 3, 4, 5];

    for (int bkt in maBai) {
      for (int i = 1; i <= 20; i++) {
        // Tạo câu hỏi trắc nghiệm
        String noiDung = "Question $i for Test $bkt (Multiple Choice)?";
        String luaChon = '{"A":"Option A","B":"Option B","C":"Option C","D":"Option D"}';
        String dapAn = "A";
        String giaiThich = "Explanation for question $i of Test $bkt";

        await db.execute('''
        INSERT INTO CauHoiKT (MaBKT, Loai, NoiDung, LuaChon, DapAn, GiaiThich, TrongSo, ThuTu)
        VALUES ($bkt, 'trac_nghiem', '$noiDung', '$luaChon', '$dapAn', '$giaiThich', 1, $i)
      ''');
      }

      for (int i = 21; i <= 40; i++) {
        // Tạo câu hỏi đúng/sai
        String noiDung = "Statement $i for Test $bkt (True/False)?";
        String luaChon = '{"A":"True","B":"False"}';
        String dapAn = "A";
        String giaiThich = "Explanation for statement $i of Test $bkt";

        await db.execute('''
        INSERT INTO CauHoiKT (MaBKT, Loai, NoiDung, LuaChon, DapAn, GiaiThich, TrongSo, ThuTu)
        VALUES ($bkt, 'dung_sai', '$noiDung', '$luaChon', '$dapAn', '$giaiThich', 1, $i)
      ''');
      }

      for (int i = 41; i <= 50; i++) {
        // Tạo câu hỏi điền khuyết
        String noiDung = "Fill in the blank for Test $bkt: ___ is ...";
        String luaChon = "";
        String dapAn = "Answer $i";
        String giaiThich = "Explanation for blank $i of Test $bkt";

        await db.execute('''
        INSERT INTO CauHoiKT (MaBKT, Loai, NoiDung, LuaChon, DapAn, GiaiThich, TrongSo, ThuTu)
        VALUES ($bkt, 'dien_khuyet', '$noiDung', '$luaChon', '$dapAn', '$giaiThich', 1, $i)
      ''');
      }
    }
  }

  /// Lấy danh sách câu hỏi theo mã bài kiểm tra
  Future<List<Map<String, dynamic>>> layCauHoiTheoBai(int maBKT) async {
    final db = await database;
    return await db.query(
      'CauHoiKT',
      where: 'MaBKT = ?',
      whereArgs: [maBKT],
      orderBy: 'ThuTu ASC',
    );
  }

  /// Nộp bài kiểm tra
  Future<void> nopBai({
    required int maND,
    required int maBKT,
    required Map<int, String> dapAnNguoiDung,
    required int tgLam, // giây
    required DateTime tgBatDau,
  }) async {
    final db = await database;
    final cauHoi = await layCauHoiTheoBai(maBKT);
    int tongDiem = 0;

    // Tính điểm
    for (var ch in cauHoi) {
      int maCH = ch['MaCH'] as int;
      int trongSo = ch['TrongSo'] as int? ?? 1;
      String dapAnDung = ch['DapAn'] as String;

      if (dapAnNguoiDung[maCH] != null &&
          dapAnNguoiDung[maCH] == dapAnDung) {
        tongDiem += trongSo;
      }
    }

    // Encode câu trả lời người dùng thành JSON
    String cauTraLoiJson = jsonEncode(
        dapAnNguoiDung.map((key, value) => MapEntry(key.toString(), value))
    );

    await db.insert('LSKiemTra', {
      'MaND': maND,
      'MaBKT': maBKT,
      'CauTraLoi': cauTraLoiJson,
      'Diem': tongDiem,
      'TgLam': tgLam,
      'TgBatDau': tgBatDau.toIso8601String(),
      'TgNopBai': DateTime.now().toIso8601String(),
    });
  }

  /// Lấy lịch sử làm bài của người dùng
  Future<List<Map<String, dynamic>>> layLichSu(int maND) async {
    final db = await database;
    return await db.query(
      'LSKiemTra',
      where: 'MaND = ?',
      whereArgs: [maND],
      orderBy: 'TgBatDau DESC',
    );
  }

  /// Chuyển JSON string từ cột CauTraLoi thành Map<int, String>
  Map<int, String> parseCauTraLoi(String jsonStr) {
    final Map<String, dynamic> tmp = jsonDecode(jsonStr);
    return tmp.map((key, value) => MapEntry(int.parse(key), value.toString()));
  }

  /// Lấy danh sách tất cả bài kiểm tra
  Future<List<Map<String, dynamic>>> layBaiKT() async {
    final db = await database;
    return await db.query('BaiKT', orderBy: 'MaBKT ASC');
  }

  Future<void> dongDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
 
}
