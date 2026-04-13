import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // تعريف الـ Controllers للتحكم في النصوص وإرسالها للـ API
  final _nameController = TextEditingController(text: 'Engi Eid');
  final _jobController = TextEditingController(text: 'Computer Science Student');
  final _collegeController = TextEditingController(text: 'Computer Science');
  final _ageController = TextEditingController(text: '20');
  final _emailController = TextEditingController(text: 'engi@example.com');

  static const Color primaryColor = Color(0xFF67C2B9);

  // دالة وهمية لمحاكاة استدعاء الـ API
  Future<void> _updateProfileOnAPI() async {
    // هنا سيتم وضع كود الـ http post
    // مثال:
    // var response = await http.post(Uri.parse('your-api-url'), body: {...});
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    await Future.delayed(const Duration(seconds: 2)); // محاكاة وقت الشبكة
    
    if (mounted) {
      Navigator.pop(context); // إغلاق الـ Loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: primaryColor),
      );
      Navigator.pop(context); // العودة للصفحة السابقة
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildEditField(Icons.person, 'Full Name', _nameController),
            _buildEditField(Icons.work, 'Title', _jobController),
            _buildEditField(Icons.school, 'College', _collegeController),
            _buildEditField(Icons.cake, 'Age', _ageController, isNumber: true),
            _buildEditField(Icons.email, 'Email', _emailController),
            const SizedBox(height: 40),
            
            // زر الحفظ المرتبط بالـ API
            ElevatedButton(
              onPressed: _updateProfileOnAPI,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(IconData icon, String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: primaryColor),
          prefixIcon: Icon(icon, color: primaryColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }
}