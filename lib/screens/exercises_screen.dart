import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String selectedCategory = "All";
  bool _isLoading = true;
  bool _isCompleting = false;
  List<Map<String, dynamic>> exercises = [];
  
  static const Color primaryColor = Color(0xFF67C2B9);
  static const String baseUrl = 'https://localhost:7057'; // غير الرابط حسب إعداداتك

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  // جلب التمارين من الخادم
  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/Exercises/all'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> exercisesData = jsonDecode(response.body);
        setState(() {
          exercises = exercisesData.map((e) => {
            'id': e['id'],
            'title': e['title'] ?? '',
            'desc': e['description'] ?? '',
            'time': e['time'] ?? '5 MINS',
            'tag': e['tag'] ?? '',
            'category': e['category'] ?? '',
            'image': e['image'] ?? '',
            'video': e['video'] ?? '',
            'isCompleted': e['isCompleted'] ?? false,
          }).cast<Map<String, dynamic>>().toList();
        });
      } else {
        // في حالة فشل الاتصال، استخدم البيانات المحلية
        _loadLocalExercises();
      }
    } catch (e) {
      print('خطأ في تحميل التمارين: $e');
      _loadLocalExercises();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // تحميل البيانات المحلية كبديل
  void _loadLocalExercises() {
    setState(() {
      exercises = [
        {
          "id": 1,
          "title": "Deep Breathing",
          "desc": "Reduce stress with breathing",
          "time": "5 MINS",
          "tag": "Calming",
          "category": "Breathing",
          "image": "images/Deep Breathing.jpeg",
          "video": "https://www.youtube.com/watch?v=odADwWzHR24",
          "isCompleted": false,
        },
        {
          "id": 2,
          "title": "Morning Meditation",
          "desc": "Start your day calm",
          "time": "10 MINS",
          "tag": "Focus",
          "category": "Meditation",
          "image": "images/Morning Meditation.jpg",
          "video": "https://www.youtube.com/watch?v=inpok4MKVLM",
          "isCompleted": false,
        },
        {
          "id": 3,
          "title": "Forest Walk",
          "desc": "Relax in nature",
          "time": "15 MINS",
          "tag": "Refresh",
          "category": "Movement",
          "image": "images/Forest Walk.jpeg",
          "video": "https://www.youtube.com/watch?v=1ZYbU82GVz4",
          "isCompleted": false,
        },
        {
          "id": 4,
          "title": "Mindful Stretching",
          "desc": "Release tension",
          "time": "8 MINS",
          "tag": "Flexibility",
          "category": "Movement",
          "image": "images/Mindfull Stretshing.jpeg",
          "video": "https://www.youtube.com/watch?v=v7AYKMP6rOE",
          "isCompleted": false,
        },
        {
          "id": 5,
          "title": "Relaxation",
          "desc": "Muscle relaxation",
          "time": "7 MINS",
          "tag": "Calm",
          "category": "Meditation",
          "image": "images/Relaxation.png",
          "video": "https://www.youtube.com/watch?v=86HUcX8ZtAk",
          "isCompleted": false,
        },
        {
          "id": 6,
          "title": "Gratitude Writing",
          "desc": "Boost positivity",
          "time": "5 MINS",
          "tag": "Mind",
          "category": "Meditation",
          "image": "images/Gratitude Writing.png",
          "video": "https://www.youtube.com/watch?v=9WgP4u5m1oY",
          "isCompleted": false,
        },
      ];
    });
  }

  // إكمال تمرين
  Future<void> _completeExercise(Map<String, dynamic> item, int index) async {
    if (_isCompleting) return;
    
    setState(() => _isCompleting = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        _showErrorDialog('الرجاء تسجيل الدخول أولاً');
        setState(() => _isCompleting = false);
        return;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/Exercises/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final newScore = jsonDecode(response.body);
        
        // تحديث حالة التمرين محلياً
        setState(() {
          exercises[index]['isCompleted'] = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exercise completed! 🎉 Total score: $newScore points'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showErrorDialog('Failed to complete exercise');
      }
    } catch (e) {
      _showErrorDialog('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  void openVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showErrorDialog("Could not launch $url");
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    List filteredExercises = selectedCategory == "All"
        ? exercises
        : exercises.where((e) => e["category"] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Exercises",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: _isLoading && exercises.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Exercises",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Simple activities for your mental well-being",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        category("All"),
                        category("Breathing"),
                        category("Meditation"),
                        category("Movement"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Grid
                  Expanded(
                    child: filteredExercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fitness_center, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  "No exercises found",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            itemCount: filteredExercises.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.75,
                            ),
                            itemBuilder: (context, index) {
                              final item = filteredExercises[index];
                              final originalIndex = exercises.indexWhere((e) => e['id'] == item['id']);
                              return exerciseCard(item, originalIndex);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Category Button
  Widget category(String text) {
    bool active = selectedCategory == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  /// Card
  Widget exerciseCard(Map<String, dynamic> item, int index) {
    bool isCompleted = item['isCompleted'] == true;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isCompleted ? Colors.green.shade50 : Colors.grey[100],
        border: isCompleted
            ? Border.all(color: Colors.green.shade200, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openVideo(item["video"]),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.asset(
                    item["image"],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item["time"],
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item["desc"],
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.grey : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item["tag"],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    // Complete Button
                    if (!isCompleted)
                      GestureDetector(
                        onTap: _isCompleting ? null : () => _completeExercise(item, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isCompleting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Complete",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}