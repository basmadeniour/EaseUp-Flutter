import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // ==================== دوال مساعدة ====================
  
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('غير مصرح به - يرجى تسجيل الدخول مرة أخرى');
    } else if (response.statusCode == 404) {
      throw Exception('العنوان غير موجود - تحقق من صحة الرابط');
    } else if (response.statusCode == 500) {
      throw Exception('خطأ في الخادم الداخلي');
    } else {
      String errorMessage = 'حدث خطأ غير متوقع (${response.statusCode})';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        }
      } catch (e) {
        // تجاهل إذا لم يكن الرد بصيغة JSON
      }
      throw Exception(errorMessage);
    }
  }

  // ==================== المصادقة ====================
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'rememberMe': false
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // حفظ التوكن
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setStringList('roles', List<String>.from(data['roles']));
        return data;
      } else {
        throw Exception('فشل تسجيل الدخول: ${response.body}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String userName,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'universityEmail': email,
          'password': password,
          'confirmPassword': password,
          'userName': userName,
          'address': address ?? '',
          'isAgree': true,
          'rememberMe': false,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return data;
      } else {
        throw Exception('فشل التسجيل: ${response.body}');
      }
    } catch (e) {
      print('❌ Register error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('roles');
  }

  // ==================== الأهداف ====================
  
  Future<List<dynamic>> getMyGoals() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Goals/my-goals'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get goals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createGoal({
    required String title,
    required int priority, // 1=Low, 2=Medium, 3=High
    DateTime? deadline,
    required List<String> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Goals/add'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'priority': priority,
          'deadline': deadline?.toIso8601String(),
          'items': items,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل إضافة الهدف: ${response.body}');
    } catch (e) {
      print('❌ Create goal error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<void> toggleItem(int itemId, int goalId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Goals/toggle-item/$itemId?goalId=$goalId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('فشل تحديث المهمة');
      }
    } catch (e) {
      print('❌ Toggle item error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<void> deleteGoal(int goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/Goals/delete/$goalId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('فشل حذف الهدف');
      }
    } catch (e) {
      print('❌ Delete goal error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  // ==================== التمارين ====================
  
  Future<List<dynamic>> getAllExercises() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Exercises/all'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get exercises error: $e');
      return [];
    }
  }

  Future<int> completeExercise() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Exercises/complete'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // استخراج الرقم من الرسالة (مثال: "Updated successfully: 15")
        final String message = data.toString();
        final RegExp regex = RegExp(r'(\d+)$');
        final match = regex.firstMatch(message);
        if (match != null) {
          return int.parse(match.group(0)!);
        }
        return 0;
      }
      throw Exception('فشل إكمال التمرين');
    } catch (e) {
      print('❌ Complete exercise error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  // ==================== الملف الشخصي ====================
  
  // ✅ تم تصحيح المسار من 'prfile' إلى 'profile'
  Future<Map<String, dynamic>> getStudentProfile(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/student/profile?studentId=$studentId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل جلب الملف الشخصي');
    } catch (e) {
      print('❌ Get profile error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<Map<String, dynamic>> updateStudentProfile(
    int studentId, {
    required String name,
    required int age,
    required String gender,
    required String university,
    required String department,
    required int academicYear,
    required double currentGPA,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/update/student/$studentId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'id': studentId,
          'name': name,
          'age': age,
          'gender': gender,
          'university': university,
          'department': department,
          'academicYear': academicYear,
          'currentGPA': currentGPA,
          'user': {'phoneNumber': phoneNumber},
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل تحديث الملف الشخصي');
    } catch (e) {
      print('❌ Update profile error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/change-password'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('فشل تغيير كلمة المرور');
      }
    } catch (e) {
      print('❌ Change password error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  // ==================== الاستبيانات (Surveys) ====================
  
  Future<Map<String, dynamic>> getSurvey(int surveyId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Survey?id=$surveyId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل جلب الاستبيان');
    } catch (e) {
      print('❌ Get survey error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  Future<Map<String, dynamic>> submitSurvey({
    required int studentId,
    required int surveyId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Survey/submit'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'studentId': studentId,
          'surveyId': surveyId,
          'answers': answers,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('فشل إرسال الاستبيان');
    } catch (e) {
      print('❌ Submit survey error: $e');
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  // ==================== دوال مساعدة إضافية ====================
  
  Future<int?> getCurrentStudentId() async {
    try {
      // هذا يعتمد على كيفية تخزين studentId
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('student_id');
    } catch (e) {
      print('❌ Get student id error: $e');
      return null;
    }
  }

  Future<void> saveStudentId(int studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('student_id', studentId);
  }
}