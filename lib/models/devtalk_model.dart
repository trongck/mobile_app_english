import 'dart:convert';

class GT {
  final int? maGT;
  final String phienBan;
  final int tt;
  final String tieuDe;
  final String? moTa;
  final String? anh;

  GT({
    this.maGT,
    this.phienBan = '1.0',
    required this.tt,
    required this.tieuDe,
    this.moTa,
    this.anh,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maGT != null) 'MaGT': maGT,
      'PhienBan': phienBan,
      'TT': tt,
      'TieuDe': tieuDe,
      'MoTa': moTa,
      'Anh': anh,
    };
  }

  factory GT.fromMap(Map<String, dynamic> map) {
    return GT(
      maGT: map['MaGT'] as int?,
      phienBan: map['PhienBan'] as String? ?? '1.0',
      tt: map['TT'] as int,
      tieuDe: map['TieuDe'] as String,
      moTa: map['MoTa'] as String?,
      anh: map['Anh'] as String?,
    );
  }

  GT copyWith({
    int? maGT,
    String? phienBan,
    int? tt,
    String? tieuDe,
    String? moTa,
    String? anh,
  }) {
    return GT(
      maGT: maGT ?? this.maGT,
      phienBan: phienBan ?? this.phienBan,
      tt: tt ?? this.tt,
      tieuDe: tieuDe ?? this.tieuDe,
      moTa: moTa ?? this.moTa,
      anh: anh ?? this.anh,
    );
  }

  @override
  String toString() =>
      'GT(maGT: $maGT, phienBan: $phienBan, tt: $tt, tieuDe: $tieuDe)';
}


class NguoiDung {
  final int? maND;
  final String email;
  final String matKhau;
  final String? hoTen;
  final String? ngaySinh;
  final String trinhDo;
  final String mucTieuCapDo;
  final String? hocVi;
  final int mucTieuPhut;
  final bool xacMinhEmail;
  final String ngayTao;

  NguoiDung({
    this.maND,
    required this.email,
    required this.matKhau,
    this.hoTen,
    this.ngaySinh,
    this.trinhDo = 'A1',
    this.mucTieuCapDo = 'A2',
    this.hocVi,
    this.mucTieuPhut = 15,
    this.xacMinhEmail = false,
    String? ngayTao,
  }) : ngayTao = ngayTao ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (maND != null) 'MaND': maND,
      'Email': email,
      'MatKhau': matKhau,
      'HoTen': hoTen,
      'NgaySinh': ngaySinh,
      'TrinhDo': trinhDo,
      'MucTieuCapDo': mucTieuCapDo,
      'HocVi': hocVi,
      'MucTieuPhut': mucTieuPhut,
      'XacMinhEmail': xacMinhEmail ? 1 : 0,
      'NgayTao': ngayTao,
    };
  }

  factory NguoiDung.fromMap(Map<String, dynamic> map) {
    return NguoiDung(
      maND: map['MaND'] as int?,
      email: map['Email'] as String,
      matKhau: map['MatKhau'] as String,
      hoTen: map['HoTen'] as String?,
      ngaySinh: map['NgaySinh'] as String?,
      trinhDo: map['TrinhDo'] as String? ?? 'A1',
      mucTieuCapDo: map['MucTieuCapDo'] as String? ?? 'A2',
      hocVi: map['HocVi'] as String?,
      mucTieuPhut: map['MucTieuPhut'] as int? ?? 15,
      xacMinhEmail: (map['XacMinhEmail'] as int? ?? 0) == 1,
      ngayTao: map['NgayTao'] as String?,
    );
  }

  NguoiDung copyWith({
    int? maND,
    String? email,
    String? matKhau,
    String? hoTen,
    String? ngaySinh,
    String? trinhDo,
    String? mucTieuCapDo,
    String? hocVi,
    int? mucTieuPhut,
    bool? xacMinhEmail,
    String? ngayTao,
  }) {
    return NguoiDung(
      maND: maND ?? this.maND,
      email: email ?? this.email,
      matKhau: matKhau ?? this.matKhau,
      hoTen: hoTen ?? this.hoTen,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      trinhDo: trinhDo ?? this.trinhDo,
      mucTieuCapDo: mucTieuCapDo ?? this.mucTieuCapDo,
      hocVi: hocVi ?? this.hocVi,
      mucTieuPhut: mucTieuPhut ?? this.mucTieuPhut,
      xacMinhEmail: xacMinhEmail ?? this.xacMinhEmail,
      ngayTao: ngayTao ?? this.ngayTao,
    );
  }

  @override
  String toString() =>
      'NguoiDung(maND: $maND, email: $email, hoTen: $hoTen, trinhDo: $trinhDo)';
}


