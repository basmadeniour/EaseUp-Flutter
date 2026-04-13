import 'package:flutter/material.dart';

class SelfCareTipsScreen extends StatelessWidget {
  const SelfCareTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tips = [
      {'icon': Icons.self_improvement, 'title': 'Practice Mindfulness', 'desc': 'Spend 5 minutes focusing on your breath to reduce stress.'},
      {'icon': Icons.directions_walk, 'title': 'Stay Active', 'desc': 'A short 15-minute walk can significantly boost your mood.'},
      {'icon': Icons.bed, 'title': 'Prioritize Sleep', 'desc': 'Try to get 7-9 hours of sleep to help your brain recharge.'},
      {'icon': Icons.water_drop_outlined, 'title': 'Stay Hydrated', 'desc': 'Drinking enough water keeps your energy levels stable.'},
      {'icon': Icons.edit_note, 'title': 'Journaling', 'desc': 'Write down three things you are grateful for today.'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      appBar: AppBar(
        title: const Text('Self-Care Tips', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF67C2B9).withOpacity(0.1),
                  child: Icon(tips[index]['icon'], color: const Color(0xFF67C2B9)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tips[index]['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(tips[index]['desc'], style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}