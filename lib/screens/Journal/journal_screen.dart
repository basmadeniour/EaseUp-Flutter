import 'package:flutter/material.dart';
import 'journal_detail_screen.dart';
import 'add_journal_screen.dart';

class JournalScreen extends StatefulWidget {
  final List<Map<String, String>> journalEntries;

  const JournalScreen({super.key, required this.journalEntries});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const Color primaryColor = Color(0xFF67C2B9);

  void _addNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddJournalScreen()),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        widget.journalEntries.insert(0, result);
      });
    }
  }

  // دالة لحذف التدوينة
  void _deleteEntry(int index) {
    setState(() {
      widget.journalEntries.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entry deleted"), behavior: SnackBarBehavior.floating),
    );
  }

@override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(widget.journalEntries.length);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFB),
        appBar: AppBar(
          title: const Text('My Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color.fromRGBO(103, 194, 185, 1),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(widget.journalEntries.length),
          ),
        ),
        body: widget.journalEntries.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: widget.journalEntries.length,
                itemBuilder: (context, index) {
                  final entry = widget.journalEntries[index];
                  
                  // منطق الفصل حسب الشهور:
                  // نتحقق إذا كانت التدوينة الحالية في شهر مختلف عن التدوينة السابقة
                  bool showHeader = false;
                  if (index == 0) {
                    showHeader = true; // دائماً اظهر العنوان لأول عنصر
                  } else {
                    final prevEntry = widget.journalEntries[index - 1];
                    // نقارن التاريخ (بافتراض أن التاريخ مخزن بصيغة MMM dd, yyyy)
                    // سنستخرج الشهر والسنة للمقارنة
                    if (_extractMonthYear(entry['date']!) != _extractMonthYear(prevEntry['date']!)) {
                      showHeader = true;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) _buildSectionHeader(_extractMonthYear(entry['date']!)),
                      _buildDismissibleCard(index),
                    ],
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addNewEntry,
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note_rounded, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "Your story starts here...",
            style: TextStyle(color: Colors.grey[600], fontSize: 18, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // كارت يدعم المسح بالسحب (Swipe to Delete)
  Widget _buildDismissibleCard(int index) {
    final entry = widget.journalEntries[index];
    return Dismissible(
      key: Key(entry['title']! + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) => _deleteEntry(index),
      child: _buildJournalCard(entry),
    );
  }

  Widget _buildJournalCard(Map<String, String> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          entry['title']!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
        ),
        subtitle: Text(
          entry['date']!,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailScreen(
                title: entry['title']!,
                content: entry['content']!,
              ),
            ),
          );
        },
      ),
    );
  }

String _extractMonthYear(String dateStr) {
    // التاريخ عندك بصيغة "Apr 13, 2026"
    // سنأخذ أول جزء (الشهر) وآخر جزء (السنة)
    final parts = dateStr.split(' ');
    if (parts.length >= 3) {
      return "${parts[0]} ${parts[2]}"; // يرجع "Apr 2026"
    }
    return dateStr;
  }

  // واجهة الفاصل الزمني (Header)
  Widget _buildSectionHeader(String monthYear) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Row(
        children: [
          Text(
            monthYear.toUpperCase(),
            style: TextStyle(
              color: primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }}