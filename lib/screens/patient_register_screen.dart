import 'package:flutter/material.dart';

class PatientRegisterScreen extends StatelessWidget {
  const PatientRegisterScreen({super.key});

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
                color: Colors.blue[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: const Icon(
                Icons.assignment_ind,
                color: Colors.blue,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            
            // Titles
            const Text(
              'Create Your Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xff0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate your unique Patient ID instantly.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Form Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInputField(
                    label: 'FULL NAME',
                    prefixIcon: Icons.person_outline,
                    hintText: 'Jane Doe',
                  ),
                  const SizedBox(height: 20),
                  
                  // Age and Blood Group Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'AGE',
                          prefixIcon: Icons.cake_outlined,
                          hintText: 'e.g., 34',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          label: 'BLOOD GROUP',
                          prefixIcon: Icons.bloodtype_outlined,
                          hintText: 'e.g., O+',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputField(
                    label: 'EMERGENCY CONTACT',
                    prefixIcon: Icons.phone_outlined,
                    hintText: '+1 234 567 8900',
                    keyboardType: TextInputType.phone,
                  ),
                   const SizedBox(height: 20),

                   // Separator
                   Divider(color: Colors.grey[300], height: 32),
                  
                  _buildInputField(
                    label: 'EMAIL ADDRESS',
                    prefixIcon: Icons.mail_outline,
                    hintText: 'jane@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputField(
                    label: 'PASSWORD',
                    prefixIcon: Icons.lock_outline,
                    hintText: '••••••••',
                    isPassword: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                // Return to login for now
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
                'REGISTER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
             const SizedBox(height: 32),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xff1E293B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            prefixIcon: Icon(prefixIcon, color: Colors.grey[400]),
            suffixIcon: isPassword ? Icon(Icons.visibility, color: Colors.grey[400]) : null,
            filled: true,
            fillColor: Colors.white,
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
