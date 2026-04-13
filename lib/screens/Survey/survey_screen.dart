import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_screen.dart'; // استيراد صفحة النتيجة

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  final Map<int, int?> _answers = {};
  bool _isLoading = false;
  int _currentPage = 0;
  static const Color primaryColor = Color(0xFF67C2B9);

  final List<String> _questions = [
    "How often have you had little interest or pleasure in doing things?",
    "How often have you been feeling down, depressed or hopeless?",
    "How often have you had trouble falling or staying asleep, or sleeping too much?",
    "How often have you been feeling tired or having little energy?",
    "How often have you had poor appetite or overeating?",
    "How often have you been feeling bad about yourself - or that you are a failure or have let yourself or your family down?",
    "How often have you been having trouble concentrating on things, such as reading the books or watching television?",
    "How often have you moved or spoke too slowly for other people to notice?",
    "How often have you had thoughts that you would be better off dead, or of hurting yourself?",
  ];

  final List<String> _options = [
    "Not at all",
    "Several days",
    "More than half the days",
    "Nearly every day",
  ];

  Future<void> _submitAndPredict() async {
    setState(() => _isLoading = true);

    Map<String, String> dataToSend = {};
    for (int i = 0; i < _questions.length; i++) {
      int selectedIndex = _answers[i] ?? 0;
      dataToSend["Q${i + 19}"] = _options[selectedIndex];
    }

    try {
      final url = Uri.parse('https://shrieky-stephan-uncontemned.ngrok-free.dev/predict');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (!mounted) return;

        final bool? finished = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(prediction: result['prediction'].toString()),
          ),
        );

        if (finished == true) {
          if (!mounted) return;
          Navigator.pop(context, true); 
        }
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      _showErrorSnackBar("Connection Error: Check your server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() => _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    double progress = _answers.length / _questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Weekly Survey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: _previousPage)
            : null,
        actions: [
          if (_currentPage < _questions.length - 1)
            IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white), onPressed: _nextPage),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: const Color.fromARGB(255, 194, 193, 193),
              color: const Color.fromARGB(255, 236, 243, 230),
              minHeight: 8,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemCount: _questions.length,
              itemBuilder: (context, index) => _buildQuestionPage(index),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int qIndex) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("QUESTION ${qIndex + 1}", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          Text(_questions[qIndex], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 40),
          ...List.generate(_options.length, (optIndex) => _buildOptionTile(qIndex, optIndex)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int qIndex, int optIndex) {
    bool isSelected = _answers[qIndex] == optIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _answers[qIndex] = optIndex);
        Future.delayed(const Duration(milliseconds: 300), _nextPage);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 15),
            Expanded(
              child: Text(_options[optIndex], style: TextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    bool isLastPage = _currentPage == _questions.length - 1;
    bool hasAnsweredCurrent = _answers.containsKey(_currentPage);
    return Padding(
      padding: const EdgeInsets.all(30),
      child: isLastPage
          ? ElevatedButton(
              onPressed: (hasAnsweredCurrent && !_isLoading) ? _submitAndPredict : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get Results', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : const SizedBox.shrink(),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }
}