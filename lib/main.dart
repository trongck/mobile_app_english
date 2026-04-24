import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/gt_provider.dart';
import 'providers/nguoi_dung_provider.dart';
import 'providers/tu_vung_provider.dart';
import 'providers/bai_kt_provider.dart';
import 'providers/nhat_ky_provider.dart';
import 'screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://nogdeylfdjttgymdgrpt.supabase.co',
    anonKey: 'sb_publishable_LeXoTOUZ0u5wsn0dog94RA_5LYIw1vL',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080B1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GTProvider()),
        ChangeNotifierProvider(create: (_) => NguoiDungProvider()),
        ChangeNotifierProvider(create: (_) => TuVungProvider()),
        ChangeNotifierProvider(create: (_) => BaiKTProvider()),
        ChangeNotifierProvider(create: (_) => NhatKyProvider()),
      ],
      child: const DevTalkApp(),
    ),
  );
}

class DevTalkApp extends StatelessWidget {
  const DevTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevTalk English',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080B1A),
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // fallback to system
      ),
      // SplashScreen tự quyết định route sau khi check session
      home: const SplashScreen(),
    );
  }
}