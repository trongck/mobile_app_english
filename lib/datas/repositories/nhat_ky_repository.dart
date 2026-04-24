import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

class NhatKyRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(NhatKy nk) async {
    final response = await supabase
        .from('nhatky')
        .insert(nk.toMap())
        .select('mank');
    return response.first['mank'] as int;
  }

  Future<List<NhatKy>> layTheoND(int maND) async {
    final response = await supabase
        .from('nhatky')
        .select()
        .eq('mand', maND)
        .order('ngayhoc', ascending: false);
    return response.map((r) => NhatKy.fromMap(r)).toList();
  }

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

 Future<int> capNhat(NhatKy nk) async {
    final response = await supabase
        .from('nhatky')
        .update(nk.toMap())
        .eq('mank', nk.maNK as int)
        .select(); 
    return response.length;
  }

  Future<int> tongPhutTheoThang(int maND, String thang) async {
    final response = await supabase
        .from('nhatky')
        .select('tghoc')
        .eq('mand', maND)
        .like('ngayhoc', '$thang%');

    int tong = 0;
    for (var row in response) {
      tong += row['tghoc'] as int;
    }
    return tong;
  }

  Future<int> xoa(int maNK) async {
    await supabase.from('nhatky').delete().eq('mank', maNK);
    return 1;
  }
}