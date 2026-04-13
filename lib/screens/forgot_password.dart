import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  // 1. تعريف مفتاح الفورم والـ Controller
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  static const Color primaryColor = Color(0xff64C3BF);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // 2. لف المحتوى بـ Form
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // تأكدي من المسار (assets أو images) حسب مشروعك
              SizedBox(
                width: double.infinity,
                height: 110, // يمكنكِ تعديل الارتفاع حسب الرغبة
                child: Image.asset(
                  'images/top.png', // تأكدي من المسار الصحيح للصورة في مشروعك
                  fit: BoxFit.fill, // لضمان ملء العرض بالكامل
                ),
              ),

              const SizedBox(height: 100),

              Text(
                'Forgot Password',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

              Text(
                'Enter your email to reset your password',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 90, 89, 89),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // 3. استخدام TextFormField بدلاً من TextField لدعم الـ Validator
                child: TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: primaryColor),

                    // تصميم الحدود العادية
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    // 4. تصميم الحدود عند وجود خطأ (ستظهر بالأحمر تلقائياً)
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  // 5. التحقق من الفورم عند الضغط
                  if (_formKey.currentState!.validate()) {
                    // إذا كان الإيميل مكتوباً بشكل صحيح
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset link sent to your email'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 199.63,
                  height: 38.21,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
