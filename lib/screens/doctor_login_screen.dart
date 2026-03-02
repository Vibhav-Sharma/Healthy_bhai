import 'package:flutter/material.dart';

class DoctorLoginScreen extends StatelessWidget {
  const DoctorLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background grid pattern simulation
          Positioned.fill(
              child: Opacity(
            opacity: 0.05,
            child: Container(
              color: Colors.transparent, // Let grid shine through
            ),
          )),
          SafeArea(
            child: Column(
              children: [
                // Top app bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.grey, size: 20),
                      ),
                      const Text(
                        'Healthy Bhai',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[100]!),
                            boxShadow: [
                               BoxShadow(
                                color: const Color(0xffDC2626).withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Color(0xffDC2626),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Titles
                        const Text(
                          'Doctor Login',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Secure access to patient records',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[100]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                label: 'EMAIL ID',
                                prefixIcon: Icons.mail,
                                hintText: 'doctor@healthybhai.com',
                              ),
                              const SizedBox(height: 24),
                              _buildInputField(
                                label: 'PASSWORD',
                                prefixIcon: Icons.lock_open,
                                hintText: '••••••••',
                                isPassword: true,
                              ),
                              
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Checkbox(
                                          value: false,
                                          onChanged: (v) {},
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          side: BorderSide(color: Colors.grey[300]!),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xffDC2626),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffDC2626),
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'ACCESS DASHBOARD',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Fast Login Section
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[200])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'FAST LOGIN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[400],
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                             Expanded(child: Divider(color: Colors.grey[200])),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                         Row(
                           children: [
                             Expanded(
                               child: _buildBiometricButton(
                                 icon: Icons.fingerprint,
                                 label: 'Touch ID',
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: _buildBiometricButton(
                                 icon: Icons.face,
                                 label: 'Face ID',
                               ),
                             )
                           ],
                         ),
                         
                         const SizedBox(height: 32),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text(
                               'New to Healthy Bhai? ',
                               style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                             ),
                             const Text(
                               'Register Practice',
                               style: TextStyle(
                                 color: Color(0xffDC2626),
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                               ),
                             )
                           ],
                         ),
                          const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
           // Bottom Fade
           Positioned(
             bottom: 0,
             left: 0,
             right: 0,
             child: Container(
               height: 96,
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.bottomCenter,
                   end: Alignment.topCenter,
                   colors: [
                     Colors.white,
                     Colors.white.withOpacity(0),
                   ]
                 )
               ),
             ),
           )
        ],
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

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          )
        ],
      ),
    );
  }
}
