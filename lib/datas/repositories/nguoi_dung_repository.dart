import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

class NguoiDungRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(NguoiDung nd) async {
    final response = await supabase
        .from('nguoidung')
        .insert(nd.toMap())
        .select('mand'); 
    
    return response.first['mand'] as int;
  }

  Future<NguoiDung?> layTheoId(int maND) async {
    final response = await supabase
        .from('nguoidung')
        .select()
        .eq('mand', maND) 
        .limit(1);

    if (response.isEmpty) return null;
    return NguoiDung.fromMap(response.first);
  }

  Future<NguoiDung?> layTheoEmail(String email) async {
    final response = await supabase
        .from('nguoidung')
        .select()
        .eq('email', email) 
        .limit(1);
        
    if (response.isEmpty) return null;
    return NguoiDung.fromMap(response.first);
  }

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
  
  Future<int> capNhatMatKhau(int maND, String matKhauMoi) async {
    final response = await supabase
        .from('nguoidung')
        .update({'matkhau': matKhauMoi}) 
        .eq('mand', maND);
    return response != null ? 1 : 0; 
  }
  Future<void> capNhatXacMinhEmail(int maND, bool isVerified) async {
    
    await supabase.from('nguoidung').update({
      'xacminhemail': isVerified ? 1 : 0, 
    }).eq('mand', maND);
  }
  Future<int> xoa(int maND) async {
    await supabase
        .from('nguoidung')
        .delete()
        .eq('mand', maND);
    return 1;
  }
}