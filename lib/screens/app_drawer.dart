import 'package:flutter/material.dart';
import 'Profile/about_you_screen.dart';
import 'Survey/survey_screen.dart';
import 'Journal/journal_screen.dart';
import 'exercises_screen.dart';
import 'goal_screen.dart'; 

class AppDrawer extends StatelessWidget {
  final VoidCallback onSurveyComplete;
  final List<Map<String, String>> journalEntries;
  final VoidCallback onJournalUpdated;
  final VoidCallback onGoalsUpdated;

  const AppDrawer({
    super.key,
    required this.onSurveyComplete,
    required this.journalEntries,
    required this.onJournalUpdated,
    required this.onGoalsUpdated,
  });

  static const Color primaryColor = Color(0xFF67C2B9);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: "About You",
                  destination: const AboutYouScreen(),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.list_alt_rounded,
                  title: "Surveys",
                  destination: const SurveyScreen(),
                  isSurvey: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.book_outlined,
                  title: "Journal",
                  destination: JournalScreen(journalEntries: journalEntries),
                  isJournal: true,
                ),
                // 2. ربط صفحة الأهداف (Goals)
                _buildDrawerItem(
                  context,
                  icon: Icons.flag_outlined,
                  title: "Goals",
                  destination: const GoalScreen(),
                  isGoals: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fitness_center_outlined,
                  title: "Exercises",
                  destination: const ExercisesPage(),
                  isExercises: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: "AI Chat",
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: "Community",
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.emoji_events_outlined,
                  title: "Gamification",
                ),
                const Divider(indent: 20, endIndent: 20, height: 30),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 230,
      padding: const EdgeInsets.only(top: 50, left: 25),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 37,
              backgroundImage: AssetImage('images/profile.jpeg'),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? destination,
    bool isSurvey = false,
    bool isJournal = false,
    bool isExercises = false,
    bool isGoals = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () async {
        if (destination != null) {
          Navigator.pop(context); // غلق المنيو

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );

          if (isSurvey && result == true) {
            onSurveyComplete();
          } else if (isJournal || isExercises || isGoals) {
            onGoalsUpdated();
            onJournalUpdated();
          }
        }
      },
    );
  }
}
