import '../DB_helper.dart';
import '../../models/devtalk_model.dart';

/// Repository quản lý chủ đề từ vựng (bảng cdtuvung).
class CDTuVungRepository {
  final supabase = DBHelper.client;

  /// Lấy danh sách tất cả các chủ đề từ vựng.
  Future<List<CDTuVung>> layTatCa() async {
    final response = await supabase
        .from('cdtuvung')
        .select()
        .order('tencd', ascending: true);
    return response.map((r) => CDTuVung.fromMap(r)).toList();
  }
}

/// Repository quản lý thông tin từ vựng chi tiết (bảng tuvung).
class TuVungRepository {
  final supabase = DBHelper.client;

  /// Lấy danh sách toàn bộ từ vựng, sắp xếp theo thứ tự bảng chữ cái.
  Future<List<TuVung>> layTatCa() async {
    final response = await supabase
        .from('tuvung')
        .select()
        .order('tu', ascending: true);
    return response.map((r) => TuVung.fromMap(r)).toList();
  }

  /// Lấy danh sách từ vựng thuộc về một chủ đề cụ thể (maCD).
  Future<List<TuVung>> layTheoChuDe(int maCD) async {
    final response = await supabase
        .from('tuvung')
        .select()
        .eq('macd', maCD)
        .order('tu', ascending: true);
    return response.map((r) => TuVung.fromMap(r)).toList();
  }
}

/// Repository quản lý trạng thái tương tác từ vựng của cá nhân người dùng (bảng nguoidung_tuvung - yêu thích/đã học).
class NguoiDungTuVungRepository {
  final supabase = DBHelper.client;

  /// Thêm hoặc cập nhật trạng thái học tập (yêu thích/đã học) của người dùng đối với một từ vựng.
  Future<void> upsert(NguoiDungTuVung record) async {
    await supabase
        .from('nguoidung_tuvung')
        .upsert(record.toMap(), onConflict: 'mand,matu');
  }

  /// Lấy danh sách các từ vựng đã được người dùng đánh dấu là yêu thích.
  Future<List<NguoiDungTuVung>> layYeuThich(int maND) async {
    final response = await supabase
        .from('nguoidung_tuvung')
        .select()
        .eq('mand', maND)
        .eq('yeuthich', true);
    return response.map((r) => NguoiDungTuVung.fromMap(r)).toList();
  }

  /// Lấy danh sách các từ vựng đã được người dùng đánh dấu là đã học.
  Future<List<NguoiDungTuVung>> layDaHoc(int maND) async {
    final response = await supabase
        .from('nguoidung_tuvung')
        .select()
        .eq('mand', maND)
        .eq('dahoc', true);
    return response.map((r) => NguoiDungTuVung.fromMap(r)).toList();
  }
}
