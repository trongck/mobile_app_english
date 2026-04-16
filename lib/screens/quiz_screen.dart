import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thêm dòng này
import '../providers/bai_kt_provider.dart';
import '../models/devtalk_model.dart';
import '../datas/repositories/bai_kt_repository.dart';

// --- MÀN HÌNH CHÍNH: DANH SÁCH BÀI THI  ---
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    // Vừa vào màn hình là bảo Provider đi lấy dữ liệu ngay
    Future.microtask(() =>
        context.read<BaiKTProvider>().layDuLieu()
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu từ Provider
    final quizProvider = context.watch<BaiKTProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách bài kiểm tra", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: quizProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : quizProvider.danhSach.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Không có dữ liệu bài thi."),
            ElevatedButton(
              onPressed: () => quizProvider.layDuLieu(),
              child: const Text("Tải lại"),
            )
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: quizProvider.danhSach.length,
        itemBuilder: (context, index) {
          final item = quizProvider.danhSach[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              title: Text(item.tieuDe ?? "Bài thi số ${index + 1}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Thời gian: ${item.tgLamPhut} phút"),

                  // Dòng lịch sử/nhật ký in nghiêng
                  FutureBuilder<LSKiemTra?>(
                    // Gọi hàm lấy nhật ký mới nhất mà mình vừa thêm ở Repository
                    future: LSKiemTraRepository().layLichSuMoiNhat(item.maBKT!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final ls = snapshot.data!;
                        return GestureDetector(
                          onTap: () {
                            // Ấn vào dòng in nghiêng để xem lại bài cũ
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizPlayPage(baiKT: item, historyReview: ls),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Lịch sử: ${ls.diem} điểm - Xem lại",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic, // In nghiêng đúng ý Hạnh
                                color: Colors.blueGrey,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink(); // Nếu chưa làm bài bao giờ thì để trống
                    },
                  ),
                ],
              ),


              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizPlayPage(baiKT: item)),
                  );
                },
                child: const Text("Bắt đầu"),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- MÀN HÌNH PHỤ: GIAO DIỆN LÀM BÀI (Giữ nguyên logic của bạn nhưng bọc thêm SingleChildScrollView) ---
class QuizPlayPage extends StatefulWidget {
  final BaiKT baiKT;
  final LSKiemTra? historyReview;
  const QuizPlayPage({super.key, required this.baiKT, this.historyReview});

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  final CauHoiKTRepository _chRepo = CauHoiKTRepository();
  List<CauHoiKT> _questions = [];
  int _currentIndex = 0;
  Map<int, String> _userAnswers = {};
  final Map<int, TextEditingController> _controllers = {};

  late Timer _timer;
  int _remainingSeconds = 0;
  bool _isLoading = true;

