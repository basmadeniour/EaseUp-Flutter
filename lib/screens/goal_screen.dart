import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Goal {
  int? id;
  String description;
  DateTime deadline;
  int totalTasks;
  int completedTasks;
  String priority;

  Goal({
    this.id,
    required this.description,
    required this.deadline,
    required this.totalTasks,
    this.completedTasks = 0,
    required this.priority,
  });

  double get progressPercentage =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}

class GoalScreen extends StatefulWidget {
  static List<Goal> allGoals = [];
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tasksController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPriority = 'Medium';
  bool _isLoading = false;
  
  static const Color primaryColor = Color(0xFF67C2B9);
  static const String baseUrl = 'https://localhost:7057'; // غير الرابط حسب إعداداتك

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  // جلب الأهداف من الخادم
  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/Goals/my-goals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> goalsData = jsonDecode(response.body);
        setState(() {
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
        });
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

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'High': return 3;
      case 'Medium': return 2;
      default: return 1;
    }
  }

  // إضافة هدف جديد إلى الخادم
  Future<void> _addNewGoal() async {
    int tasks = int.tryParse(_tasksController.text) ?? 0;

    if (_descController.text.isEmpty || _selectedDate == null || tasks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the description, date, and number of subtasks."),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        _showErrorDialog('الرجاء تسجيل الدخول أولاً');
        setState(() => _isLoading = false);
        return;
      }

      // إنشاء قائمة المهام الفرعية
      final items = List.generate(tasks, (i) => 'مهمة ${i + 1}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/Goals/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _descController.text,
          'priority': _getPriorityValue(_selectedPriority),
          'deadline': _selectedDate?.toIso8601String(),
          'items': items,
        }),
      );

      if (response.statusCode == 200) {
        final newGoal = jsonDecode(response.body);
        
        setState(() {
          GoalScreen.allGoals.insert(
            0,
            Goal(
              id: newGoal['id'],
              description: _descController.text,
              deadline: _selectedDate!,
              totalTasks: tasks,
              priority: _selectedPriority,
            ),
          );
        });

        _descController.clear();
        _tasksController.clear();
        _selectedDate = null;
        _selectedPriority = 'Medium';
        FocusScope.of(context).unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Goal added successfully!"), backgroundColor: primaryColor),
        );
      } else {
        _showErrorDialog('فشل إضافة الهدف');
      }
    } catch (e) {
      _showErrorDialog('خطأ في الاتصال بالخادم');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // تبديل حالة مهمة فرعية
  Future<void> _toggleItem(Goal goal, int itemId, int goalId) async {
    setState(() {
      goal.completedTasks++;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl/api/Goals/toggle-item/$itemId?goalId=$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // في حالة الخطأ، نرجع الحالة السابقة
      setState(() {
        goal.completedTasks--;
      });
      _showErrorDialog('فشل تحديث المهمة');
    }
  }

  // حذف هدف
  Future<void> _deleteGoal(Goal goal, int index) async {
    if (goal.id == null) {
      setState(() {
        GoalScreen.allGoals.removeAt(index);
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) return;

      await http.delete(
        Uri.parse('$baseUrl/api/Goals/delete/${goal.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      setState(() {
        GoalScreen.allGoals.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal deleted successfully"), backgroundColor: primaryColor),
      );
    } catch (e) {
      _showErrorDialog('فشل حذف الهدف');
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsToDisplay = GoalScreen.allGoals;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: const Text(
          "My Goals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
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
            onPressed: _loadGoals,
          ),
        ],
      ),
      body: _isLoading && goalsToDisplay.isEmpty
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildAddGoalSheet(),
                const SizedBox(height: 10),
                Expanded(
                  child: goalsToDisplay.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: goalsToDisplay.length,
                          itemBuilder: (context, index) =>
                              _buildEnhancedGoalCard(goalsToDisplay[index], index),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddGoalSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: "What's your goal?",
              prefixIcon: const Icon(Icons.track_changes, color: primaryColor),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _tasksController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Subtasks",
                    prefixIcon: const Icon(Icons.list, color: primaryColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              IconButton.filled(
                onPressed: _isLoading ? null : () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: Icon(
                  _selectedDate == null ? Icons.calendar_month : Icons.check_circle,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                initialValue: _selectedPriority,
                onSelected: _isLoading ? null : (String value) =>
                    setState(() => _selectedPriority = value),
                itemBuilder: (context) => [
                  'Low',
                  'Medium',
                  'High',
                ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPriority,
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              FloatingActionButton.small(
                onPressed: _isLoading ? null : _addNewGoal,
                backgroundColor: primaryColor,
                elevation: 0,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGoalCard(Goal goal, int index) {
    bool isDone = goal.completedTasks >= goal.totalTasks;

    return Dismissible(
      key: Key(goal.id?.toString() ?? goal.description + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Goal"),
              content: Text("Are you sure you want to delete '${goal.description}'?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => _deleteGoal(goal, index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isDone ? 0.8 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDone ? Colors.green.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDone
                ? Border.all(color: Colors.green.withOpacity(0.2), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDone
                                ? "All tasks finished! 🎉"
                                : "${goal.completedTasks} of ${goal.totalTasks} tasks completed",
                            style: TextStyle(color: Colors.grey[800], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    isDone
                        ? const Icon(Icons.check_circle, color: primaryColor, size: 28)
                        : _buildPriorityBadge(goal.priority),
                  ],
                ),
                const SizedBox(height: 15),

                if (!isDone)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      color: primaryColor,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDone ? Colors.grey[800] : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Due: ${goal.deadline.day}/${goal.deadline.month}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDone ? Colors.grey[800] : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (!isDone)
                      ElevatedButton.icon(
                        onPressed: () => _toggleItem(goal, 0, goal.id ?? 0),
                        icon: const Icon(Icons.done, size: 16, color: Colors.white),
                        label: const Text(
                          "Subtask Done",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = priority == 'High'
        ? Colors.red
        : (priority == 'Medium' ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Small steps lead to big changes.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}