import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

/// Repository quản lý thông tin các bài kiểm tra (đề thi).
class BaiKTRepository {
  final supabase = Supabase.instance.client;

  /// Lấy danh sách tất cả các bài kiểm tra hiện có.
  Future<List<BaiKT>> layTatCa() async {
    final response = await supabase
        .from('baikt')
        .select()
        .order('mabkt', ascending: false);
    return response.map((r) => BaiKT.fromMap(r)).toList();
  }
}

/// Repository quản lý câu hỏi trong bài kiểm tra.
class CauHoiKTRepository {
  final supabase = Supabase.instance.client;

  /// Lấy danh sách câu hỏi của một bài kiểm tra theo mã bài kiểm tra (maBKT).
  Future<List<CauHoiKT>> layTheoBai(int maBKT) async {
    final response = await supabase
        .from('cauhoikt')
        .select()
        .eq('mabkt', maBKT)
        .order('thutu', ascending: true);
    return response.map((r) => CauHoiKT.fromMap(r)).toList();
  }
}

/// Repository quản lý lịch sử làm bài kiểm tra của người dùng.
class LSKiemTraRepository {
  final supabase = Supabase.instance.client;

  /// Lưu lượt làm bài kiểm tra mới.
  Future<int> them(LSKiemTra ls) async {
    final response = await supabase
        .from('lskiemtra')
        .insert(ls.toMap())
        .select('mals');
    return response.first['mals'] as int;
  }

  /// Lấy lịch sử làm bài kiểm tra của một người dùng theo mã người dùng (maND).
  Future<List<LSKiemTra>> layTheoND(int maND) async {
    final response = await supabase
        .from('lskiemtra')
        .select()
        .eq('mand', maND)
        .order('tgbatdau', ascending: false);
    return response.map((r) => LSKiemTra.fromMap(r)).toList();
  }
}