  double _startX = 0.0;
  double _endX = 0.0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.baiKT.tgLamPhut ?? 15) * 60;
    _loadQuestions();
    _startTimer();
  }

  void _loadQuestions() async {
    try {
      if (widget.baiKT.maBKT == null) return;
      final data = await _chRepo.layTheoBai(widget.baiKT.maBKT!);

      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;

          // QUAN TRỌNG: Nếu là xem lại, đổ dữ liệu cũ vào _userAnswers
          if (widget.historyReview != null) {
            widget.historyReview!.cauTraLoi?.forEach((key, value) {
              _userAnswers[int.parse(key)] = value.toString();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        _submit();
      }
    });
  }

  void _showConfirmDialog() {
    // 1. Đếm số câu chưa làm
    int soCauChuaLam = 0;
    for (var q in _questions) {
      if (_userAnswers[q.maCH] == null || _userAnswers[q.maCH]!.isEmpty) {
        soCauChuaLam++;
      }
    }

    // 2. Hiển thị Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Xác nhận nộp bài?"),
        content: Text(soCauChuaLam > 0
            ? "Bạn còn $soCauChuaLam câu chưa chọn. Bạn có chắc chắn muốn nộp bài không?"
            : "Bạn đã hoàn thành tất cả câu hỏi. Nộp bài nhé?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Đóng dialog để làm tiếp
            child: const Text("Làm tiếp", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              _submit(); // Gọi hàm nộp bài chính thức
            },
            child: const Text("Nộp ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _submit() async {
    _timer.cancel();

    // 1. Tính tổng số câu đúng
    int soCauDung = 0;
    for (var q in _questions) {
      String userAns = (_userAnswers[q.maCH] ?? "").trim().toLowerCase();
      String correctAns = (q.dapAn ?? "").trim().toLowerCase();
      if (userAns == correctAns) {
        soCauDung++;
      }
    }

    // 2. Tính điểm theo thang điểm 10
    // Công thức: (Số câu đúng / Tổng số câu) * 10
    double score = (soCauDung / _questions.length) * 10;

    // Làm tròn 1 chữ số thập phân (ví dụ 7.5) hoặc lấy số nguyên tùy Hạnh
    double scoreRounded = double.parse(score.toStringAsFixed(1));

    try {
      final nhatKyMoi = LSKiemTra(
        maND: 1,
        maBKT: widget.baiKT.maBKT!,
        cauTraLoi: _userAnswers.map((k, v) => MapEntry(k.toString(), v)),
        diem: scoreRounded.toInt(), // Nếu model yêu cầu int thì toInt, không thì để double
        tgBatDau: DateTime.now().toIso8601String(),
        tgNopBai: DateTime.now().toIso8601String(),
      );

      await LSKiemTraRepository().luuLichSu(nhatKyMoi);
    } catch (e) {
      debugPrint("❌ Lỗi: $e");
    }

    // 3. Hiển thị thông báo (Sửa lại Text hiển thị)
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Kết quả"),
        content: Text("Bạn đúng $soCauDung/${_questions.length} câu.\nĐiểm số: $scoreRounded"),
        actions: [
          TextButton(
              onPressed: () async {
                await context.read<BaiKTProvider>().layDuLieu();
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Hoàn thành")
          )
        ],
      ),
    );
  }
  @override
  void dispose() {
    _timer.cancel();
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text("Bài thi này chưa có câu hỏi!")));

    final q = _questions[_currentIndex];

    // 1. Xác định loại câu hỏi
    bool isFillInBlank = (q.luaChon == null || (q.luaChon as List).isEmpty);

    // 2. Khởi tạo Controller cho câu điền khuyết (QUAN TRỌNG: để không bị giật khi gõ)
    if (isFillInBlank && q.maCH != null && !_controllers.containsKey(q.maCH)) {
      _controllers[q.maCH!] = TextEditingController(text: _userAnswers[q.maCH] ?? "");
    }

    Map<String, dynamic> options = {};
    if (q.luaChon != null && q.luaChon is List) {
      for (var item in (q.luaChon as List)) {
        if (item is Map) {
          options.addAll(Map<String, dynamic>.from(item));
        }
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.historyReview != null
            ? "Xem lại bài"
            : "Còn lại: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}"),
        backgroundColor: Colors.orangeAccent,
      ),
      // --- BẮT ĐẦU PHẦN VUỐT MÀN HÌNH ---
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) {
          _startX = details.globalPosition.dx; // Lưu điểm bắt đầu chạm
        },
        onHorizontalDragUpdate: (details) {
          _endX = details.globalPosition.dx; // Cập nhật vị trí khi đang kéo
        },
        onHorizontalDragEnd: (details) {
          // Khi nhấc tay lên, tính toán quãng đường vuốt
          double distance = _startX - _endX;
          if (distance.abs() > 50) { // Nếu vuốt trên 50 pixel mới nhận lệnh
            if (distance > 0) {
              // Vuốt sang trái -> Tiếp theo
              if (_currentIndex < _questions.length - 1) {
                setState(() => _currentIndex++);
              }
            } else {
              // Vuốt sang phải -> Quay lại
              if (_currentIndex > 0) {
                setState(() => _currentIndex--);
              }
            }
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Hiển thị số câu hỏi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Câu ${_currentIndex + 1} / ${_questions.length}",
                    style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Nội dung câu hỏi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    q.noiDung ?? "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white, // Đã sửa từ trắng sang đen để dễ nhìn
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // --- DANH SÁCH LỰA CHỌN ---

                isFillInBlank
                    ? Column(
                  children: [
                    TextField(
                      controller: _controllers[q.maCH],
                      enabled: widget.historyReview == null,
                      style: const TextStyle(color: Colors.black), // Chữ đen cho dễ nhìn
                      decoration: InputDecoration(
                        hintText: "Nhập đáp án của bạn...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        // --- ĐÂY LÀ DẤU X ---
                        suffixIcon: (widget.historyReview == null && _controllers[q.maCH]!.text.isNotEmpty)
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _controllers[q.maCH]!.clear(); // Xóa trên giao diện
                              _userAnswers[q.maCH!] = "";     // Xóa trong dữ liệu lưu trữ
                            });
                          },
                        )
                            : null,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                        onChanged: (val) {
                          setState(() {
                            _userAnswers[q.maCH!] = val;
                          });
                        },

                    ),
                    if (widget.historyReview != null)
                      Container(
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Text("Đáp án đúng: ${q.dapAn}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                )
                    : Column(
                  children: options.entries.map((e) {
                    String optionKey = e.key;
                    String? userAnswer;
                    if (widget.historyReview != null) {
                      userAnswer = widget.historyReview!.cauTraLoi?[q.maCH.toString()];
                    } else {
                      userAnswer = _userAnswers[q.maCH];
                    }

                    String correctAnswer = q.dapAn ?? "";
                    bool isSelected = (userAnswer == optionKey);

                    Color itemColor = isSelected ? Colors.blue[50]! : Colors.grey[50]!;
                    Color borderColor = isSelected ? Colors.blue : Colors.grey[300]!;
                    Color titleColor = isSelected ? Colors.blue[800]! : Colors.black87;
                    FontWeight titleWeight = isSelected ? FontWeight.bold : FontWeight.w500;

                    if (widget.historyReview != null) {
                      if (optionKey == correctAnswer) {
                        itemColor = Colors.green[500]!;
                        borderColor = Colors.green[700]!;
                        titleColor = Colors.white;
                        titleWeight = FontWeight.w900;
                      } else if (optionKey == userAnswer && userAnswer != correctAnswer) {
                        itemColor = Colors.red[500]!;
                        borderColor = Colors.red[700]!;
                        titleColor = Colors.white;
                        titleWeight = FontWeight.w900;
                      } else {
                        itemColor = Colors.grey[100]!;
                        titleColor = Colors.black54;
                      }
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: borderColor, width: 2.5),
                      ),
                      child: RadioListTile<String>(
                        title: Text("${e.key}. ${e.value}",
                            style: TextStyle(fontSize: 17, fontWeight: titleWeight, color: titleColor)),
                        value: optionKey,
                        groupValue: userAnswer,
                        activeColor: widget.historyReview != null ? Colors.transparent : Colors.blue,
                        onChanged: widget.historyReview != null ? null : (val) {
                          if (val != null) setState(() => _userAnswers[q.maCH!] = val);
                        },
                      ),
                    );
                  }).toList(),
                ),
                // --- GIẢI THÍCH ---
                if (widget.historyReview != null && q.giaiThich != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_circle, color: Colors.orange[700], size: 24),
                            const SizedBox(width: 8),
                            const Text("Giải thích đáp án:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(q.giaiThich!, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black)),
                      ],
                    ),
                  ),

                const SizedBox(height: 35),

                // --- HÀNG NÚT ĐIỀU HƯỚNG ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      IconButton(
                        onPressed: () => setState(() => _currentIndex--),
                        icon: const Icon(Icons.arrow_back_ios),
                        style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
                      )
                    else
                      const SizedBox(width: 48),

                    if (widget.historyReview != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => QuizPlayPage(baiKT: widget.baiKT)),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Làm lại"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex == _questions.length - 1 ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_currentIndex < _questions.length - 1) {
                          setState(() => _currentIndex++);
                        } else {
                          // Nếu đang ở câu cuối cùng
                          if (widget.historyReview != null) {
                            Navigator.pop(context); // Nếu là xem lại thì thoát luôn
                          } else {
                            _showConfirmDialog(); // Nếu là đang làm bài thì hiện thông báo hỏi
                          }
                        }
                      },
                      child: Text(_currentIndex == _questions.length - 1
                          ? (widget.historyReview != null ? "Hoàn thành" : "Nộp bài")
                          : "Tiếp theo"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}