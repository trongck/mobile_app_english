import '../database_helper.dart';
import '../../models/devtalk_model.dart';

class GTRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // Lấy toàn bộ danh sách Intro, sắp xếp theo thứ tự (TT)
  Future<List<GT>> layDanhSachIntro() async {
    final db = await _db.database;
    final rows = await db.query(
      'GT',
      orderBy: 'TT ASC', // Sắp xếp từ trang 1 đến 4
    );
    return rows.map((r) => GT.fromMap(r)).toList();
  }

  // Nạp dữ liệu gốc cho Intro (chạy 1 lần duy nhất)
  Future<void> kiemTraVaNapDuLieuGoc() async {
    final db = await _db.database;
    
    // Kiểm tra xem bảng GT đã có dữ liệu chưa
    final existingData = await db.query('GT', limit: 1);
    
    // Nếu bảng trống, tiến hành nạp dữ liệu cứng
    if (existingData.isEmpty) {
      final listIntro = [
        GT(
          tt: 1,
          tieuDe: 'Dừng học vẹt! DevTalk English mang ngữ cảnh dự án thực tế vào từng từ vựng.',
          moTa: 'Học tiếng Anh chuyên ngành IT chưa bao giờ thực tế đến thế. Chúng tôi không chỉ dạy từ vựng lẻ tẻ. Chúng tôi tích hợp 3.000+ từ cốt lõi vào các tình huống thực tế mà bạn gặp hàng ngày.',
          anh: 'assets/images/intro1.png',
        ),
        GT(
          tt: 2,
          tieuDe: 'Tự tin chinh phục thị trường IT quốc tế với DevTalk English.',
          moTa: 'Rào cản ngôn ngữ đang ngăn bạn thăng tiến? Đừng để tiếng Anh là điểm yếu lớn nhất của bạn. Với DevTalk English, bạn sẽ nắm chuyên ngành Lập trình, Cloud, AI và DevOps – chìa khóa để tự tin giao tiếp, phỏng vấn và làm việc trong các tập đoàn đa quốc gia.',
          anh: 'assets/images/intro2.png',
        ),
        GT(
          tt: 3,
          tieuDe: 'Lộ trình học tiếng Anh chuyên ngành IT khoa học và toàn diện nhất.',
          moTa: 'Mệt mỏi với việc tìm kiếm từ vựng lẻ tẻ trên mạng? DevTalk English cung cấp hệ thống từ vựng chuyên ngành IT được phân loại rõ ràng và khoa học theo 4 trụ cột công nghệ hiện đại: Programming, Cloud, AI, và DevOps. Học một lần, hiểu sâu sắc ngữ cảnh và bao quát toàn bộ kiến thức cần thiết.',
          anh: 'assets/images/intro3.png',
        ),
        GT(
          tt: 4,
          tieuDe: 'Học tiếng Anh IT dễ dàng hơn bao giờ hết',
          moTa: 'DevTalk English mang đến trải nghiệm học tập trực quan, dễ hiểu với các bài học ngắn gọn, thực tế và phù hợp cho mọi cấp độ lập trình viên.',
          anh: 'assets/images/intro4.png',
        ),
      ];

      final batch = db.batch();
      for (var gt in listIntro) {
        batch.insert('GT', gt.toMap());
      }
      await batch.commit(noResult: true);
    }
  }
}