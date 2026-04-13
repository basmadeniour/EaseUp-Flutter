import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. الجزء العلوي (استخدام الصورة بدلاً من التموجات البرمجية)
          _buildHeaderImage(screenHeight),

          SizedBox(height: screenHeight * 0.05),

          // 2. النصوص الترحيبية
          _buildWelcomeText(),

          const Spacer(),

          // 3. اللوجو
          _buildLogo(screenHeight),

          const Spacer(),

          // 4. أزرار التحكم
          _buildActionButtons(context),

          SizedBox(height: screenHeight * 0.03),
        ],
      ),
    );
  }

  // الدالة الجديدة لعرض صورة التموجات
  Widget _buildHeaderImage(double screenHeight) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.12, // يمكنكِ تعديل الارتفاع حسب الرغبة
      child: Image.asset(
        'images/top.png', // تأكدي من المسار الصحيح للصورة في مشروعك
        fit: BoxFit.fill, // لضمان ملء العرض بالكامل
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            'Find your inner calm and academic balance!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(double screenHeight) {
    return Center(
      child: Image.asset(
        'images/Easeup.png',
        height: screenHeight * 0.22,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 30),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => _navigateTo(context, const SignupScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _navigateTo(context, const LoginScreen()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor, width: 2),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}