class CDTuVung {
  final int? maCD;
  final String tenCD;

  CDTuVung({
    this.maCD,
    required this.tenCD,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maCD != null) 'MaCD': maCD,
      'TenCD': tenCD,
    };
  }

  factory CDTuVung.fromMap(Map<String, dynamic> map) {
    return CDTuVung(
      maCD: map['MaCD'] as int?,
      tenCD: map['TenCD'] as String,
    );
  }

  CDTuVung copyWith({int? maCD, String? tenCD}) {
    return CDTuVung(
      maCD: maCD ?? this.maCD,
      tenCD: tenCD ?? this.tenCD,
    );
  }

  @override
  String toString() => 'CDTuVung(maCD: $maCD, tenCD: $tenCD)';
}


class TuVung {
  final int? maTu;
  final String tu;
  final String? phienAm;
  final String? amThanh;
  final String nghiaEN;
  final String? nghiaVI;
  final String? vdEN;
  final String? vdVI;
  final String? tuLoai;
  final int? maCD;
  final bool yeuThich;

  TuVung({
    this.maTu,
    required this.tu,
    this.phienAm,
    this.amThanh,
    required this.nghiaEN,
    this.nghiaVI,
    this.vdEN,
    this.vdVI,
    this.tuLoai,
    this.maCD,
    this.yeuThich = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maTu != null) 'MaTu': maTu,
      'Tu': tu,
      'PhienAm': phienAm,
      'AmThanh': amThanh,
      'NghiaEN': nghiaEN,
      'NghiaVI': nghiaVI,
      'VdEN': vdEN,
      'VdVI': vdVI,
      'TuLoai': tuLoai,
      'MaCD': maCD,
      'YeuThich': yeuThich ? 1 : 0,
    };
  }

  factory TuVung.fromMap(Map<String, dynamic> map) {
    return TuVung(
      maTu: map['MaTu'] as int?,
      tu: map['Tu'] as String,
      phienAm: map['PhienAm'] as String?,
      amThanh: map['AmThanh'] as String?,
      nghiaEN: map['NghiaEN'] as String,
      nghiaVI: map['NghiaVI'] as String?,
      vdEN: map['VdEN'] as String?,
      vdVI: map['VdVI'] as String?,
      tuLoai: map['TuLoai'] as String?,
      maCD: map['MaCD'] as int?,
      yeuThich: (map['YeuThich'] as int? ?? 0) == 1,
    );
  }

  TuVung copyWith({
    int? maTu,
    String? tu,
    String? phienAm,
    String? amThanh,
    String? nghiaEN,
    String? nghiaVI,
    String? vdEN,
    String? vdVI,
    String? tuLoai,
    int? maCD,
    bool? yeuThich,
  }) {
    return TuVung(
      maTu: maTu ?? this.maTu,
      tu: tu ?? this.tu,
      phienAm: phienAm ?? this.phienAm,
      amThanh: amThanh ?? this.amThanh,
      nghiaEN: nghiaEN ?? this.nghiaEN,
      nghiaVI: nghiaVI ?? this.nghiaVI,
      vdEN: vdEN ?? this.vdEN,
      vdVI: vdVI ?? this.vdVI,
      tuLoai: tuLoai ?? this.tuLoai,
      maCD: maCD ?? this.maCD,
      yeuThich: yeuThich ?? this.yeuThich,
    );
  }

  @override
  String toString() =>
      'TuVung(maTu: $maTu, tu: $tu, nghiaEN: $nghiaEN, yeuThich: $yeuThich)';
}


