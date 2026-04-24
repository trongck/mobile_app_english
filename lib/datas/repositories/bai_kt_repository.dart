import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

class BaiKTRepository {
  final supabase = Supabase.instance.client;
  
  Future<int> them(BaiKT bkt) async {
    final response = await supabase
        .from('baikt')
        .insert(bkt.toMap())
        .select('mabkt'); // Đã sửa
    return response.first['mabkt'] as int;
  }

  Future<List<BaiKT>> layTatCa() async {
    final response = await supabase
        .from('baikt')
        .select()
        .order('mabkt', ascending: false); // Đã sửa
    return response.map((r) => BaiKT.fromMap(r)).toList();
  }

  Future<BaiKT?> layTheoId(int maBKT) async {
    final response = await supabase
        .from('baikt')
        .select()
        .eq('mabkt', maBKT) // Đã sửa
        .limit(1);

    if (response.isEmpty) return null;
    return BaiKT.fromMap(response.first);
  }

  Future<int> xoa(int maBKT) async {
    await supabase.from('baikt').delete().eq('mabkt', maBKT);
    return 1;
  }
}

class CauHoiKTRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(CauHoiKT ch) async {
    final response = await supabase
        .from('cauhoikt')
        .insert(ch.toMap())
        .select('mach');
    return response.first['mach'] as int;
  }

  Future<List<CauHoiKT>> layTheoBai(int maBKT) async {
    final response = await supabase
        .from('cauhoikt')
        .select()
        .eq('mabkt', maBKT)
        .order('thutu', ascending: true);
    return response.map((r) => CauHoiKT.fromMap(r)).toList();
  }

  Future<int> xoa(int maCH) async {
    await supabase.from('cauhoikt').delete().eq('mach', maCH);
    return 1;
  }
}

class LSKiemTraRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(LSKiemTra ls) async {
    final response = await supabase
        .from('lskiemtra')
        .insert(ls.toMap())
        .select('mals');
    return response.first['mals'] as int;
  }

  Future<List<LSKiemTra>> layTheoND(int maND) async {
    final response = await supabase
        .from('lskiemtra')
        .select()
        .eq('mand', maND)
        .order('tgbatdau', ascending: false);
    return response.map((r) => LSKiemTra.fromMap(r)).toList();
  }

  Future<LSKiemTra?> layTheoId(int maLS) async {
    final response = await supabase
        .from('lskiemtra')
        .select()
        .eq('mals', maLS)
        .limit(1);
    if (response.isEmpty) return null;
    return LSKiemTra.fromMap(response.first);
  }

  Future<int> capNhatDiem(int maLS, int diem, int tgLam, String tgNopBai) async {
    await supabase
        .from('lskiemtra')
        .update({'diem': diem, 'tglam': tgLam, 'tgnopbai': tgNopBai}) // Đã sửa
        .eq('mals', maLS);
    return 1;
  }
}