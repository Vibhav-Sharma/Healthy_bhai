import 'package:flutter/material.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6), // Gray-50
      appBar: AppBar(
        backgroundColor: const Color(0xffDC2626), // Primary Red
        elevation: 2,
        shadowColor: Colors.black12,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.monitor_heart, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Healthy Bhai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Patient Portal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xffFEE2E2), // Red-100
                  ),
                )
              ],
            )
          ],
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.notifications, color: Colors.white, size: 20),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Hello, Patient',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is your daily health summary.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Grid Options
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildGridButton(
                      icon: Icons.history_edu,
                      title: 'Medical History',
                      subtitle: 'Detailed logs of your past treatments.',
                    ),
                     _buildGridButton(
                      icon: Icons.upload_file,
                      title: 'Upload Reports',
                      subtitle: 'Add new lab results or documents.',
                    ),
                     _buildGridButton(
                      icon: Icons.local_hospital,
                      title: 'Emergency Info',
                      subtitle: 'Critical medical data for responders.',
                    ),
                     _buildGridButton(
                      icon: Icons.qr_code_2,
                      title: 'My QR Code',
                      subtitle: 'Your unique patient identifier.',
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E293B),
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xffDC2626), // Primary red
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildActivityCard(
                  icon: Icons.medication,
                  iconColor: Colors.blue[600]!,
                  iconBgColor: Colors.blue[50]!,
                  title: 'Prescription Updated',
                  subtitle: 'Dr. Sarah Smith • 2h ago',
                ),
                const SizedBox(height: 12),
                 _buildActivityCard(
                  icon: Icons.science,
                  iconColor: Colors.green[600]!,
                  iconBgColor: Colors.green[50]!,
                  title: 'Lab Results Ready',
                  subtitle: 'Blood Analysis • Yesterday',
                ),
                
                const SizedBox(height: 100), // Navigation padding
              ],
            ),
          ),
          
          // Custom Bottom Nav
          Positioned(
             bottom: 0,
             left: 0,
             right: 0,
             child: Container(
               padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
               decoration: BoxDecoration(
                 color: Colors.white,
                 border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.02),
                     blurRadius: 6,
                     offset: const Offset(0, -4),
                   )
                 ]
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    _buildNavItem(Icons.home, 'HOME', true),
                    _buildNavItem(Icons.folder_open, 'RECORDS', false),
                    _buildNavItem(Icons.medical_services, 'DOCTORS', false),
                    _buildNavItem(Icons.account_circle, 'PROFILE', false),
                 ],
               ),
             ),
          )
        ],
      ),
    );
  }

  Widget _buildGridButton({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 6,
             offset: const Offset(0, -1),
          ),
           BoxShadow(
             color: Colors.black.withOpacity(0.01),
             blurRadius: 4,
             offset: const Offset(0, 2),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[50], // Light red
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xffDC2626), size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xffDC2626),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

   Widget _buildActivityCard({
     required IconData icon,
     required Color iconColor,
     required Color iconBgColor,
     required String title,
     required String subtitle,
   }) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey[100]!),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.02),
             blurRadius: 4,
           )
         ]
       ),
       child: Row(
         children: [
           Container(
             width: 40,
             height: 40,
             decoration: BoxDecoration(
               color: iconBgColor,
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: iconColor, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: const TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.bold,
                     color: Color(0xff1E293B),
                   ),
                 ),
                 const SizedBox(height: 2),
                 Text(
                   subtitle,
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.grey[500],
                   ),
                 ),
               ],
             ),
           ),
           const Icon(Icons.chevron_right, color: Colors.grey),
         ],
       ),
     );
   }

   Widget _buildNavItem(IconData icon, String label, bool isActive) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(
           icon,
           color: isActive ? const Color(0xffDC2626) : Colors.grey[400],
           size: 24,
         ),
         const SizedBox(height: 6),
         Text(
           label,
           style: TextStyle(
             fontSize: 10,
             fontWeight: FontWeight.bold,
             letterSpacing: 1,
             color: isActive ? const Color(0xffDC2626) : Colors.grey[400],
           ),
         )
       ],
     );
   }
}
