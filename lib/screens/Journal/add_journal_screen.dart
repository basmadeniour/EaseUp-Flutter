import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddJournalScreen extends StatefulWidget {
  const AddJournalScreen({super.key});

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  // نحتاج الآن لمتحكمين (Controllers) واحد للعنوان وواحد للمحتوى
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  static const Color primaryColor = Color(0xFF67C2B9);

  void _saveEntry() {
    // التحقق من أن الحقلين ليسوا فارغين
    if (_titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty) {
      String title = _titleController.text.trim();
      String content = _contentController.text.trim();
      String today = DateFormat('MMM dd, yyyy').format(DateTime.now());

      Navigator.pop(context, {
        'title': title,
        'content': content,
        'date': today,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in both title and content"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ... (نفس الـ Imports والـ Controller)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'New Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        // حذفنا الزر من هنا لمزيد من الهدوء البصري
      ),
      body: Column(
        children: [
          // شريط التاريخ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: primaryColor.withOpacity(0.05),
            width: double.infinity,
            child: Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "Entry Title",
                      hintStyle: TextStyle(color: Colors.grey[300]),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18, height: 1.6),
                    decoration: InputDecoration(
                      hintText: "Write your thoughts here...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                  ), // مسافة أمان لكي لا يغطي الزر على النص
                ],
              ),
            ),
          ),
        ],
      ),
      // --- زر الـ Done الجديد والمحسن ---
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat, // ليكون في المنتصف
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEntry,
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          "Save My Story",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
