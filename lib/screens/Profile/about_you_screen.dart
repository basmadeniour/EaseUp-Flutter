import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_screen.dart';
import '../../config/api_config.dart'; // إضافة import الـ config

class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  // متغيرات البيانات
  String _fullName = '';
  String _title = '';
  String _college = '';
  String _academicYear = '';
  String _age = '';
  String _email = '';
  int _studentId = 0;
  
  static const Color primaryColor = Color(0xFF67C2B9);
  // تم حذف static const String baseUrl

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      _email = prefs.getString('user_email') ?? '';
      
      if (token == null) {
        setState(() {
          _errorMessage = 'الرجاء تسجيل الدخول أولاً';
          _isLoading = false;
        });
        return;
      }
      
      // أولاً: جلب الـ studentId من API الطلاب
      // ملاحظة: قد تحتاج إلى تعديل هذا الـ endpoint حسب الـ API المتاح لديك
      final studentResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Students/my-id'), // استخدام ApiConfig
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      int studentId = 0;
      if (studentResponse.statusCode == 200) {
        final studentData = jsonDecode(studentResponse.body);
        studentId = studentData['id'] ?? 0;
        _studentId = studentId;
        // حفظ الـ studentId في SharedPreferences للاستخدام لاحقاً
        await prefs.setInt('student_id', studentId);
      } else {
        // محاولة جلب الـ studentId من SharedPreferences إذا كان موجوداً
        studentId = prefs.getInt('student_id') ?? 0;
        _studentId = studentId;
      }
      
      if (studentId == 0) {
        setState(() {
          _errorMessage = 'لم يتم العثور على بيانات الطالب';
          _isLoading = false;
        });
        return;
      }
      
      // ثانياً: جلب بيانات الملف الشخصي باستخدام الـ studentId
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/student/prfile?studentId=$studentId'), // استخدام ApiConfig
        headers: {
          'Content-Type': 'application/json',   
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fullName = data['name'] ?? data['fullName'] ?? 'غير محدد';
          _title = data['title'] ?? data['jobTitle'] ?? 'طالب/ة';
          _college = data['college'] ?? data['department'] ?? 'علوم الحاسب';
          _academicYear = _getAcademicYearString(data['academicYear']);
          _age = data['age'] != null ? '${data['age']} سنة' : 'غير محدد';
          _email = data['email'] ?? _email;
          _errorMessage = '';
          _isLoading = false;
        });
        print('Student ID: $_studentId');
      } else if (response.statusCode == 404) {
        // إذا لم يتم العثور على الملف الشخصي، نستخدم بيانات افتراضية
        setState(() {
          _fullName = 'Engi Eid';
          _title = 'Computer Science Student';
          _college = 'Computer Science';
          _academicYear = 'Third Year';
          _age = '20 Years';
          _isLoading = false;
          _errorMessage = 'لم يتم العثور على الملف الشخصي';
        });
      } else {
        setState(() {
          _fullName = 'Engi Eid';
          _title = 'Computer Science Student';
          _college = 'Computer Science';
          _academicYear = 'Third Year';
          _age = '20 Years';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullName = 'Engi Eid';
        _title = 'Computer Science Student';
        _college = 'Computer Science';
        _academicYear = 'Third Year';
        _age = '20 Years';
        _isLoading = false;
        _errorMessage = 'استخدام بيانات محلية مؤقتة: ${e.toString()}';
      });
    }
  }

  String _getAcademicYearString(int? year) {
    switch (year) {
      case 1: return 'First Year';
      case 2: return 'Second Year';
      case 3: return 'Third Year';
      case 4: return 'Fourth Year';
      default: return 'Third Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 95),
                    _buildNameAndTitle(),
                    const SizedBox(height: 35),
                    _buildInfoCard(),
                    const SizedBox(height: 40),
                    _buildEditButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 90,
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(60),
              bottomRight: Radius.circular(60),
            ),
          ),
        ),
        Positioned(
          top: 15,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 75,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('images/profile.jpeg'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndTitle() {
    return Column(
      children: [
        Text(
          _fullName,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoRow(Icons.school_rounded, 'College', _college),
            _buildDivider(),
            _buildInfoRow(Icons.auto_awesome_mosaic_rounded, 'Academic Year', _academicYear),
            _buildDivider(),
            _buildInfoRow(Icons.cake_rounded, 'Age', _age),
            _buildDivider(),
            _buildInfoRow(Icons.alternate_email_rounded, 'Email', _email),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                studentId: _studentId,
              ),
            ),
          );
          if (result == true) {
            _loadProfile();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Divider(color: Colors.grey[100], thickness: 1),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
      ],
    );
  }
}