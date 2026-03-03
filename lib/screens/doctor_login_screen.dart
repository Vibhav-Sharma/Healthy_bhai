import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'doctor_dashboard.dart';
import 'doctor_register_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasStartedTypingId = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- VALIDATION LOGIC ---
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidDoctorId(String id) {
    return RegExp(r'^DR-\d{4}-[A-Z]{2}$').hasMatch(id.toUpperCase());
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email/Doctor ID and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final input = _emailController.text.trim();
      final password = _passwordController.text.trim();

      String doctorId;
      // Check if they typed an ID or an Email
      if (AuthService.isDoctorId(input)) {
        doctorId = await AuthService.doctorLoginWithId(
          doctorId: input.toUpperCase(),
          password: password,
        );
      } else {
        doctorId = await AuthService.doctorLogin(
          email: input,
          password: password,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DoctorDashboard(doctorId: doctorId)),
      );
    } catch (e) {
      if (!mounted) return;
      // Clean up Firebase error messages
      String msg = e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/invalid-credential]', '');
      if (msg.contains('user-not-found')) msg = 'No account found.';
      if (msg.contains('wrong-password')) msg = 'Incorrect password.';
      if (msg.contains('invalid-email')) msg = 'Invalid email address.';
      if (msg.trim().isEmpty) msg = 'Invalid email/ID or password.';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.trim())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final doctorId = await AuthService.doctorGoogleSignIn();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DoctorDashboard(doctorId: doctorId)),
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
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.inverseSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Swasthya', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                    child: Icon(Icons.local_hospital, color: Color(0xffDC2626), size: 36),
                  ),
                  SizedBox(height: 24),
                  Text('Doctor Login', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.inverseSurface, letterSpacing: -0.5)),
                  SizedBox(height: 8),
                  Text('Access patient records and manage notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                ],
              ),
            ),

            SizedBox(height: 32),

            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor, ),
              ),
              child: Column(
                children: [
                  // --- LIVE FEEDBACK ID/EMAIL FIELD ---
                  _buildInputField(
                    label: 'Email or Doctor ID', 
                    controller: _emailController, 
                    prefixIcon: Icons.mail, 
                    hintText: 'doctor@hospital.com or DR-XXXX-XX',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => setState(() => _hasStartedTypingId = true),
                    bottomWidget: _buildIdCriteria(),
                  ),
                  SizedBox(height: 24),
                  
                  _buildInputField(
                    label: 'Password', 
                    controller: _passwordController, 
                    prefixIcon: Icons.lock, 
                    hintText: 'Enter your password', 
                    isPassword: true
                  ),
                  SizedBox(height: 32),

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

                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorRegisterScreen())),
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
          ],
        ),
      ),
    );
  }

  // --- REAL-TIME FEEDBACK WIDGET ---
  Widget _buildIdCriteria() {
    if (!_hasStartedTypingId) return SizedBox.shrink();
    String input = _emailController.text.trim();
    bool isValid = _isValidEmail(input) || _isValidDoctorId(input);
    
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red, size: 16),
        SizedBox(width: 6),
        Text(
          isValid ? 'Valid format' : 'Enter a valid Email or DR-XXXX-XX',
          style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- STANDARD INPUT FIELD ---
  Widget _buildInputField({
    required String label, 
    required TextEditingController controller, 
    required IconData prefixIcon, 
    required String hintText, 
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    Widget? bottomWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface)),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
            filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding: EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
        if (bottomWidget != null) ...[
          SizedBox(height: 8),
          bottomWidget,
        ]
      ],
    );
  }
}