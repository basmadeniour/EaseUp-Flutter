import 'package:flutter/material.dart';

class JournalDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const JournalDetailScreen({super.key, required this.title, required this.content});

  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Reading Note",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // إضافة خلفية متدرجة بسيطة لتعطي طابع الورق
          color: Color(0xFFFDFDFD),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم العنوان
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              
              // خط فاصل جمالي
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 25),
              
              // قسم المحتوى
              Text(
                content,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.8, // زيادة التباعد بين الأسطر لراحة القراءة
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 50), // مساحة في الأسفل
            ],
          ),
        ),
      ),
    );
  }
}