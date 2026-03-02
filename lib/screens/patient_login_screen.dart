import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'patient_dashboard.dart';
import 'patient_register_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  PatientLoginScreen({super.key});

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
        SnackBar(content: Text('Please enter email/Patient ID and password.')),
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

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final patientId = await AuthService.patientGoogleSignIn();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PatientDashboard(patientId: patientId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.inverseSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Healthy Bhai', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                        child: Icon(Icons.medical_services, color: Color(0xffDC2626), size: 36),
                      ),
                      SizedBox(height: 24),
                      Text('Patient Login', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.inverseSurface, letterSpacing: -0.5)),
                      SizedBox(height: 8),
                      Text('Access your medical records securely', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Form
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor, ),
                  ),
                  child: Column(
                    children: [
                      // Email
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Email or Patient ID', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface)),
                          ),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'name@example.com or HB-XXXX-XX',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                              prefixIcon: Icon(Icons.mail, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                              filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                              contentPadding: EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface)),
                          ),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                              prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                              suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                              contentPadding: EdgeInsets.symmetric(vertical: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Login Button
                      _isLoading
                          ? CircularProgressIndicator(color: Color(0xffDC2626))
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffDC2626),
                                minimumSize: Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),

                      SizedBox(height: 12),

                      // Register Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PatientRegisterScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          side: BorderSide(color: Color(0xffDC2626)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Sloth jumping animation
                Center(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.22,
                    child: Lottie.network(
                      'https://assets9.lottiefiles.com/packages/lf20_vPnn3K.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
