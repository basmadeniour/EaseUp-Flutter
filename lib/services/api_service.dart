import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://localhost:7057'; // غير الرابط حسب إعداداتك

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== المصادقة ====================
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
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
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String userName,
    String? address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
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
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('roles');
  }

  // ==================== الأهداف ====================
  
  Future<List<dynamic>> getMyGoals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Goals/my-goals'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createGoal({
    required String title,
    required int priority, // 1=Low, 2=Medium, 3=High
    DateTime? deadline,
    required List<String> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Goals/add'),
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
  }

  Future<void> toggleItem(int itemId, int goalId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Goals/toggle-item/$itemId?goalId=$goalId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode != 204) {
      throw Exception('فشل تحديث المهمة');
    }
  }

  Future<void> deleteGoal(int goalId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Goals/delete/$goalId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode != 204) {
      throw Exception('فشل حذف الهدف');
    }
  }

  // ==================== التمارين ====================
  
  Future<List<dynamic>> getAllExercises() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Exercises/all'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<int> completeExercise() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Exercises/complete'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data; // إرجاع النتيجة (Total_Exercise_Score الجديد)
    }
    throw Exception('فشل إكمال التمرين');
  }

  // ==================== الملف الشخصي ====================
  
  Future<Map<String, dynamic>> getStudentProfile(int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Profile/student/prfile?studentId=$studentId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('فشل جلب الملف الشخصي');
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
    final response = await http.put(
      Uri.parse('$baseUrl/api/Profile/update/student/$studentId'),
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
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Profile/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('فشل تغيير كلمة المرور');
    }
  }
}