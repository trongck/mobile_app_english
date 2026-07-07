import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lớp hỗ trợ quản lý kết nối cơ sở dữ liệu Supabase của ứng dụng.
class DBHelper {
  /// Lấy instance của SupabaseClient để tương tác với cơ sở dữ liệu.
  static SupabaseClient get client => Supabase.instance.client;

  /// Khởi tạo kết nối tới Supabase sử dụng các cấu hình từ file môi trường (.env).
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (url == null || anonKey == null) {
      throw Exception('Không tìm thấy cấu hình SUPABASE_URL hoặc SUPABASE_ANON_KEY trong file .env.local');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
