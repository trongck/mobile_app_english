import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/devtalk_model.dart';

class GTRepository {
  final supabase = Supabase.instance.client;

  Future<List<GT>> layDanhSachIntro() async {
    final response = await supabase
        .from('gt')
        .select()
        .order('tt', ascending: true); // Đã sửa TT thành tt
        
    return response.map((r) => GT.fromMap(r)).toList();
  }

  Future<void> kiemTraVaNapDuLieuGoc() async {
    return;
  }
}