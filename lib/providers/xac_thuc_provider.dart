import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Dịch vụ gửi và xác thực mã OTP qua Email dùng EmailJS và Supabase.
class EmailOtpService {
  static String get _serviceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? 'service_k84lh8h';
  static String get _templateId => dotenv.env['EMAILJS_TEMPLATE_ID'] ?? 'template_zkxpumt';
  static String get _publicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? 'bDlldZB1lDG-Bjz1x';

  /// Sinh mã OTP ngẫu nhiên gồm 6 chữ số.
  static String generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  /// Thực hiện gửi mã OTP đến email người nhận và lưu lại vào cơ sở dữ liệu để xác thực.
  static Future<bool> sendOtp({
    required String toEmail,
    required String otp,
    String? userName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(">>> Gửi OTP $otp tới $toEmail...");
      }

      // Gửi email thông qua EmailJS
      final emailSent = await _sendViaEmailJs(
        toEmail: toEmail,
        otp: otp,
        userName: userName ?? toEmail.split('@').first,
      );

      if (!emailSent) {
        debugPrint("❌ Gửi email qua EmailJS thất bại");
        return false;
      }

      // Lưu mã OTP vào bảng xacthucemail để phục vụ đối chiếu
      final dbSaved = await _saveOtpToDb(toEmail, otp);

      debugPrint(">>> ${dbSaved ? '✅' : '❌'} Lưu OTP vào cơ sở dữ liệu thành công");
      return emailSent && dbSaved;
    } catch (e) {
      debugPrint("❌ Lỗi trong quá trình gửi OTP: $e");
      return false;
    }
  }

  /// Xác thực mã OTP người dùng nhập vào bằng cách đối chiếu với bản ghi trong cơ sở dữ liệu.
  static Future<bool> verifyOtp(String email, String otpInput) async {
    try {
      final sb = Supabase.instance.client;
      
      final response = await sb
          .from('xacthucemail')
          .select()
          .eq('email', email)
          .limit(1);

      if (response.isEmpty) {
        debugPrint("❌ Không tìm thấy mã OTP cho email này");
        return false;
      }

      final data = response.first;
      final savedOtp = data['maotp'] as String;
      final expiryStr = data['thoigianhethan'] as String?;
      
      // Đối chiếu mã OTP
      if (otpInput.trim() != savedOtp) {
        debugPrint("❌ Mã OTP nhập vào không trùng khớp");
        return false;
      }
      
      // Kiểm tra thời hạn hiệu lực của mã OTP (10 phút)
      if (expiryStr != null) {
        try {
          DateTime expiry;
          final fixedExpiry = expiryStr.endsWith('Z') ? expiryStr : '$expiryStr.000Z';
          expiry = DateTime.parse(fixedExpiry);
          
          final now = DateTime.now().toUtc(); 
          final isValidTime = now.isBefore(expiry);
          
          if (!isValidTime) {
            debugPrint("❌ Mã OTP đã hết hạn sử dụng");
            return false;
          }
        } catch (e) {
          debugPrint("⚠️ Lỗi kiểm tra thời gian hết hạn: $e. Tiếp tục xác thực nếu OTP khớp.");
        }
      }
      
      // Xóa OTP khỏi database sau khi xác thực thành công để bảo mật
      await sb.from('xacthucemail').delete().eq('email', email);
      debugPrint("✅ Xác thực OTP thành công!");
      
      return true;
    } catch (e) {
      debugPrint("❌ Lỗi trong quá trình xác thực OTP: $e");
      return false;
    }
  }

  /// Gọi API của EmailJS để gửi email chứa mã OTP.
  static Future<bool> _sendViaEmailJs({
    required String toEmail,
    required String otp,
    required String userName,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final body = jsonEncode({
      'service_id': _serviceId,
      'template_id': _templateId,
      'user_id': _publicKey,
      'template_params': {
        'to_email': toEmail,
        'to_name': userName,
        'otp_code': otp,
        'app_name': 'DevTalk English',
      },
    });

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    final success = response.statusCode == 200;
    debugPrint("EmailJS Status: ${success ? '✅' : '❌'} ${response.statusCode}");
    return success;
  }

  /// Lưu trữ hoặc cập nhật mã OTP mới và thời gian hết hạn vào bảng xacthucemail.
  static Future<bool> _saveOtpToDb(String email, String otp) async {
    final sb = Supabase.instance.client;
    final expiry = DateTime.now().add(const Duration(minutes: 10));
    final expiryIso = expiry.toUtc().toIso8601String();
    
    final response = await sb.from('xacthucemail').upsert({
      'email': email,
      'maotp': otp,
      'thoigianhethan': expiryIso,
    }).select().limit(1);
    
    return response.isNotEmpty;
  }
}
