import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'Home/home_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. تعريف مفتاح الفورم والـ Controllers للوصول للداتا
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  void dispose() {
    // تنظيف الـ Controllers عند إغلاق الشاشة
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // 2. لف العمود بـ Form وتمرير المفتاح
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderImage(screenHeight),
              SizedBox(height: screenHeight * 0.03),
              _buildTitleSection(),
              SizedBox(height: screenHeight * 0.04),
              Image.asset('images/Easeup.png', height: screenHeight * 0.15),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _buildEmailField(),
                    const SizedBox(height: 15),
                    _buildPasswordField(),
                    _buildForgetPasswordButton(),
                    const SizedBox(height: 10),
                    _buildLoginButton(context),
                    const SizedBox(height: 25),
                    _buildSignupRedirect(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- دوال بناء الـ Widgets مع إضافة القيود ---

  Widget _buildEmailField() {
    return _customTextField(
      hint: 'Email',
      icon: Icons.email_outlined,
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      // قيد الإيميل
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@') || !value.contains('.com')) {
          return 'Please enter a valid email (e.g. name@mail.com)';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _customTextField(
      hint: 'Password',
      icon: Icons.lock_outline,
      isPassword: true,
      controller: _passwordController,
      // قيد كلمة المرور
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: primaryColor.withOpacity(0.7),
        ),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 3. التحقق من القيود قبل الانتقال
        if (_formKey.currentState!.validate()) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        'Login',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // تعديل الـ Widget الموحدة لدعم الـ Validator والـ Controller والـ KeyboardType
  Widget _customTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.black87), // لضمان ظهور النص عند الكتابة
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        // أضفت Error Borders عشان يظهر اللون الأحمر عند الخطأ
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      ),
    );
  }

  // --- بقية الـ UI والـ Clippers كما هي في كودك الأصلي ---
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

  Widget _buildTitleSection() {
    return const Column(
      children: [
        Text('Welcome!', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor)),
        Text('Login', style: TextStyle(fontSize: 18, color: Colors.black54)),
      ],
    );
  }

Widget _buildForgetPasswordButton() {
  return Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () {
        // الربط هنا للانتقال لصفحة نسيت كلمة المرور
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgetPassword()),
        );
      },
      child: const Text(
        'Forget Password?',
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

  Widget _buildSignupRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't Have Account? "),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
          child: const Text('Signup', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// --- الكليبرز (نفس كودك دون تعديل) ---
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(size.width * 0.65, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BackgroundWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width * 0.35, size.height + 10, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}