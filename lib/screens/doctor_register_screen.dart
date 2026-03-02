import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Name, Email, and Password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doctorId = await AuthService.doctorSignup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        specialization: _specializationController.text.trim(),
        hospital: _hospitalController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Registration Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Your Doctor ID is:'),
              const SizedBox(height: 8),
              SelectableText(
                doctorId,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xffDC2626), letterSpacing: 2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('GO TO LOGIN'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Register Practice', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle, border: Border.all(color: Colors.red[100]!)),
              child: const Icon(Icons.medical_information, color: Color(0xffDC2626), size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Join Healthy Bhai', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xff0F172A), letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Create your doctor profile to access patients.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 32),

            _buildInputField(label: 'FULL NAME', controller: _nameController, prefixIcon: Icons.person_outline, hintText: 'Dr. John Doe'),
            const SizedBox(height: 20),
            _buildInputField(label: 'EMAIL ID', controller: _emailController, prefixIcon: Icons.mail_outline, hintText: 'doctor@hospital.com'),
            const SizedBox(height: 20),
            _buildInputField(label: 'SPECIALIZATION', controller: _specializationController, prefixIcon: Icons.psychology, hintText: 'Cardiologist, General Physician, etc.'),
            const SizedBox(height: 20),
            _buildInputField(label: 'HOSPITAL / CLINIC', controller: _hospitalController, prefixIcon: Icons.local_hospital_outlined, hintText: 'City General Hospital'),
            const SizedBox(height: 20),
            _buildInputField(label: 'CREATE PASSWORD', controller: _passwordController, prefixIcon: Icons.lock_outline, hintText: '••••••••', isPassword: true),
            const SizedBox(height: 32),

            _isLoading
                ? const CircularProgressIndicator(color: Color(0xffDC2626))
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDC2626),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                  ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Login In', style: TextStyle(color: Color(0xffDC2626), fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required IconData prefixIcon, required String hintText, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
            suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
            filled: true, fillColor: const Color(0xffF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffDC2626))),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
