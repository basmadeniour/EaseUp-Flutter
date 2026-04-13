import 'package:flutter/material.dart';

class Goal {
  String description;
  DateTime deadline;
  int totalTasks;
  int completedTasks;
  String priority;

  Goal({
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
  static const Color primaryColor = Color(0xFF67C2B9);

  void _addNewGoal() {
    int tasks = int.tryParse(_tasksController.text) ?? 0;

    if (_descController.text.isEmpty || _selectedDate == null || tasks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter the description, date, and number of subtasks.",
          ),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    setState(() {
      GoalScreen.allGoals.insert(
        0,
        Goal(
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
      ),
      body: Column(
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
                        _buildEnhancedGoalCard(goalsToDisplay[index]),
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
          // حقل الوصف
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

          // الصف الذي يحتوي على المهام، التاريخ، الأولوية، وزر الإضافة
          Row(
            children: [
              // عدد المهام
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

              // زر اختيار التاريخ
              IconButton.filled(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: Icon(
                  _selectedDate == null
                      ? Icons.calendar_month
                      : Icons.check_circle,
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

              // زر اختيار الأولوية (بجانب التاريخ)
              PopupMenuButton<String>(
                initialValue: _selectedPriority,
                onSelected: (String value) =>
                    setState(() => _selectedPriority = value),
                itemBuilder: (context) => [
                  'Low',
                  'Medium',
                  'High',
                ].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
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

              // زر الإضافة النهائي
              FloatingActionButton.small(
                onPressed: _addNewGoal,
                backgroundColor: primaryColor,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- بقية الـ Widgets (البطاقة، الحالة الفارغة) كما هي ---
  Widget _buildEnhancedGoalCard(Goal goal) {
    bool isDone = goal.completedTasks >= goal.totalTasks;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isDone
          ? 0.8
          : 1.0, // جعل المهام المكتملة باهتة قليلاً للتركيز على المهام الحالية
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
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey[700] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDone
                              ? "All tasks finished! 🎉"
                              : "${goal.completedTasks} of ${goal.totalTasks} tasks completed",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // إذا اكتمل الهدف تظهر علامة صح بدلاً من شارة الأولوية (اختياري)
                  isDone
                      ? const Icon(
                          Icons.check_circle,
                          color: primaryColor,
                          size: 28,
                        )
                      : _buildPriorityBadge(goal.priority),
                ],
              ),
              const SizedBox(height: 15),

              // --- منطق عرض التقدم أو كلمة Completed ---
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
                      onPressed: () => setState(() => goal.completedTasks++),
                      icon: const Icon(
                        Icons.done,
                        size: 16,
                        color: Colors.white,
                      ),
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
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
