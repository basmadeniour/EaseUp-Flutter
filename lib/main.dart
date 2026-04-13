import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';

void main() {
  // للتأكد من استقرار تهيئة الخدمات قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  
  // جعل شريط الحالة (Status Bar) شفاف ليعطي شكلاً أجمل
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const EaseUpApp());
}

class EaseUpApp extends StatelessWidget {
  const EaseUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EaseUp',
      
      // إعداد الثيم العام للتطبيق لتوحيد الألوان
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF67C2B9),
          primary: const Color(0xFF67C2B9),
        ),
        fontFamily: 'Poppins', // تأكدي من تعريفه في pubspec.yaml
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      
      home: const WelcomeScreen(),
    );
  }
}