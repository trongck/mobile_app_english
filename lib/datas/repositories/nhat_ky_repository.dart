import '../DB_helper.dart';
import '../../models/devtalk_model.dart';

/// Repository quản lý nhật ký học tập (thời lượng học hàng ngày) của người dùng.
class NhatKyRepository {
  final supabase = DBHelper.client;

  /// Thêm bản ghi nhật ký học tập mới.
  Future<int> them(NhatKy nk) async {
    final response = await supabase
        .from('nhatky')
        .insert(nk.toMap())
        .select('mank');
    return response.first['mank'] as int;
  }

  /// Lấy toàn bộ danh sách nhật ký học tập của một người dùng theo mã người dùng (maND).
  Future<List<NhatKy>> layTheoND(int maND) async {
    final response = await supabase
        .from('nhatky')
        .select()
        .eq('mand', maND)
        .order('ngayhoc', ascending: false);
    return response.map((r) => NhatKy.fromMap(r)).toList();
  }

  /// Lấy bản ghi nhật ký của một ngày cụ thể (định dạng 'yyyy-MM-dd').
  Future<NhatKy?> layTheoNgay(int maND, String ngayHoc) async {
    final response = await supabase
        .from('nhatky')
        .select()
        .eq('mand', maND)
        .eq('ngayhoc', ngayHoc)
        .limit(1);

    if (response.isEmpty) return null;
    return NhatKy.fromMap(response.first);
  }

  /// Lấy danh sách nhật ký trong khoảng thời gian xác định (từ ngày... đến ngày...).
  Future<List<NhatKy>> layTheoKhoang(int maND, String tuNgay, String denNgay) async {
    final response = await supabase
        .from('nhatky')
        .select()
        .eq('mand', maND)
        .gte('ngayhoc', tuNgay)
        .lte('ngayhoc', denNgay)
        .order('ngayhoc', ascending: true);
    return response.map((r) => NhatKy.fromMap(r)).toList();
  }

  /// Cập nhật thời gian học và các thông số liên quan của một bản ghi nhật ký.
  Future<int> capNhat(NhatKy nk) async {
    final response = await supabase
        .from('nhatky')
        .update(nk.toMap())
        .eq('mank', nk.maNK as int)
        .select(); 
    return response.length;
  }
}