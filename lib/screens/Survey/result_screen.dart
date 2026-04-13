import 'package:flutter/material.dart';
import 'tips_screen.dart'; // استيراد صفحة النصائح

class ResultScreen extends StatelessWidget {
  final String prediction;
  const ResultScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    String result = prediction.toLowerCase();

    Color mainColor = const Color(0xFF67C2B9);
    IconData stateIcon = Icons.wb_sunny_rounded;
    String statusTitle = "Everything is fine!";
    String description = "You're doing great! Keep maintaining your mental health and stay positive.";
    List<Color> bgGradient = [const Color(0xFFF0F9F8), Colors.white];

    if (result.contains("severe")) {
      mainColor = const Color(0xFFE57373);
      stateIcon = Icons.cloud_queue_rounded; 
      statusTitle = "We're here for you";
      description = "It seems you're going through a tough time. Please consider talking to a professional counselor who can support you.";
      bgGradient = [const Color(0xFFFFF5F5), Colors.white];
    } else if (result.contains("mild") || result.contains("moderate")) {
      mainColor = const Color(0xFFFFB74D);
      stateIcon = Icons.filter_drama_rounded;
      statusTitle = "Take a deep breath";
      description = "You might be feeling a bit overwhelmed. It's a good time for some self-care, a short walk, or some meditation.";
      bgGradient = [const Color(0xFFFFF9F2), Colors.white];
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: mainColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(stateIcon, size: 80, color: mainColor),
                ),
                const SizedBox(height: 40),
                Text(statusTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: mainColor.withOpacity(0.8))),
                const SizedBox(height: 10),
                Text(
                  prediction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                    shadows: [Shadow(color: mainColor.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54, height: 1.6)),
                ),
                const Spacer(),
                _buildActionButton(
                  label: 'Back to Home',
                  color: mainColor,
                  onPressed: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelfCareTipsScreen()),
                    );
                  },
                  child: Text("Read self-care tips", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}