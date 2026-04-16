import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  final int? studentId;
  
  const EditProfileScreen({
    super.key,
    this.studentId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // تعريف الـ Controllers
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _collegeController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  int _studentId = 0;
  String _token = '';

  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    _collegeController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // جلب البيانات الحالية من API
  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final firstName = prefs.getString('user_first_name') ?? '';
      final lastName = prefs.getString('user_last_name') ?? '';
      
      if (_token.isEmpty) {
        _showError('الرجاء تسجيل الدخول أولاً');
        setState(() => _isLoading = false);
        return;
      }
      
      // استخدام studentId من widget إذا كان موجوداً
      int studentId = widget.studentId ?? 0;
      
      // إذا لم يكن هناك studentId، نحاول جلبها من SharedPreferences أو API
      if (studentId == 0) {
        studentId = prefs.getInt('student_id') ?? 0;
        _studentId = studentId;
      } else {
        _studentId = studentId;
      }
      
      // ✅ تم تصحيح المسار: prfile -> profile
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/student/profile?studentId=$_studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // ✅ استخدام الاسم المحفوظ أولاً
          String fullName = data['name'] ?? '';
          if (fullName.isEmpty && firstName.isNotEmpty) {
            fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          }
          
          _nameController.text = fullName.isNotEmpty ? fullName : 'User';
          _jobController.text = data['title'] ?? data['jobTitle'] ?? 'Computer Science Student';
          _collegeController.text = data['college'] ?? data['university'] ?? data['department'] ?? 'Computer Science';
          _ageController.text = data['age']?.toString() ?? '20';
          _emailController.text = data['email'] ?? email;
          _isLoading = false;
        });
        print('✅ Profile loaded successfully for studentId: $_studentId');
      } else if (response.statusCode == 404) {
        // ✅ إذا لم يتم العثور على الملف الشخصي، استخدمي البيانات من SharedPreferences
        setState(() {
          String fullName = firstName.isNotEmpty 
              ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
              : 'User';
          _nameController.text = fullName;
          _jobController.text = 'Computer Science Student';
          _collegeController.text = 'Computer Science';
          _ageController.text = '20';
          _emailController.text = email;
          _isLoading = false;
        });
        print('⚠️ Profile not found (404), using fallback data');
      } else {
        // بيانات افتراضية في حال فشل الاتصال
        setState(() {
          String fullName = firstName.isNotEmpty 
              ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
              : 'User';
          _nameController.text = fullName;
          _jobController.text = 'Computer Science Student';
          _collegeController.text = 'Computer Science';
          _ageController.text = '20';
          _emailController.text = email;
          _isLoading = false;
        });
        print('❌ Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() => _isLoading = false);
      _showError('خطأ في تحميل البيانات: $e');
    }
  }

  // تحديث الملف الشخصي
  Future<void> _updateProfile() async {
    // التحقق من المدخلات
    if (_nameController.text.isEmpty) {
      _showError('الرجاء إدخال الاسم');
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError('الرجاء إدخال بريد إلكتروني صحيح');
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? _token;
      
      if (token.isEmpty) {
        _showError('الرجاء تسجيل الدخول أولاً');
        setState(() => _isSaving = false);
        return;
      }
      
      // تحديث باستخدام الرابط الصحيح
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/update/student/$_studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': _studentId,
          'name': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 20,
          'gender': 'Not specified',
          'university': _collegeController.text.trim(),
          'department': _collegeController.text.trim(),
          'academicYear': 3,
          'currentGPA': 3.0,
          'isActive': true,
          'hasScolarship': false,
          'total_Exercise_Score': 0,
        }),
      );
      
      if (response.statusCode == 200) {
        // حفظ الإيميل الجديد والاسم في SharedPreferences
        await prefs.setString('user_email', _emailController.text.trim());
        
        // حفظ الاسم الجديد
        final nameParts = _nameController.text.trim().split(' ');
        if (nameParts.isNotEmpty) {
          await prefs.setString('user_first_name', nameParts.first);
          if (nameParts.length > 1) {
            await prefs.setString('user_last_name', nameParts.skip(1).join(' '));
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile Updated Successfully!'),
              backgroundColor: primaryColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData.toString());
      }
    } catch (e) {
      _showError('خطأ في الاتصال: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildEditField(Icons.person, 'Full Name', _nameController),
                  _buildEditField(Icons.work, 'Title', _jobController),
                  _buildEditField(Icons.school, 'College/University', _collegeController),
                  _buildEditField(Icons.cake, 'Age', _ageController, isNumber: true),
                  _buildEditField(Icons.email, 'Email', _emailController, isEmail: true),
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditField(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: primaryColor),
          prefixIcon: Icon(icon, color: primaryColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}