import 'package:flutter/material.dart';
import '../app_drawer.dart';
import '../Survey/survey_screen.dart';
import '../Profile/about_you_screen.dart';
import '../Journal/journal_screen.dart';
import '../exercises_screen.dart';
import '../goal_screen.dart';
import 'home_widgets.dart'; // سنقوم بإنشاء هذا الملف في الخطوة التالية

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int surveyCount = 0;
  static const Color primaryColor = Color(0xFF67C2B9);

  // --- حساب النسبة المئوية للأهداف المكتملة ---
  // --- حساب النسبة المئوية للأهداف المكتملة من المصدر الحقيقي ---
  double get _overallProgress {
    // هنا نصل للقائمة 'allGoals' الموجودة داخل كلاس 'GoalScreen'
    // تأكدي أن القائمة في ملف goal_screen.dart مُعرفة كـ static

    // سنستخدم اسم الكلاس مباشرة للوصول للبيانات
    List<Goal> goals = GoalScreen.allGoals;

    if (goals.isEmpty) return 0.0;

    int totalSubTasks = 0;
    int completedSubTasks = 0;

    for (var goal in goals) {
      totalSubTasks += goal.totalTasks; // إجمالي المهام المطلوبة في هذا الهدف
      completedSubTasks +=
          goal.completedTasks; // ما تم إنجازه فعلياً في هذا الهدف
    }

    if (totalSubTasks == 0) return 0.0;

    // النسبة هي مجموع المنجز مقسوماً على مجموع الكلي
    return completedSubTasks / totalSubTasks;
  }

  // --- المخزن الرئيسي للبيانات (للمزامنة) ---
  List<Map<String, String>> globalJournalEntries = [
    {
      'title': 'I felt much better today',
      'content':
          'I spent some time meditating and it really helped me clear my mind from all the stress at work.',
      'date': 'Mar 02, 2026',
    },
  ];

  int get journalCount => globalJournalEntries.length;

  void _incrementSurveyCounter() {
    setState(() => surveyCount++);
  }

  void _goToJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JournalScreen(journalEntries: globalJournalEntries),
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
          // استدعاء الميثود الخاصة بالـ Notification (موجودة بالأسفل)
          _buildNotificationAction(context),
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutYouScreen()),
            ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Engi!',
              style: TextStyle(
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

            // --- الكروت الإحصائية (يتم استدعاؤها من الملف الثاني) ---
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

            // --- جزء شريط التقدم (يتم استدعاؤه من الملف الثاني) ---
            HomeWidgets.buildProgressSection(
              progress: progress,
              progressPercent: progressPercent,
              // فحص القائمة الـ static من GoalScreen
              isGoalsEmpty: GoalScreen.allGoals.isEmpty,
              primaryColor: primaryColor,
            ),

            const SizedBox(height: 30),

            // --- جزء الأنشطة الأخيرة (يتم استدعاؤها من الملف الثاني) ---
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
    );
  }

  // ميثود الـ Notification (نفس الكود والتصميم والظلال)
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