class BaiKT {
  final int? maBKT;
  final String tieuDe;
  final int? tgLamPhut;
  final int tongDiem;

  BaiKT({
    this.maBKT,
    required this.tieuDe,
    this.tgLamPhut,
    this.tongDiem = 100,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maBKT != null) 'MaBKT': maBKT,
      'TieuDe': tieuDe,
      'TgLamPhut': tgLamPhut,
      'TongDiem': tongDiem,
    };
  }

  factory BaiKT.fromMap(Map<String, dynamic> map) {
    return BaiKT(
      maBKT: map['MaBKT'] as int?,
      tieuDe: map['TieuDe'] as String,
      tgLamPhut: map['TgLamPhut'] as int?,
      tongDiem: map['TongDiem'] as int? ?? 100,
    );
  }

  BaiKT copyWith({
    int? maBKT,
    String? tieuDe,
    int? tgLamPhut,
    int? tongDiem,
  }) {
    return BaiKT(
      maBKT: maBKT ?? this.maBKT,
      tieuDe: tieuDe ?? this.tieuDe,
      tgLamPhut: tgLamPhut ?? this.tgLamPhut,
      tongDiem: tongDiem ?? this.tongDiem,
    );
  }

  @override
  String toString() =>
      'BaiKT(maBKT: $maBKT, tieuDe: $tieuDe, tongDiem: $tongDiem)';
}


class CauHoiKT {
  final int? maCH;
  final int maBKT;
  final String loai;       // tracnghiem / dung_sai / dien_khuyet
  final String noiDung;
  final List<Map<String, dynamic>>? luaChon; // [{ky_hieu, noi_dung}]
  final String dapAn;
  final String? giaiThich;
  final int trongSo;
  final int thuTu;

  CauHoiKT({
    this.maCH,
    required this.maBKT,
    required this.loai,
    required this.noiDung,
    this.luaChon,
    required this.dapAn,
    this.giaiThich,
    this.trongSo = 1,
    this.thuTu = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maCH != null) 'MaCH': maCH,
      'MaBKT': maBKT,
      'Loai': loai,
      'NoiDung': noiDung,
      'LuaChon': luaChon != null ? jsonEncode(luaChon) : null,
      'DapAn': dapAn,
      'GiaiThich': giaiThich,
      'TrongSo': trongSo,
      'ThuTu': thuTu,
    };
  }

  factory CauHoiKT.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>>? luaChon;
    if (map['LuaChon'] != null) {
      final decoded = jsonDecode(map['LuaChon'] as String);
      luaChon = List<Map<String, dynamic>>.from(decoded);
    }
    return CauHoiKT(
      maCH: map['MaCH'] as int?,
      maBKT: map['MaBKT'] as int,
      loai: map['Loai'] as String,
      noiDung: map['NoiDung'] as String,
      luaChon: luaChon,
      dapAn: map['DapAn'] as String,
      giaiThich: map['GiaiThich'] as String?,
      trongSo: map['TrongSo'] as int? ?? 1,
      thuTu: map['ThuTu'] as int? ?? 0,
    );
  }

  CauHoiKT copyWith({
    int? maCH,
    int? maBKT,
    String? loai,
    String? noiDung,
    List<Map<String, dynamic>>? luaChon,
    String? dapAn,
    String? giaiThich,
    int? trongSo,
    int? thuTu,
  }) {
    return CauHoiKT(
      maCH: maCH ?? this.maCH,
      maBKT: maBKT ?? this.maBKT,
      loai: loai ?? this.loai,
      noiDung: noiDung ?? this.noiDung,
      luaChon: luaChon ?? this.luaChon,
      dapAn: dapAn ?? this.dapAn,
      giaiThich: giaiThich ?? this.giaiThich,
      trongSo: trongSo ?? this.trongSo,
      thuTu: thuTu ?? this.thuTu,
    );
  }

  @override
  String toString() =>
      'CauHoiKT(maCH: $maCH, loai: $loai, noiDung: $noiDung)';
}


