import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _allergiesController = TextEditingController();
  final _pastDiseasesController = TextEditingController();
  final _currentDiseasesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _currentMedicinesController = TextEditingController();
  final _oldMedicinesController = TextEditingController();
  final _surgeriesController = TextEditingController();
  final _treatmentsController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Track if user has started typing to show live feedback
  bool _hasStartedTypingPhone = false;
  bool _hasStartedTypingPassword = false;
  bool _hasStartedTypingEmail = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyContactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _allergiesController.dispose();
    _pastDiseasesController.dispose();
    _currentDiseasesController.dispose();
    _chronicDiseasesController.dispose();
    _currentMedicinesController.dispose();
    _oldMedicinesController.dispose();
    _surgeriesController.dispose();
    _treatmentsController.dispose();
    super.dispose();
  }

  // --- VALIDATION LOGIC (copied from Doctor Registration) ---
  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#\$&*~]'))) return false;
    return true;
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  Future<void> _register() async {
    // Validate all required fields
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _emergencyContactController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (!_isValidPhone(_emergencyContactController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be exactly 10 digits.')),
      );
      return;
    }

    if (!_isPasswordStrong(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in your password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patientId = await AuthService.patientSignup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        height: _heightController.text.trim(),
        weight: _weightController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        allergies: _allergiesController.text.trim(),
        pastDiseases: _pastDiseasesController.text.trim(),
        currentDiseases: _currentDiseasesController.text.trim(),
        chronicDiseases: _chronicDiseasesController.text.trim(),
        currentMedicines: _currentMedicinesController.text.trim(),
        oldMedicines: _oldMedicinesController.text.trim(),
        surgeries: _surgeriesController.text.trim(),
        treatments: _treatmentsController.text.trim(),
      );

      if (!mounted) return;

      // Show success dialog with PatientID
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
              const Text('Your Patient ID is:'),
              const SizedBox(height: 8),
              SelectableText(
                patientId,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xffDC2626),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save this ID! Doctors will use it to access your records.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // go back to login
              },
              child: const Text('GO TO LOGIN'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Clean up the Firebase error message so it looks nice
      String msg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('[firebase_auth/email-already-in-use]', 'This email is already registered. Please use a different email or log in.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.trim())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Registration',
          style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[50], shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: const Icon(Icons.assignment_ind, color: Colors.blue, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Create Your Profile',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xff0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            const Text('Generate your unique Patient ID instantly.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInputField(label: 'FULL NAME', controller: _nameController, prefixIcon: Icons.person_outline, hintText: 'Jane Doe'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: 'AGE', controller: _ageController, prefixIcon: Icons.cake_outlined, hintText: 'e.g., 34', keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(label: 'BLOOD GROUP', controller: _bloodGroupController, prefixIcon: Icons.bloodtype_outlined, hintText: 'e.g., O+')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(label: 'WEIGHT (kg)', controller: _weightController, prefixIcon: Icons.monitor_weight_outlined, hintText: 'e.g., 70', keyboardType: TextInputType.number),
                  const SizedBox(height: 20),
                  _buildInputField(label: 'HEIGHT (cm)', controller: _heightController, prefixIcon: Icons.height, hintText: 'e.g., 170', keyboardType: TextInputType.number),
                  const SizedBox(height: 20),

                  // --- PHONE FIELD WITH LIVE VALIDATION ---
                  _buildInputField(
                    label: 'EMERGENCY CONTACT',
                    controller: _emergencyContactController,
                    prefixIcon: Icons.phone_outlined,
                    hintText: '10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => setState(() => _hasStartedTypingPhone = true),
                    bottomWidget: _buildPhoneCriteria(),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey[300], height: 32),

                  // --- EMAIL FIELD WITH LIVE VALIDATION ---
                  _buildInputField(
                    label: 'EMAIL ADDRESS',
                    controller: _emailController,
                    prefixIcon: Icons.mail_outline,
                    hintText: 'jane@example.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => setState(() => _hasStartedTypingEmail = true),
                    bottomWidget: _buildEmailCriteria(),
                  ),
                  const SizedBox(height: 20),

                  // --- PASSWORD FIELD WITH LIVE VALIDATION ---
                  _buildInputField(
                    label: 'PASSWORD',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    hintText: 'Create a strong password',
                    isPassword: true,
                    onChanged: (val) => setState(() => _hasStartedTypingPassword = true),
                    bottomWidget: _buildPasswordCriteria(),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey[300], height: 32),
                  const Text('MEDICAL HISTORY (OPTIONAL)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  
                  _buildInputField(label: 'ALLERGIES', controller: _allergiesController, prefixIcon: Icons.warning_amber_rounded, hintText: 'Any known allergies?'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: 'PAST DISEASES', controller: _pastDiseasesController, prefixIcon: Icons.history, hintText: 'E.g., Jaundice')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(label: 'CURRENT DISEASES', controller: _currentDiseasesController, prefixIcon: Icons.coronavirus_outlined, hintText: 'E.g., Diabetes')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(label: 'CHRONIC DISEASES', controller: _chronicDiseasesController, prefixIcon: Icons.favorite_border, hintText: 'E.g., Blood Pressure, Asthma'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: 'CURRENT MEDICINES', controller: _currentMedicinesController, prefixIcon: Icons.medication, hintText: 'E.g., Metformin')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(label: 'OLD MEDICINES', controller: _oldMedicinesController, prefixIcon: Icons.medication_outlined, hintText: 'Past medications')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInputField(label: 'PAST SURGERIES', controller: _surgeriesController, prefixIcon: Icons.content_cut_outlined, hintText: 'E.g., Appendectomy')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(label: 'TREATMENTS', controller: _treatmentsController, prefixIcon: Icons.healing_outlined, hintText: 'E.g., Physiotherapy')),
                    ],
                  ),
                ],
              ),
            ),

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
                    child: const Text('REGISTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- REAL-TIME FEEDBACK WIDGETS ---
  Widget _buildPhoneCriteria() {
    if (!_hasStartedTypingPhone) return const SizedBox.shrink();
    bool isValid = _isValidPhone(_emergencyContactController.text.trim());
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(
          isValid ? 'Valid phone number' : 'Must be exactly 10 digits',
          style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmailCriteria() {
    if (!_hasStartedTypingEmail) return const SizedBox.shrink();
    bool isValid = _isValidEmail(_emailController.text.trim());
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(
          isValid ? 'Valid email address' : 'Please enter a valid email address',
          style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPasswordCriteria() {
    if (!_hasStartedTypingPassword) return const SizedBox.shrink();
    bool isStrong = _isPasswordStrong(_passwordController.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isStrong ? Icons.check_circle : Icons.cancel, color: isStrong ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isStrong ? 'Strong password' : 'Must be 8+ chars, include A-Z, a-z, 0-9, and a symbol (!@#\$&*~)',
            style: TextStyle(color: isStrong ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ),
      ],
    );
  }

  // --- STANDARD INPUT FIELD (with onChanged + bottomWidget support) ---
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff1E293B), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
            suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffDC2626))),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (bottomWidget != null) ...[
          const SizedBox(height: 8),
          bottomWidget,
        ]
      ],
    );
  }
}
