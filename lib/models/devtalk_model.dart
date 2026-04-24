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
      if (maGT != null) 'magt': maGT,
      'phienban': phienBan,
      'tt': tt,
      'tieude': tieuDe,
      'mota': moTa,
      'anh': anh,
    };
  }

  factory GT.fromMap(Map<String, dynamic> map) {
    return GT(
      maGT: map['magt'] as int?,
      phienBan: map['phienban'] as String? ?? '1.0',
      tt: map['tt'] as int,
      tieuDe: map['tieude'] as String,
      moTa: map['mota'] as String?,
      anh: map['anh'] as String?,
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
      if (maND != null) 'mand': maND,
      'email': email,
      'matkhau': matKhau,
      'hoten': hoTen,
      'ngaysinh': ngaySinh,
      'trinhdo': trinhDo,
      'muctieucapdo': mucTieuCapDo,
      'hocvi': hocVi,
      'muctieuphut': mucTieuPhut,
      'xacminhemail': xacMinhEmail ? 1 : 0,
      'ngaytao': ngayTao,
    };
  }

  factory NguoiDung.fromMap(Map<String, dynamic> map) {
    return NguoiDung(
      maND: map['mand'] as int?,
      email: map['email'] as String,
      matKhau: map['matkhau'] as String,
      hoTen: map['hoten'] as String?,
      ngaySinh: map['ngaysinh'] as String?,
      trinhDo: map['trinhdo'] as String? ?? 'A1',
      mucTieuCapDo: map['muctieucapdo'] as String? ?? 'A2',
      hocVi: map['hocvi'] as String?,
      mucTieuPhut: map['muctieuphut'] as int? ?? 15,
      xacMinhEmail: (map['xacminhemail'] as int? ?? 0) == 1,
      ngayTao: map['ngaytao'] as String?,
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
      if (maCD != null) 'macd': maCD,
      'tencd': tenCD,
    };
  }

  factory CDTuVung.fromMap(Map<String, dynamic> map) {
    return CDTuVung(
      maCD: map['macd'] as int?,
      tenCD: map['tencd'] as String,
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
      if (maTu != null) 'matu': maTu,
      'tu': tu,
      'phienam': phienAm,
      'amthanh': amThanh,
      'nghiaen': nghiaEN,
      'nghiavi': nghiaVI,
      'vden': vdEN,
      'vdvi': vdVI,
      'tuloai': tuLoai,
      'macd': maCD,
      'yeuthich': yeuThich ? 1 : 0,
    };
  }

  factory TuVung.fromMap(Map<String, dynamic> map) {
    return TuVung(
      maTu: map['matu'] as int?,
      tu: map['tu'] as String,
      phienAm: map['phienam'] as String?,
      amThanh: map['amthanh'] as String?,
      nghiaEN: map['nghiaen'] as String,
      nghiaVI: map['nghiavi'] as String?,
      vdEN: map['vden'] as String?,
      vdVI: map['vdvi'] as String?,
      tuLoai: map['tuloai'] as String?,
      maCD: map['macd'] as int?,
     
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
      
    );
  }

  @override
  String toString() =>
      'TuVung(maTu: $maTu, tu: $tu, nghiaEN: $nghiaEN)';
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
      if (maBKT != null) 'mabkt': maBKT,
      'tieude': tieuDe,
      'tglamphut': tgLamPhut,
      'tongdiem': tongDiem,
    };
  }

  factory BaiKT.fromMap(Map<String, dynamic> map) {
    return BaiKT(
      maBKT: map['mabkt'] as int?,
      tieuDe: map['tieude'] as String,
      tgLamPhut: map['tglamphut'] as int?,
      tongDiem: map['tongdiem'] as int? ?? 100,
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
      if (maCH != null) 'mach': maCH,
      'mabkt': maBKT,
      'loai': loai,
      'noidung': noiDung,
      'luachon': luaChon != null ? jsonEncode(luaChon) : null,
      'dapan': dapAn,
      'giaithich': giaiThich,
      'trongso': trongSo,
      'thutu': thuTu,
    };
  }

  factory CauHoiKT.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>>? luaChon;
    if (map['luachon'] != null) {
      final decoded = jsonDecode(map['luachon'] as String);
      luaChon = List<Map<String, dynamic>>.from(decoded);
    }
    return CauHoiKT(
      maCH: map['mach'] as int?,
      maBKT: map['mabkt'] as int,
      loai: map['loai'] as String,
      noiDung: map['noidung'] as String,
      luaChon: luaChon,
      dapAn: map['dapan'] as String,
      giaiThich: map['giaithich'] as String?,
      trongSo: map['trongso'] as int? ?? 1,
      thuTu: map['thutu'] as int? ?? 0,
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
      if (maLS != null) 'mals': maLS,
      'mand': maND,
      'mabkt': maBKT,
      'cautraloi': jsonEncode(cauTraLoi),
      'diem': diem,
      'tglam': tgLam,
      'tgbatdau': tgBatDau,
      'tgnopbai': tgNopBai,
    };
  }

  factory LSKiemTra.fromMap(Map<String, dynamic> map) {
    return LSKiemTra(
      maLS: map['mals'] as int?,
      maND: map['mand'] as int,
      maBKT: map['mabkt'] as int,
      cauTraLoi: Map<String, dynamic>.from(
          jsonDecode(map['cautraloi'] as String)),
      diem: map['diem'] as int?,
      tgLam: map['tglam'] as int?,
      tgBatDau: map['tgbatdau'] as String?,
      tgNopBai: map['tgnopbai'] as String?,
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
      if (maNK != null) 'mank': maNK,
      'mand': maND,
      'ngayhoc': ngayHoc,
      'tgon': tgOn,
      'tgoff': tgOff,
      'tghoc': tgHoc,
    };
  }

  factory NhatKy.fromMap(Map<String, dynamic> map) {
    return NhatKy(
      maNK: map['mank'] as int?,
      maND: map['mand'] as int,
      ngayHoc: map['ngayhoc'] as String,
      tgOn: map['tgon'] as String,
      tgOff: map['tgoff'] as String,
      tgHoc: map['tghoc'] as int,
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

class XacThucEmail {
  final String email;
  final String maOTP;
  final String thoiGianHetHan; // Lưu dạng ISO8601 string

  XacThucEmail({
    required this.email,
    required this.maOTP,
    required this.thoiGianHetHan,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'maotp': maOTP,
      'thoigianhethan': thoiGianHetHan,
    };
  }

  factory XacThucEmail.fromMap(Map<String, dynamic> map) {
    return XacThucEmail(
      email: map['email'] as String,
      maOTP: map['maotp'] as String,
      thoiGianHetHan: map['thoigianhethan'] as String,
    );
  }

  XacThucEmail copyWith({
    String? email,
    String? maOTP,
    String? thoiGianHetHan,
  }) {
    return XacThucEmail(
      email: email ?? this.email,
      maOTP: maOTP ?? this.maOTP,
      thoiGianHetHan: thoiGianHetHan ?? this.thoiGianHetHan,
    );
  }

  @override
  String toString() =>
      'XacThucEmail(email: $email, maOTP: $maOTP, thoiGianHetHan: $thoiGianHetHan)';
}


class NguoiDungTuVung {
  final int maND;
  final int maTu;
  final bool daHoc;
  final bool yeuThich;

  NguoiDungTuVung({
    required this.maND,
    required this.maTu,
    this.daHoc = false,
    this.yeuThich = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'mand': maND,
      'matu': maTu,
      'dahoc': daHoc ? 1 : 0,
      'yeuthich': yeuThich ? 1 : 0,
    };
  }

  factory NguoiDungTuVung.fromMap(Map<String, dynamic> map) {
    return NguoiDungTuVung(
      maND: map['mand'] as int,
      maTu: map['matu'] as int,
      daHoc: (map['dahoc'] as int? ?? 0) == 1,
      yeuThich: (map['yeuthich'] as int? ?? 0) == 1,
    );
  }

  NguoiDungTuVung copyWith({
    int? maND,
    int? maTu,
    bool? daHoc,
    bool? yeuThich,
  }) {
    return NguoiDungTuVung(
      maND: maND ?? this.maND,
      maTu: maTu ?? this.maTu,
      daHoc: daHoc ?? this.daHoc,
      yeuThich: yeuThich ?? this.yeuThich,
    );
  }

  @override
  String toString() =>
      'NguoiDungTuVung(maND: $maND, maTu: $maTu, daHoc: $daHoc, yeuThich: $yeuThich)';
}