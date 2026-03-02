import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'patient_dashboard.dart';
import 'patient_register_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email/Patient ID and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final input = _emailController.text.trim();
      final password = _passwordController.text.trim();

      String patientId;
      if (AuthService.isPatientId(input)) {
        // Login using PatientID
        patientId = await AuthService.patientLoginWithId(
          patientId: input.toUpperCase(),
          password: password,
        );
      } else {
        // Login using email
        patientId = await AuthService.patientLogin(
          email: input,
          password: password,
        );
      }

      if (!mounted) return;

      // Navigate to dashboard, replacing the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientDashboard(patientId: patientId)),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString().replaceAll('Exception: ', '');
      // Clean up Firebase error messages
      if (msg.contains('user-not-found')) msg = 'No account found.';
      if (msg.contains('wrong-password')) msg = 'Incorrect password.';
      if (msg.contains('invalid-email')) msg = 'Invalid email address.';
      if (msg.contains('invalid-credential')) msg = 'Invalid email/ID or password.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Healthy Bhai', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                        child: const Icon(Icons.medical_services, color: Color(0xffDC2626), size: 36),
                      ),
                      const SizedBox(height: 24),
                      const Text('Patient Login', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xff1E293B), letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      const Text('Access your medical records securely', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Form
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Email
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Email or Patient ID', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                          ),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'name@example.com or HB-XXXX-XX',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.mail, color: Colors.grey[400]),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Login Button
                      _isLoading
                          ? const CircularProgressIndicator(color: Color(0xffDC2626))
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffDC2626),
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),

                      const SizedBox(height: 12),

                      // Register Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientRegisterScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: const BorderSide(color: Color(0xffDC2626)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
