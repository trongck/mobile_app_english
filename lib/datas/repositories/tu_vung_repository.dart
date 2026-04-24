import "package:supabase_flutter/supabase_flutter.dart";
import '../../models/devtalk_model.dart';

class CDTuVungRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(CDTuVung cd) async {
    final response = await supabase
        .from('cdtuvung')
        .insert(cd.toMap())
        .select('macd');
    return response.first['macd'] as int;
  }

  Future<List<CDTuVung>> layTatCa() async {
    final response = await supabase
        .from('cdtuvung')
        .select()
        .order('tencd', ascending: true);
    return response.map((r) => CDTuVung.fromMap(r)).toList();
  }

  Future<int> xoa(int maCD) async {
    await supabase.from('cdtuvung').delete().eq('macd', maCD);
    return 1;
  }
}

class TuVungRepository {
  final supabase = Supabase.instance.client;

  Future<int> them(TuVung tv) async {
    final response = await supabase
        .from('tuvung')
        .insert(tv.toMap())
        .select('matu');
    return response.first['matu'] as int;
  }

  Future<List<TuVung>> layTheoChuDe(int maCD) async {
    final response = await supabase
        .from('tuvung')
        .select()
        .eq('macd', maCD);
    return response.map((r) => TuVung.fromMap(r)).toList();
  }

  Future<List<TuVung>> layYeuThich() async {
    final response = await supabase
        .from('tuvung')
        .select()
        .eq('yeuthich', true);
    return response.map((r) => TuVung.fromMap(r)).toList();
  }

  Future<int> capNhatYeuThich(int maTu, bool yeuThich) async {
    final response = await supabase
        .from('tuvung')
        .update({'yeuthich': yeuThich})
        .eq('matu', maTu)
        .select();
    return response.length;
  }

  Future<int> capNhat(TuVung tv) async {
    final response = await supabase
        .from('tuvung')
        .update(tv.toMap())
        .eq('matu', tv.maTu as int)
        .select();
    return response.length;
  }

  Future<int> xoa(int maTu) async {
    await supabase.from('tuvung').delete().eq('matu', maTu);
    return 1;
  }
}