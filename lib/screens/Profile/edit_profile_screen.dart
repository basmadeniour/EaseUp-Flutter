import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _collegeController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  int _studentId = 0;
  String _token = '';
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploadingImage = false;

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

  // اختيار الصورة (يدعم Web و Mobile تلقائياً)
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUploadingImage = true;
        });
        await _uploadImage(image);
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      setState(() => _isUploadingImage = false);
      _showError('حدث خطأ في اختيار الصورة: $e');
    }
  }

  // رفع الصورة إلى الخادم
  Future<void> _uploadImage(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/upload-image'),
      );
      request.headers['Authorization'] = 'Bearer $_token';
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 Upload Status: ${response.statusCode}');
      print('📤 Upload Body: ${response.body}');
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _profileImageUrl = jsonData['imageUrl'];
          _isUploadingImage = false;
        });
        _showSuccess('Image uploaded successfully!');
      } else if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isUploadingImage = false;
        });
        _showSuccess('Image uploaded successfully!');
      } else {
        setState(() => _isUploadingImage = false);
        String errorMessage = 'Upload failed: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            errorMessage = response.body;
          }
        }
        _showError(errorMessage);
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      setState(() => _isUploadingImage = false);
      _showError('Error uploading image: $e');
    }
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
      
      int studentId = widget.studentId ?? 0;
      
      if (studentId == 0) {
        studentId = prefs.getInt('student_id') ?? 0;
        _studentId = studentId;
      } else {
        _studentId = studentId;
      }
      
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
          String fullName = data['name'] ?? '';
          if (fullName.isEmpty && firstName.isNotEmpty) {
            fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          }
          
          _nameController.text = fullName.isNotEmpty ? fullName : 'User';
          _jobController.text = data['title'] ?? data['jobTitle'] ?? prefs.getString('user_title') ?? 'Computer Science Student';
          _collegeController.text = data['college'] ?? data['university'] ?? data['department'] ?? prefs.getString('user_university') ?? 'Computer Science';
          _ageController.text = data['age']?.toString() ?? prefs.getString('user_age') ?? '20';
          _emailController.text = data['email'] ?? email;
          _profileImageUrl = data['profilePictureUrl'];
          _isLoading = false;
        });
        
        await prefs.setString('user_title', _jobController.text);
        await prefs.setString('user_university', _collegeController.text);
        await prefs.setString('user_age', _ageController.text);
        
        print('✅ Profile loaded successfully for studentId: $_studentId');
      } else if (response.statusCode == 204 || response.statusCode == 404) {
        setState(() {
          String fullName = firstName.isNotEmpty 
              ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
              : 'User';
          _nameController.text = fullName;
          _jobController.text = prefs.getString('user_title') ?? 'Computer Science Student';
          _collegeController.text = prefs.getString('user_university') ?? 'Computer Science';
          _ageController.text = prefs.getString('user_age') ?? '20';
          _emailController.text = email;
          _isLoading = false;
        });
        print('⚠️ Profile not found, using fallback data');
      } else {
        setState(() {
          String fullName = firstName.isNotEmpty 
              ? (lastName.isNotEmpty ? '$firstName $lastName' : firstName)
              : 'User';
          _nameController.text = fullName;
          _jobController.text = prefs.getString('user_title') ?? 'Computer Science Student';
          _collegeController.text = prefs.getString('user_university') ?? 'Computer Science';
          _ageController.text = prefs.getString('user_age') ?? '20';
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
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('student_id');
    print('🔍 Retrieved studentId from storage: $storedId');

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
      
      // ✅ التحقق من وجود studentId قبل الإرسال
      _studentId = prefs.getInt('student_id') ?? 0;
      if (_studentId == 0) {
        _showError('Student ID not found. Please logout and login again.');
        setState(() => _isSaving = false);
        return;
      }
      
      final token = prefs.getString('auth_token') ?? _token;
      
      if (token.isEmpty) {
        _showError('الرجاء تسجيل الدخول أولاً');
        setState(() => _isSaving = false);
        return;
      }
      
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
          'profilePictureUrl': _profileImageUrl ?? '',
        }),
      );
      
      print('📤 Update Status: ${response.statusCode}');
      print('📤 Update Body: ${response.body}');
      
      if (response.statusCode == 200) {
        await prefs.setString('user_email', _emailController.text.trim());
        
        final nameParts = _nameController.text.trim().split(' ');
        if (nameParts.isNotEmpty) {
          await prefs.setString('user_first_name', nameParts.first);
          if (nameParts.length > 1) {
            await prefs.setString('user_last_name', nameParts.skip(1).join(' '));
          }
        }
        
        await prefs.setString('user_title', _jobController.text.trim());
        await prefs.setString('user_university', _collegeController.text.trim());
        await prefs.setString('user_age', _ageController.text.trim());
        
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
        // ✅ معالجة الاستجابة النصية أو JSON بشكل آمن
        String errorMessage = 'Failed to update profile';
        try {
          if (response.body.isNotEmpty) {
            if (response.body.trim().startsWith('{')) {
              final errorData = jsonDecode(response.body);
              errorMessage = errorData['message'] ?? errorData.toString();
            } else {
              errorMessage = response.body;
            }
          }
        } catch (e) {
          errorMessage = response.body.isNotEmpty ? response.body : 'Server error';
        }
        _showError(errorMessage);
      }
    } catch (e) {
      print('❌ Update error: $e');
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: primaryColor,
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
                  _buildProfileImageSection(),
                  const SizedBox(height: 20),
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

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isUploadingImage
                      ? const Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                          ? Image.network(
                              '${ApiConfig.baseUrl}$_profileImageUrl',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to change profile picture',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
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