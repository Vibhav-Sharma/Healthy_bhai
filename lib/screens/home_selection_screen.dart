import 'package:flutter/material.dart';
import '../main.dart';
import 'patient_login_screen.dart';
import 'doctor_login_screen.dart';
import 'settings_screen.dart';

class HomeSelectionScreen extends StatelessWidget {
  HomeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Effects
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 60,
                  )
                ]
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
               decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.1),
                 boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ]
              ),
            ),
          ),
           // Grid Background Overlay (removed - asset doesn't exist)
          
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0, top: 8.0),
                    child: IconButton(
                      icon: Icon(
                        themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                        color: Theme.of(context).colorScheme.inverseSurface,
                      ),
                      onPressed: () {
                        themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                         // Top Icon
                        Container(
                          width: 96,
                          height: 96,
                          margin: EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              )
                            ]
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/Logo.png', width: 48, height: 48, fit: BoxFit.contain),
                          ),
                        ),
                        
                        // Header
                        Text(
                          'Swasthya',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Color(0xffDC2626),
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 8),
                         Text(
                          'DIGITAL MEDICAL RECORDS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 2,
                          ),
                        ),
                        
                        SizedBox(height: 48),
                        
                        _buildSelectionButton(
                          context,
                          title: 'Patient Login',
                          icon: Icons.person,
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PatientLoginScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        _buildSelectionButton(
                          context,
                          title: 'Doctor Login',
                          icon: Icons.medical_services,
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DoctorLoginScreen()),
                            );
                          },
                        ),
                        
                        SizedBox(height: 48),
                         Padding(
                           padding: EdgeInsets.symmetric(horizontal: 24),
                           child: Text(
                            'Securely manage your healthcare journey with encrypted digital records.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                                                   ),
                         ),
                      ],
                    ),
                  ),
                ),
                ),
                
                // Bottom Navigation Bar
                 Container(
                   decoration: BoxDecoration(
                     color: Theme.of(context).scaffoldBackgroundColor,
                     border: Border(
                       top: BorderSide(color: Colors.grey[200]!),
                     ),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.03),
                         blurRadius: 20,
                         offset: Offset(0, -5),
                       )
                     ]
                   ),
                   padding: EdgeInsets.only(top: 16, bottom: 32),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceAround,
                     children: [
                       _buildNavItem(Icons.home, 'HOME', true, () {}),
                       _buildNavItem(Icons.settings, 'SETTINGS', false, () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                       }),
                     ],
                   ),
                 )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectionButton(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 128,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xffDC2626),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
              color: Color(0xffDC2626).withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, 10),
            )
          ]
        ),
        child: Stack(
          children: [
             // Glow effects
             Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor.withOpacity(0.1),
                   boxShadow: [
                     BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 10)
                   ]
                ),
              ),
            ),
            Positioned(
              left: -24,
              bottom: -24,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor.withOpacity(0.1),
                   boxShadow: [
                     BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 10)
                   ]
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  )
                ],
              ),
            ),
             Positioned(
              bottom: 16,
              right: 20,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 24),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: isActive ? EdgeInsets.symmetric(horizontal: 16, vertical: 4) : null,
          decoration: isActive ? BoxDecoration(
             color: Colors.red.withOpacity(0.1),
             borderRadius: BorderRadius.circular(20),
          ) : null,
          child: Icon(
            icon,
            color: isActive ? Color(0xffDC2626) : Colors.grey[400],
            size: 24,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xffDC2626) : Colors.grey[400],
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 1,
          ),
        )
      ],
      ),
    );
  }
}
