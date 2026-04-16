import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signup_screen.dart';
import 'Home/home_screen.dart';
import 'forgot_password.dart';
import '../config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة التحقق من وجود token مخزن
  Future<void> _checkIfAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null && token.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  // دالة تسجيل الدخول
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'rememberMe': false
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['isAuthenticated'] == true) {
          // حفظ التوكن والمعلومات
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
          await prefs.setStringList('roles', List<String>.from(data['roles']));
          await prefs.setString('user_email', data['email']);
          
          // ✅ حفظ الاسم الأول والاسم الأخير من استجابة الخادم
          if (data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
            await prefs.setString('user_first_name', data['firstName']);
          }
          if (data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
            await prefs.setString('user_last_name', data['lastName']);
          }
          
          // ✅ حفظ الاسم الكامل (اختياري)
          String firstName = data['firstName'] ?? '';
          String lastName = data['lastName'] ?? '';
          String fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await prefs.setString('user_full_name', fullName);
          }
          
          print('✅ Login successful - First name saved: ${data['firstName']}');
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showErrorDialog(data['message'] ?? 'فشل تسجيل الدخول');
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData.toString());
      }
    } catch (e) {
      print('❌ Login error: $e');
      _showErrorDialog('خطأ في الاتصال بالخادم. تأكد من تشغيل الخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة مسح البيانات المخزنة (للاختبار)
  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _showErrorDialog('تم مسح جميع البيانات المخزنة');
    print('✅ All stored data cleared');
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                    const SizedBox(height: 10),
                    _buildClearDataButton(),
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

  // زر مسح البيانات المخزنة (للاختبار فقط)
  Widget _buildClearDataButton() {
    return TextButton(
      onPressed: _clearStoredData,
      child: const Text(
        'Clear Saved Data (Test Only)',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildEmailField() {
    return _customTextField(
      hint: 'Email',
      icon: Icons.email_outlined,
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
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
      onPressed: _isLoading ? null : () {
        if (_formKey.currentState!.validate()) {
          _login();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

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
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
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

  Widget _buildHeaderImage(double screenHeight) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.12,
      child: Image.asset(
        'images/top.png',
        fit: BoxFit.fill,
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

// --- الكليبرز ---
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