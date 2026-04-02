import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bai_kt_provider.dart';
import 'dart:async';
import 'dart:convert';

class QuizScreen extends StatefulWidget {
  final int maND; // Mã người dùng
  const QuizScreen({super.key, required this.maND});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int selectedBai = 0;
  int currentIndex = 0;
  Timer? countdownTimer;
  int remainingTime = 0; // giây

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BaiKTProvider>(context, listen: false);
      provider.loadBaiKT();
      provider.loadLichSu(widget.maND);
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startQuiz(int maBKT, int tgLamPhut, int baiIndex) async {
    final provider = Provider.of<BaiKTProvider>(context, listen: false);
    await provider.loadCauHoi(maBKT);
    if (!mounted) return;

    setState(() {
      currentIndex = 0;
      remainingTime = tgLamPhut * 60;
      selectedBai = baiIndex; // cập nhật bài đang làm
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        remainingTime--;
      });
      if (remainingTime <= 0) {
        submitQuiz(maBKT);
      }
    });
  }

  void submitQuiz(int maBKT) async {
    countdownTimer?.cancel();
    final provider = Provider.of<BaiKTProvider>(context, listen: false);

    // Thời gian làm = tgLamPhut - remainingTime
    final tgLam = provider.cauHoiList.isNotEmpty ? provider.cauHoiList.length * 10 : 0;

    await provider.nopBai(
      maND: widget.maND,
      maBKT: maBKT,
      tgLam: tgLam,
      tgBatDau: DateTime.now().subtract(Duration(seconds: remainingTime)),
    );

    await provider.loadLichSu(widget.maND);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hoàn thành"),
        content: const Text("Bài kiểm tra đã được nộp!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: Consumer<BaiKTProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Danh sách bài kiểm tra",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.baiKTList.length,
                  itemBuilder: (context, index) {
                    final bai = provider.baiKTList[index];
                    return ListTile(
                      title: Text(bai['TieuDe']),
                      subtitle: Text("Thời gian: ${bai['TgLamPhut']} phút"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          startQuiz(bai['MaBKT'], bai['TgLamPhut'] ?? 10, index);
                        },
                        child: const Text("Bắt đầu"),
                      ),
                    );
                  },
                ),
                if (provider.cauHoiList.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    "Câu hỏi ${currentIndex + 1}/${provider.cauHoiList.length}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Thời gian còn lại: ${remainingTime ~/ 60}:${(remainingTime % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  _buildCauHoi(provider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentIndex > 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentIndex--;
                            });
                          },
                          child: const Text("Trước"),
                        ),
                      if (currentIndex < provider.cauHoiList.length - 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentIndex++;
                            });
                          },
                          child: const Text("Sau"),
                        ),
                      ElevatedButton(
                        onPressed: () => submitQuiz(provider.baiKTList[selectedBai]['MaBKT']),
                        child: const Text("Nộp bài"),
                      ),
                    ],
                  )
                ],
                const Divider(),
                const Text(
                  "Lịch sử làm bài",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.lichSu.length,
                  itemBuilder: (context, index) {
                    final ls = provider.lichSu[index];
                    return ListTile(
                      title: Text("Bài: ${ls['MaBKT']} - Điểm: ${ls['Diem']}"),
                      subtitle: Text("Ngày: ${ls['TgBatDau']}"),
                      onTap: () async {
                        // 1. Load lại bộ câu hỏi đúng của bài test đó
                        await provider.loadCauHoi(ls['MaBKT']);

                        // 2. Lấy kết quả chấm điểm
                        final ketQua = provider.diemTungCau(ls['CauTraLoi'], provider.cauHoiList);
                        final mapDapAnND = provider.parseCauTraLoi(ls['CauTraLoi']);

                        if (!mounted) return;

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Kết quả: ${ls['Diem']} điểm"),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: provider.cauHoiList.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, i) {
                                  final ch = provider.cauHoiList[i];
                                  final maCH = ch['MaCH'];
                                  final isCorrect = ketQua[maCH] ?? false;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Câu ${i + 1}: ${ch['NoiDung']}",
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      // Hiển thị đáp án người dùng đã chọn
                                      Text("Bạn chọn: ${mapDapAnND[maCH] ?? 'Không trả lời'}",
                                          style: TextStyle(color: isCorrect ? Colors.green : Colors.red)),
                                      // Nếu sai thì hiện đáp án đúng
                                      if (!isCorrect)
                                        Text("Đáp án đúng: ${ch['DapAn']}",
                                            style: const TextStyle(color: Colors.green)),
                                      // Luôn hiển thị giải thích
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        margin: const EdgeInsets.only(top: 5),
                                        color: Colors.grey[200],
                                        child: Text("💡 Giải thích: ${ch['GiaiThich'] ?? 'Không có giải thích'}",
                                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCauHoi(BaiKTProvider provider) {
    final ch = provider.cauHoiList[currentIndex];
    final loai = ch['Loai'];
    final maCH = ch['MaCH'];

    // Loại điền khuyết
    if (loai == 'dien_khuyet') {
      return TextFormField(
        key: ValueKey("ch_$maCH"), // Quan trọng: Giúp Flutter phân biệt các ô nhập liệu
        initialValue: provider.dapAnTam[maCH] ?? '',
        decoration: const InputDecoration(
          labelText: "Nhập đáp án của bạn",
          border: OutlineInputBorder(),
        ),
        onChanged: (val) => provider.chonDapAn(maCH, val),
      );
    }

    // Loại đúng/sai
    Map<String, String> options = {};
    if (loai == 'dung_sai') {
      options = {'Đúng': 'Đúng', 'Sai': 'Sai'};
    } else {
      try {
        final luaChon = ch['LuaChon'] ?? '{}';
        options = Map<String, String>.from(jsonDecode(luaChon));
      } catch (_) {
        options = {};
      }
    }

    return Column(
      children: options.entries.map((e) {
        final dapAn = e.key;
        final text = e.value;
        final isSelected = provider.dapAnTam[maCH] == dapAn;
        return ListTile(
          title: Text("$dapAn. $text"),
          leading: Radio<String>(
            value: dapAn,
            groupValue: provider.dapAnTam[maCH],
            onChanged: (val) {
              if (val != null) provider.chonDapAn(maCH, val);
            },
          ),
          tileColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
        );
      }).toList(),
    );
  }
}