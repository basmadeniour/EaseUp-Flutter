import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_drawer.dart';
import '../Survey/survey_screen.dart';
import '../Profile/about_you_screen.dart';
import '../Journal/journal_screen.dart';
import '../exercises_screen.dart';
import '../goal_screen.dart';
import 'home_widgets.dart';
import '../../config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int surveyCount = 0;
  bool _isLoading = true;
  String _userName = '';  // متغير لتخزين الاسم الأول فقط
  String? _profileImageUrl;  // ✅ إضافة متغير لصورة المستخدم
  
  static const Color primaryColor = Color(0xFF67C2B9);

  // --- المخزن الرئيسي للبيانات (للمزامنة) ---
  List<Map<String, String>> globalJournalEntries = [
    {
      'title': 'I felt much better today',
      'content':
          'I spent some time meditating and it really helped me clear my mind from all the stress at work.',
      'date': 'Mar 02, 2026',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadUserName();  // تحميل اسم المستخدم
    _loadUserProfileImage();  // ✅ تحميل صورة المستخدم
  }

  // ✅ دالة تحميل صورة المستخدم من SharedPreferences و API
  Future<void> _loadUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final studentId = prefs.getInt('student_id');
    
    if (token == null || studentId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Profile/student/profile?studentId=$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileImageUrl = data['profilePictureUrl'];
        });
      }
    } catch (e) {
      print('❌ Error loading profile image: $e');
    }
  }

  // ✅ دالة تحميل الاسم الأول فقط من SharedPreferences
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ محاولة قراءة الاسم الأول المخزن
    String firstName = prefs.getString('user_first_name') ?? '';
    
    if (firstName.isNotEmpty) {
      // تنسيق الاسم: أول حرف كبير والباقي صغير
      String formattedName = _capitalizeName(firstName);
      setState(() {
        _userName = formattedName;
      });
      print('✅ HomeScreen - First name loaded: $_userName');
    } else {
      // ❌ إذا لم يكن الاسم الأول موجوداً، استخدمي البريد الإلكتروني كبديل
      final email = prefs.getString('user_email') ?? 'User';
      String name = email.split('@').first;
      
      // تنسيق الاسم
      String formattedName = _capitalizeName(name);
      
      setState(() {
        _userName = formattedName;
      });
      print('✅ HomeScreen - Email fallback: $email, Name: $_userName');
    }
  }

  // ✅ دالة مساعدة لتنسيق الاسم (أول حرف كبير والباقي صغير)
  String _capitalizeName(String name) {
    if (name.isEmpty) return 'User';
    
    // إزالة المسافات الزائدة
    name = name.trim();
    
    // جعل أول حرف كبير والباقي صغير
    if (name.length == 1) {
      return name.toUpperCase();
    }
    
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  // تحميل الأهداف فقط
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // جلب الأهداف فقط
      final goalsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Goals/my-goals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (goalsResponse.statusCode == 200) {
        final List<dynamic> goalsData = jsonDecode(goalsResponse.body);
        
        // تحديث قائمة الأهداف في GoalScreen
        GoalScreen.allGoals = goalsData.map((g) => Goal(
          id: g['id'],
          description: g['title'] ?? '',
          deadline: g['deadline'] != null 
              ? DateTime.parse(g['deadline']) 
              : DateTime.now().add(const Duration(days: 7)),
          totalTasks: g['items']?.length ?? 0,
          completedTasks: g['items']?.where((i) => i['isCompleted'] == true).length ?? 0,
          priority: _getPriorityString(g['priority']),
        )).toList();
      }
      
    } catch (e) {
      print('خطأ في تحميل الأهداف: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPriorityString(int? priority) {
    switch (priority) {
      case 3: return 'High';
      case 2: return 'Medium';
      default: return 'Low';
    }
  }

  // --- حساب النسبة المئوية للأهداف المكتملة ---
  double get _overallProgress {
    List<Goal> goals = GoalScreen.allGoals;

    if (goals.isEmpty) return 0.0;

    int totalSubTasks = 0;
    int completedSubTasks = 0;

    for (var goal in goals) {
      totalSubTasks += goal.totalTasks;
      completedSubTasks += goal.completedTasks;
    }

    if (totalSubTasks == 0) return 0.0;

    return completedSubTasks / totalSubTasks;
  }

  int get journalCount => globalJournalEntries.length;

  void _incrementSurveyCounter() {
    setState(() => surveyCount++);
  }

  void _goToJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalScreen(journalEntries: globalJournalEntries),
      ),
    );
    setState(() {});
  }

  void _goToExercises() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExercisesPage()),
    );
    setState(() {});
  }

  void _goToSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SurveyScreen()),
    );
    if (result == true) {
      _incrementSurveyCounter();
    }
  }

  // تسجيل الخروج
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('roles');
    await prefs.remove('user_email');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_full_name');
    
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    double progress = _overallProgress;
    int progressPercent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        onSurveyComplete: _incrementSurveyCounter,
        journalEntries: globalJournalEntries,
        onJournalUpdated: () => setState(() {}),
        onGoalsUpdated: () => setState(() {}),
      ),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'EaseUp',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          _buildNotificationAction(context),
          // ✅ صورة المستخدم في AppBar
          _buildProfileAvatar(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ عرض الاسم الأول فقط
                    Text(
                      'Hello, $_userName!',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Your overview for today',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 30),

                    // --- الكروت الإحصائية ---
                    Row(
                      children: [
                        HomeWidgets.buildStatCard(
                          title: 'Survey Done',
                          value: surveyCount.toString(),
                          icon: Icons.fact_check_outlined,
                          color: Colors.orange,
                          onTap: _goToSurvey,
                        ),
                        const SizedBox(width: 15),
                        HomeWidgets.buildStatCard(
                          title: 'Journaling Done',
                          value: journalCount.toString(),
                          icon: Icons.edit_note_rounded,
                          color: Colors.purple,
                          onTap: _goToJournal,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- جزء شريط التقدم ---
                    HomeWidgets.buildProgressSection(
                      progress: progress,
                      progressPercent: progressPercent,
                      isGoalsEmpty: GoalScreen.allGoals.isEmpty,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: 30),

                    // --- جزء الأنشطة الأخيرة ---
                    const Text(
                      'Recent Activities',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    HomeWidgets.buildActivityItem(
                      title: 'Latest Survey Completed',
                      time: '2 hours ago',
                      activityIcon: Icons.assignment_turned_in_outlined,
                      onTap: _goToSurvey,
                    ),
                    HomeWidgets.buildActivityItem(
                      title: 'Latest Journal Entry Added',
                      time: '5 hours ago',
                      activityIcon: Icons.book_outlined,
                      onTap: _goToJournal,
                    ),
                    HomeWidgets.buildActivityItem(
                      title: 'Last Exercise Done',
                      time: 'Just now',
                      activityIcon: Icons.fitness_center_outlined,
                      onTap: _goToExercises,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ✅ صورة المستخدم في AppBar
  Widget _buildProfileAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutYouScreen()),
          );
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
              ? NetworkImage('${ApiConfig.baseUrl}$_profileImageUrl')
              : null,
          child: _profileImageUrl == null || _profileImageUrl!.isEmpty
              ? const Icon(Icons.person, size: 16, color: primaryColor)
              : null,
        ),
      ),
    );
  }

  // ميثود الـ Notification
  Widget _buildNotificationAction(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.2),
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.only(top: 50, right: 20),
              alignment: Alignment.topRight,
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_rounded,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "All Caught Up!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "No new notifications for now.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}