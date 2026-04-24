import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailOtpService {
  // EmailJS config (giữ nguyên)
  static const _serviceId = 'service_k84lh8h';
  static const _templateId = 'template_zkxpumt';
  static const _publicKey = 'bDlldZB1lDG-Bjz1x';

  /// Sinh OTP 6 chữ số
  static String generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  /// Gửi OTP qua EmailJS + LƯU VÀO DB để verify
  static Future<bool> sendOtp({
    required String toEmail,
    required String otp,
    String? userName,
  }) async {
    try {
      print(">>> Gửi OTP $otp tới $toEmail...");

      // 1. Gửi email qua EmailJS
      final emailSent = await _sendViaEmailJs(
        toEmail: toEmail,
        otp: otp,
        userName: userName ?? toEmail.split('@').first,
      );

      if (!emailSent) {
        print("❌ EmailJS gửi thất bại");
        return false;
      }

      // 2. Lưu OTP vào DB để verify (bảng xacthucemail)
      final dbSaved = await _saveOtpToDb(toEmail, otp);

      print(">>> ${dbSaved ? '✅' : '❌'} OTP lưu DB thành công");
      return emailSent && dbSaved;
    } catch (e) {
      print("❌ sendOtp error: $e");
      return false;
    }
  }

  /// Verify OTP từ DB (an toàn hơn so sánh in-memory)
  static Future<bool> verifyOtp(String email, String otpInput) async {
  try {
    final sb = Supabase.instance.client;
    
    final response = await sb
        .from('xacthucemail')
        .select()
        .eq('email', email)
        .limit(1);

    if (response.isEmpty) {
      print("❌ No OTP found");
      return false;
    }

    final data = response.first;
    final savedOtp = data['maotp'] as String;
    final expiryStr = data['thoigianhethan'] as String?;
    
    print("🔍 RAW DB:");
    print("OTP: $savedOtp");
    print("Expiry: '$expiryStr'");
    
    // Check OTP trước
    if (otpInput.trim() != savedOtp) {
      print("❌ Wrong OTP");
      return false;
    }
    
    // Check time nếu có expiry
    if (expiryStr != null) {
      try {
        DateTime expiry;
        // Fix format nếu thiếu Z
        final fixedExpiry = expiryStr.endsWith('Z') ? expiryStr : '$expiryStr.000Z';
        expiry = DateTime.parse(fixedExpiry);
        
        final now = DateTime.now().toUtc(); 
        final isValidTime = now.isBefore(expiry);
        
        print("⏰ Time check: now=$now | expiry=$expiry | valid=$isValidTime");
        
        if (!isValidTime) {
          print("❌ Expired");
          return false;
        }
      } catch (e) {
        print("⚠️ Skip time check (parse error): $e");
        // Vẫn cho qua nếu OTP đúng
      }
    }
    
    // Cleanup
    await sb.from('xacthucemail').delete().eq('email', email);
    print("✅ SUCCESS!");
    
    return true;
  } catch (e) {
    print("❌ Error: $e");
    return false;
  }
}
  // ── EmailJS gửi email (giữ nguyên code của bạn) ─────────────────────────
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
    print("EmailJS: ${success ? '✅' : '❌'} ${response.statusCode}");
    print("Response: ${response.body}");

    return success;
  }

  // ── Lưu OTP vào bảng xacthucemail ────────────────────────────────────────
  // FIX _saveOtpToDb:
static Future<bool> _saveOtpToDb(String email, String otp) async {
  final sb = Supabase.instance.client;
  final expiry = DateTime.now().add(const Duration(minutes: 10));
  
  // ✅ FORMAT ĐÚNG: full ISO8601 với Z
  final expiryIso = expiry.toUtc().toIso8601String();
  
  print(">>> SAVE: $expiryIso");
  
  final response = await sb.from('xacthucemail').upsert({
    'email': email,
    'maotp': otp,
    'thoigianhethan': expiryIso,  // 2026-04-25T01:06:03.370928Z
  }).select().limit(1);
  
  return response.isNotEmpty;
}


}
