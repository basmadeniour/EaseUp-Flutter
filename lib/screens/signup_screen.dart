import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Home/home_screen.dart';
import 'login_screen.dart';
import '../config/api_config.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. تعريف الـ Key والـ Controllers
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // دالة التسجيل
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userName = '${_firstNameController.text.trim()}_${_lastNameController.text.trim()}';
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'universityEmail': _emailController.text.trim(),
          'password': _passController.text,
          'confirmPassword': _confirmPassController.text,
          'userName': userName,
          'address': '',
          'isAgree': true,
          'rememberMe': false,
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
          
          // ✅ حفظ الاسم الأول والاسم الأخير
          await prefs.setString('user_first_name', _firstNameController.text.trim());
          await prefs.setString('user_last_name', _lastNameController.text.trim());
          
          // ✅ حفظ الاسم الكامل (اختياري)
          String fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
          await prefs.setString('user_full_name', fullName);
          
          print('✅ Signup successful - First name saved: ${_firstNameController.text.trim()}');
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _showErrorDialog(data['message'] ?? 'فشل إنشاء الحساب');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData.toString());
      }
    } catch (e) {
      print('❌ Signup error: $e');
      _showErrorDialog('خطأ في الاتصال بالخادم. تأكد من تشغيل الخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
              SizedBox(height: screenHeight * 0.015),
              _buildTitleSection(),
              SizedBox(height: screenHeight * 0.03),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    _buildInputFields(),
                    SizedBox(height: screenHeight * 0.04),
                    _buildSignupButton(context),
                    const SizedBox(height: 20),
                    _buildLoginRedirect(context),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _customField('First Name', Icons.person_outline, 
            controller: _firstNameController, 
            keyboardType: TextInputType.name,
            validator: (v) => v!.isEmpty ? 'First name is required' : null),
        const SizedBox(height: 12),
        
        _customField('Last Name', Icons.person_outline, 
            controller: _lastNameController, 
            keyboardType: TextInputType.name,
            validator: (v) => v!.isEmpty ? 'Last name is required' : null),
        const SizedBox(height: 12),
        
        _customField('Email', Icons.email_outlined, 
            controller: _emailController, 
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v!.isEmpty || !v.contains('.com')) ? 'Enter a valid email' : null),
        const SizedBox(height: 12),
        
        _customField('Phone Number', Icons.phone_outlined, 
            controller: _phoneController, 
            keyboardType: TextInputType.phone,
            validator: (v) => (v!.isEmpty || v.length < 11) ? 'Enter a valid phone number' : null),
        const SizedBox(height: 12),
        
        _customField(
          'Password', Icons.lock_outline,
          isPass: true,
          controller: _passController,
          keyboardType: TextInputType.visiblePassword,
          isVisible: _isPasswordVisible,
          onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          validator: (v) => v!.length < 6 ? 'Password must be at least 6 chars' : null,
        ),
        const SizedBox(height: 12),
        
        _customField(
          'Confirm Password', Icons.lock_outline,
          isPass: true,
          controller: _confirmPassController,
          keyboardType: TextInputType.visiblePassword,
          isVisible: _isConfirmVisible,
          onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
          validator: (v) {
            if (v!.isEmpty) return 'Please confirm password';
            if (v != _passController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              'Signup',
              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _customField(String hint, IconData icon, {
    bool isPass = false, 
    bool isVisible = false, 
    VoidCallback? onToggle, 
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: isPass 
            ? IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: onToggle) 
            : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: primaryColor, width: 1.2)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: primaryColor, width: 2)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: Colors.red, width: 1.2)
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: Colors.red, width: 2)
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
    return const Column(children: [
      Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
      SizedBox(height: 5),
      Text('Enter Your Personal Data', style: TextStyle(fontSize: 16, color: Colors.black54)),
    ]);
  }

  // الانتقال لصفحة Login
  Widget _buildLoginRedirect(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("Already have an Account? "),
      GestureDetector(
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }, 
        child: const Text(
          'Login', 
          style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)
        )
      ),
    ]);
  }
}

// --- Clippers ---
class TopWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
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
  @override Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width * 0.35, size.height + 10, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}