class LSKiemTra {
  final int? maLS;
  final int maND;
  final int maBKT;
  final Map<String, dynamic> cauTraLoi; // {ma_cau_hoi: dap_an}
  final int? diem;
  final int? tgLam;
  final String tgBatDau;
  final String? tgNopBai;

  LSKiemTra({
    this.maLS,
    required this.maND,
    required this.maBKT,
    required this.cauTraLoi,
    this.diem,
    this.tgLam,
    String? tgBatDau,
    this.tgNopBai,
  }) : tgBatDau = tgBatDau ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (maLS != null) 'MaLS': maLS,
      'MaND': maND,
      'MaBKT': maBKT,
      'CauTraLoi': jsonEncode(cauTraLoi),
      'Diem': diem,
      'TgLam': tgLam,
      'TgBatDau': tgBatDau,
      'TgNopBai': tgNopBai,
    };
  }

  factory LSKiemTra.fromMap(Map<String, dynamic> map) {
    return LSKiemTra(
      maLS: map['MaLS'] as int?,
      maND: map['MaND'] as int,
      maBKT: map['MaBKT'] as int,
      cauTraLoi: Map<String, dynamic>.from(
          jsonDecode(map['CauTraLoi'] as String)),
      diem: map['Diem'] as int?,
      tgLam: map['TgLam'] as int?,
      tgBatDau: map['TgBatDau'] as String?,
      tgNopBai: map['TgNopBai'] as String?,
    );
  }

  LSKiemTra copyWith({
    int? maLS,
    int? maND,
    int? maBKT,
    Map<String, dynamic>? cauTraLoi,
    int? diem,
    int? tgLam,
    String? tgBatDau,
    String? tgNopBai,
  }) {
    return LSKiemTra(
      maLS: maLS ?? this.maLS,
      maND: maND ?? this.maND,
      maBKT: maBKT ?? this.maBKT,
      cauTraLoi: cauTraLoi ?? this.cauTraLoi,
      diem: diem ?? this.diem,
      tgLam: tgLam ?? this.tgLam,
      tgBatDau: tgBatDau ?? this.tgBatDau,
      tgNopBai: tgNopBai ?? this.tgNopBai,
    );
  }

  @override
  String toString() =>
      'LSKiemTra(maLS: $maLS, maND: $maND, maBKT: $maBKT, diem: $diem)';
}


class NhatKy {
  final int? maNK;
  final int maND;
  final String ngayHoc;   // lưu dạng 'yyyy-MM-dd'
  final String tgOn;      // ISO8601
  final String tgOff;     // ISO8601
  final int tgHoc;        // số phút học

  NhatKy({
    this.maNK,
    required this.maND,
    required this.ngayHoc,
    required this.tgOn,
    required this.tgOff,
    required this.tgHoc,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maNK != null) 'MaNK': maNK,
      'MaND': maND,
      'NgayHoc': ngayHoc,
      'TgOn': tgOn,
      'TgOff': tgOff,
      'TgHoc': tgHoc,
    };
  }

  factory NhatKy.fromMap(Map<String, dynamic> map) {
    return NhatKy(
      maNK: map['MaNK'] as int?,
      maND: map['MaND'] as int,
      ngayHoc: map['NgayHoc'] as String,
      tgOn: map['TgOn'] as String,
      tgOff: map['TgOff'] as String,
      tgHoc: map['TgHoc'] as int,
    );
  }

  NhatKy copyWith({
    int? maNK,
    int? maND,
    String? ngayHoc,
    String? tgOn,
    String? tgOff,
    int? tgHoc,
  }) {
    return NhatKy(
      maNK: maNK ?? this.maNK,
      maND: maND ?? this.maND,
      ngayHoc: ngayHoc ?? this.ngayHoc,
      tgOn: tgOn ?? this.tgOn,
      tgOff: tgOff ?? this.tgOff,
      tgHoc: tgHoc ?? this.tgHoc,
    );
  }

  @override
  String toString() =>
      'NhatKy(maNK: $maNK, maND: $maND, ngayHoc: $ngayHoc, tgHoc: $tgHoc phút)';
}

