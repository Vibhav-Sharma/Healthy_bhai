import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'doctor_dashboard.dart';
import '../services/auth_service.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedSpecialty = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Track if user has started typing to show live feedback
  bool _hasStartedTypingPhone = false;
  bool _hasStartedTypingPassword = false;

  final List<String> _specialtiesList = [
    'General Physician', 'Internal Medicine', 'Family Medicine', 'Emergency Medicine', 'Intensive Care (ICU)',
    'Cardiology', 'Neurology', 'Pulmonology', 'Gastroenterology', 'Nephrology', 'Urology', 'Hepatology', 'Endocrinology',
    'Orthopedics', 'Rheumatology', 'Physiotherapy', 'Sports Medicine', 'Chiropractic', 'Podiatry',
    'Gynaecology', 'Obstetrics', 'Pediatrics', 'Neonatology',
    'ENT (Ear, Nose, Throat)', 'Ophthalmology', 'Optometry', 'Audiology', 'Dental Care', 'Dermatology',
    'General Surgery', 'Cardiac Surgery', 'Vascular Surgery', 'Plastic Surgery', 'Bariatric Surgery', 'Anesthesiology',
    'Oncology (Cancer)', 'Hematology', 'Infectious Disease', 'Allergy & Immunology', 'Pathology', 'Medical Genetics', 'Radiology',
    'Psychiatry', 'Nutrition & Dietetics', 'Speech Therapy', 'Occupational Therapy', 'Pain Management', 'Sleep Medicine', 'Acupuncture', 'Alternative Medicine',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- VALIDATION LOGIC ---
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

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedSpecialty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a specialty.')),
      );
      return;
    }

    if (!_isValidPhone(_phoneController.text.trim()) || !_isPasswordStrong(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in your phone number or password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Send all the data to your updated AuthService
      String newDoctorId = await AuthService.doctorSignup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        specialty: _selectedSpecialty,
      );

      if (!mounted) return;
      
      // 2. Show a success message with their new auto-generated ID!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Successful! Your ID is $newDoctorId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      
      // 3. Navigate back to login screen so they can log in
      Navigator.pop(context); 
      
    } catch (e) {
      if (!mounted) return;
      // Clean up the Firebase error message so it looks nice
      String msg = e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/email-already-in-use]', '');
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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Healthy Bhai', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red[100]!)),
                    child: const Icon(Icons.person_add, color: Color(0xffDC2626), size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text('Doctor Registration', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xff1E293B), letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Join the Healthy Bhai medical network', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInputField(label: 'Full Name', controller: _nameController, prefixIcon: Icons.person, hintText: 'Dr. John Doe'),
                  const SizedBox(height: 24),
                  
                  _buildInputField(label: 'Email Address', controller: _emailController, prefixIcon: Icons.mail, hintText: 'doctor@hospital.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),

                  // --- PHONE FIELD WITH LIVE VALIDATION ---
                  _buildInputField(
                    label: 'Phone Number', 
                    controller: _phoneController, 
                    prefixIcon: Icons.phone, 
                    hintText: '10-digit mobile number', 
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => setState(() => _hasStartedTypingPhone = true),
                    bottomWidget: _buildPhoneCriteria(),
                  ),
                  const SizedBox(height: 24),

                  // --- DYNAMIC HEIGHT SPECIALTY SEARCH ---
                  _buildSpecialtySearchBox(),
                  const SizedBox(height: 24),
                  
                  // --- PASSWORD FIELD WITH LIVE VALIDATION ---
                  _buildInputField(
                    label: 'Password', 
                    controller: _passwordController, 
                    prefixIcon: Icons.lock, 
                    hintText: 'Create a strong password', 
                    isPassword: true,
                    onChanged: (val) => setState(() => _hasStartedTypingPassword = true),
                    bottomWidget: _buildPasswordCriteria(),
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
                          child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                ],
              ),
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
    bool isValid = _isValidPhone(_phoneController.text.trim());
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

  // --- AUTOCOMPLETE SPECIALTY WIDGET ---
  Widget _buildSpecialtySearchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Specialty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _specialtiesList.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedSpecialty = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type to search 50 specialties...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.medical_services, color: Colors.grey[400]),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    // This ConstrainedBox allows the height to dynamically shrink or grow!
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: 250, // Stops growing and becomes scrollable if list is too long
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true, // Crucial! Tells the list to shrink to fit the number of items
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(option, style: const TextStyle(color: Color(0xff1E293B))),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          }
        ),
      ],
    );
  }

  // STANDARD INPUT FIELD 
  Widget _buildInputField({
    required String label, 
    required TextEditingController controller, 
    required IconData prefixIcon, 
    required String hintText, 
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged, // Allows real-time tracking
    Widget? bottomWidget, // Allows us to pass the Green/Red text below the field
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
            suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
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