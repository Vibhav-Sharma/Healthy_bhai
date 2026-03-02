import 'package:flutter/material.dart';

class EmergencyModeScreen extends StatelessWidget {
  const EmergencyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF2F2), // Red-50
      body: SafeArea(
        child: Stack(
          children: [
            // Red Top Accent Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                color: const Color(0xffDC2626),
              ),
            ),
            
            Column(
              children: [
                 // Top App bar inside red area
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                      const Row(
                        children: [
                           Icon(Icons.warning, color: Colors.white),
                           SizedBox(width: 8),
                           Text(
                            'EMERGENCY DATA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40), // spacer
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // Patient Emergency Identification Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ]
                            ),
                            child: Column(
                              children: [
                                 const CircleAvatar(
                                   radius: 40,
                                   backgroundColor: Color(0xffF1F5F9), // Slate 100
                                   child: Icon(Icons.person, size: 40, color: Colors.grey),
                                 ),
                                 const SizedBox(height: 16),
                                 const Text(
                                   'Jane Doe',
                                   style: TextStyle(
                                     fontSize: 24,
                                     fontWeight: FontWeight.bold,
                                     color: Color(0xff1E293B),
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   'Age: 34 • F',
                                   style: TextStyle(
                                     color: Colors.grey[600],
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                                 const SizedBox(height: 24),
                                 
                                 // Big Blood Group Display
                                 Container(
                                   padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                   decoration: BoxDecoration(
                                     color: const Color(0xffFEF2F2),
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(color: const Color(0xffFECACA)),
                                   ),
                                   child: Column(
                                     children: [
                                       Text(
                                         'BLOOD GROUP',
                                         style: TextStyle(
                                           color: Colors.red[800],
                                           fontSize: 10,
                                           fontWeight: FontWeight.bold,
                                           letterSpacing: 1,
                                         ),
                                       ),
                                       const Text(
                                         'O+',
                                         style: TextStyle(
                                           color: Color(0xffDC2626),
                                           fontSize: 32,
                                           fontWeight: FontWeight.w900,
                                         ),
                                       ),
                                     ],
                                   ),
                                 )
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Allergies Warning
                          _buildWarningCard(
                            title: 'SEVERE ALLERGIES',
                            icon: Icons.warning_amber_rounded,
                            items: ['Peanuts (Anaphylaxis)', 'Penicillin', 'Latex'],
                            color: const Color(0xffDC2626), // Red
                            bgColor: const Color(0xffFEF2F2),
                          ),
                          
                          const SizedBox(height: 16),
                          
                           // Current Conditions
                          _buildWarningCard(
                            title: 'ACTIVE DISEASES',
                            icon: Icons.coronavirus_outlined,
                            items: ['Type 2 Diabetes', 'Mild Asthma'],
                            color: Colors.orange[800]!, 
                            bgColor: Colors.orange[50]!,
                          ),
                          
                          const SizedBox(height: 16),

                          // Current Medicines
                           _buildWarningCard(
                            title: 'CURRENT MEDICINES',
                            icon: Icons.medication,
                            items: ['Metformin 500mg (Daily)', 'Albuterol Inhaler (As Needed)'],
                            color: Colors.blue[800]!, 
                            bgColor: Colors.blue[50]!,
                          ),
                          
                           const SizedBox(height: 16),
                           
                           // Emergency Contact
                           Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                               border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.phone_in_talk, color: Colors.green),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                         'EMERGENCY CONTACT',
                                         style: TextStyle(
                                           color: Colors.grey[500],
                                           fontSize: 10,
                                           fontWeight: FontWeight.bold,
                                           letterSpacing: 1,
                                         ),
                                       ),
                                       const Text(
                                         'John Doe (Husband)',
                                         style: TextStyle(
                                           fontSize: 16,
                                           fontWeight: FontWeight.bold,
                                           color: Color(0xff1E293B),
                                         ),
                                       ),
                                       Text(
                                         '+1 987 654 3210',
                                         style: TextStyle(
                                           color: Colors.grey[600],
                                           fontWeight: FontWeight.w500,
                                         ),
                                       )
                                    ],
                                  ),
                                ),
                                IconButton(onPressed: (){}, icon: const Icon(Icons.call, color: Colors.green))
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
           ...items.map((item) => Padding(
             padding: const EdgeInsets.only(bottom: 8.0, left: 4),
             child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Padding(
                   padding: const EdgeInsets.only(top: 6),
                   child: CircleAvatar(radius: 3, backgroundColor: color),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     item,
                     style: const TextStyle(
                       fontSize: 15,
                       color: Color(0xff1E293B),
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 )
               ],
             ),
           ))
        ],
      ),
    );
  }
}
