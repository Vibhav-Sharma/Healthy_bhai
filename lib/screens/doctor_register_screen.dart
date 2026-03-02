import 'package:flutter/material.dart';

class DoctorRegisterScreen extends StatelessWidget {
  const DoctorRegisterScreen({super.key});

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
          'Register Practice',
          style: TextStyle(
            color: Color(0xff1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red[100]!),
              ),
              child: const Icon(
                Icons.medical_information,
                color: Color(0xffDC2626),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            
            // Titles
            const Text(
              'Join Healthy Bhai',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xff0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your doctor profile to access patients.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Form Elements
            _buildInputField(
              label: 'FULL NAME',
              prefixIcon: Icons.person_outline,
              hintText: 'Dr. John Doe',
            ),
            const SizedBox(height: 20),
            
            _buildInputField(
              label: 'EMAIL ID',
              prefixIcon: Icons.mail_outline,
              hintText: 'doctor@hospital.com',
            ),
             const SizedBox(height: 20),

             _buildInputField(
              label: 'SPECIALIZATION',
              prefixIcon: Icons.psychology,
              hintText: 'Cardiologist, General Physician, etc.',
            ),
            const SizedBox(height: 20),

             _buildInputField(
              label: 'HOSPITAL / CLINIC',
              prefixIcon: Icons.local_hospital_outlined,
              hintText: 'City General Hospital',
            ),
            const SizedBox(height: 20),
            
            _buildInputField(
              label: 'CREATE PASSWORD',
              prefixIcon: Icons.lock_outline,
              hintText: '••••••••',
              isPassword: true,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                 // Eventually registers in Firebase, for now pops back to login
                 Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffDC2626),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   'Already have an account? ',
                   style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                 ),
                 GestureDetector(
                   onTap: () => Navigator.pop(context),
                   child: const Text(
                     'Login In',
                     style: TextStyle(
                       color: Color(0xffDC2626),
                       fontSize: 14,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 )
               ],
             ),
             const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData prefixIcon,
    required String hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
            suffixIcon: isPassword ? Icon(Icons.visibility, color: Colors.grey[400]) : null,
            filled: true,
            fillColor: const Color(0xffF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
               borderSide: const BorderSide(color: Color(0xffDC2626)),
            ),
             contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        )
      ],
    );
  }
}
