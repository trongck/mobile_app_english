import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

/// Repository quản lý thông tin người dùng trong cơ sở dữ liệu Supabase.
class NguoiDungRepository {
  final supabase = Supabase.instance.client;

  /// Thêm người dùng mới vào hệ thống. Trả về mã người dùng (maND) vừa tạo.
  Future<int> them(NguoiDung nd) async {
    String hashedPass = nd.matKhau;
    if (nd.matKhau.isNotEmpty) {
      final responseHash = await supabase.rpc('hash_password', params: {'password': nd.matKhau});
      hashedPass = responseHash.toString();
    }
    
    final ndMap = nd.toMap();
    ndMap['matkhau'] = hashedPass;

    final response = await supabase
        .from('nguoidung')
        .insert(ndMap)
        .select('mand'); 
    
    return response.first['mand'] as int;
  }

  /// Lấy thông tin người dùng dựa vào mã ID (maND).
  Future<NguoiDung?> layTheoId(int maND) async {
    final response = await supabase
        .from('nguoidung')
        .select()
        .eq('mand', maND) 
        .limit(1);

    if (response.isEmpty) return null;
    return NguoiDung.fromMap(response.first);
  }

  /// Lấy thông tin người dùng dựa vào Email đăng nhập.
  Future<NguoiDung?> layTheoEmail(String email) async {
    final response = await supabase
        .from('nguoidung')
        .select()
        .eq('email', email) 
        .limit(1);
        
    if (response.isEmpty) return null;
    return NguoiDung.fromMap(response.first);
  }

  /// Cập nhật thông tin hồ sơ của người dùng (tên, ngày sinh, trình độ, mục tiêu...).
  Future<int> capNhat(NguoiDung nd) async {
    if (nd.maND == null) {
      throw ArgumentError("MaND cannot be null");
    }
    await supabase
        .from('nguoidung')
        .update(nd.toMap())
        .eq('mand', nd.maND!); 
    return 1;
  }

  /// Kiểm tra mật khẩu có chính xác không bằng hàm verify_password trong database.
  Future<bool> kiemTraMatKhau(String matKhauNhap, String matKhauDaLuu) async {
    try {
      final response = await supabase.rpc('verify_password', params: {
        'input_password': matKhauNhap,
        'hashed_password': matKhauDaLuu,
      });
      return response as bool;
    } catch (e) {
      // Fallback nếu hàm băm chưa được cài đặt hoặc lỗi
      return matKhauNhap == matKhauDaLuu;
    }
  }

  /// Cập nhật trạng thái xác minh email của người dùng.
  Future<void> capNhatXacMinhEmail(int maND, bool isVerified) async {
    await supabase.from('nguoidung').update({
      'xacminhemail': isVerified ? 1 : 0, 
    }).eq('mand', maND);
  }

}