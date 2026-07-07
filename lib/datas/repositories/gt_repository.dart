import '../DB_helper.dart';
import '../../models/devtalk_model.dart';

/// Repository quản lý dữ liệu giới thiệu (intro/tutorial) của ứng dụng.
class GTRepository {
  final supabase = DBHelper.client;

  /// Lấy danh sách các trang giới thiệu, sắp xếp theo thứ tự hiển thị (tt).
  Future<List<GT>> layDanhSachIntro() async {
    final response = await supabase
        .from('gt')
        .select()
        .order('tt', ascending: true);
        
    return response.map((r) => GT.fromMap(r)).toList();
  }
}