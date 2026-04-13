import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String selectedCategory = "All";
  void openVideo(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw "Could not launch $url";
    }
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
        backgroundColor: const Color(0xff64C3BF),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
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

            /// Categories
            Row(
              children: [
                category("All"),
                category("Breathing"),
                category("Meditation"),
                category("Movement"),
              ],
            ),

            const SizedBox(height: 15),

            /// Grid
            Expanded(
              child: GridView.builder(
                itemCount: filteredExercises.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final item = filteredExercises[index];
                  return exerciseCard(item);
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
          color: active ? const Color(0xff64C3BF) : Colors.grey[200],
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
  Widget exerciseCard(Map item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[100],
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
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    color: Colors.white,
                    child: Text(
                      item["time"],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                Text(
                  item["desc"],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item["tag"],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),

                    /// Complete
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff64C3BF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Complete",
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

List<Map<String, dynamic>> exercises = [
  {
    "title": "Deep Breathing",
    "desc": "Reduce stress with breathing",
    "time": "5 MINS",
    "tag": "Calming",
    "category": "Breathing",
    "image": "images/Deep Breathing.jpeg",
    "video": "https://www.youtube.com/watch?v=odADwWzHR24",
  },
  {
    "title": "Morning Meditation",
    "desc": "Start your day calm",
    "time": "10 MINS",
    "tag": "Focus",
    "category": "Meditation",
    "image": "images/Morning Meditation.jpg",
    "video": "https://www.youtube.com/watch?v=inpok4MKVLM",
  },
  {
    "title": "Forest Walk",
    "desc": "Relax in nature",
    "time": "15 MINS",
    "tag": "Refresh",
    "category": "Movement",
    "image": "images/Forest Walk.jpeg",
    "video": "https://www.youtube.com/watch?v=1ZYbU82GVz4",
  },
  {
    "title": "Mindful Stretching",
    "desc": "Release tension",
    "time": "8 MINS",
    "tag": "Flexibility",
    "category": "Movement",
    "image": "images/Mindfull Stretshing.jpeg",
    "video": "https://www.youtube.com/watch?v=v7AYKMP6rOE",
  },
  {
    "title": "Relaxation",
    "desc": "Muscle relaxation",
    "time": "7 MINS",
    "tag": "Calm",
    "category": "Meditation",
    "image": "images/Relaxation.png",
    "video": "https://www.youtube.com/watch?v=86HUcX8ZtAk",
  },
  {
    "title": "Gratitude Writing",
    "desc": "Boost positivity",
    "time": "5 MINS",
    "tag": "Mind",
    "category": "Meditation",
    "image": "images/Gratitude Writing.png",
    "video": "https://www.youtube.com/watch?v=9WgP4u5m1oY",
  },
];
