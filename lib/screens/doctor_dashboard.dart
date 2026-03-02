import 'package:flutter/material.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_patient_detail_screen.dart';
class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1F5F9), // Slate-50 equivalents
      appBar: AppBar(
        backgroundColor: const Color(0xffDC2626), // Primary Red
        elevation: 2,
        shadowColor: Colors.black12,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medical_services, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'HEALTHY BHAI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.5,
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
            ),
            child: const Icon(Icons.notifications, color: Colors.white, size: 20),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME BACK,',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dr. Arjun Bhai',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0F172A),
                            letterSpacing: -0.5,
                          ),
                        )
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Column(
                        children: [
                          Text('08', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
                          Text('APPOINTMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))
                        ],
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stats Grid
                Row(
                  children: [
                    Expanded(child: _buildStatCard('PENDING', '12')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xffDC2626),
                          borderRadius: BorderRadius.circular(12),
                           boxShadow: [
                            BoxShadow(
                              color: const Color(0xffDC2626).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        ),
                        child: const Column(
                          children: [
                             Text('TODAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1)),
                             SizedBox(height: 4),
                             Text('08', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('TOTAL', '45')),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Find Patient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                            child: const Icon(Icons.person_search, color: Color(0xffDC2626), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Find Patient', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('Search database by ID or Name', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientSearchScreen()));
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                         decoration: InputDecoration(
                            hintText: 'Enter Patient ID #...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
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
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientSearchScreen()));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xffDC2626),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                         ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Patient Records Banner
                Container(
                   decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xffDC2626),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                               Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                                child: const Icon(Icons.history_edu, color: Color(0xffDC2626), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Patient Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Access medical history & labs', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: 0.75,
                                            backgroundColor: Colors.grey[100],
                                            color: const Color(0xffDC2626),
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('75% COMPLETE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                               const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                 // Note Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildNoteButton(Icons.mic, 'Voice Note', Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                       child: _buildNoteButton(Icons.edit_note, 'Text Note', Colors.green),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Up Next Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xffDC2626), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                         const Text('Up Next', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Text('VIEW ALL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildAppointmentCard(
                  context,
                  name: 'Sarah Jenkins',
                  time: '10:30 AM',
                  type: 'General Checkup',
                  id: '#9201',
                  statusColor: Colors.green,
                  statusBorderColor: Colors.green,
                  imagePlaceholder: Icons.person_2,
                ),
                const SizedBox(height: 12),
                 _buildAppointmentCard(
                  context,
                  name: 'Robert Chen',
                  time: '11:15 AM',
                  type: 'Follow-up',
                  id: 'In Lobby',
                  statusColor: Colors.amber,
                  statusBorderColor: Colors.amber,
                  imagePlaceholder: Icons.person_3,
                  isWarning: true,
                ),
                
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          ),
          
          // Custom Bottom Nav
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 15,
                     offset: const Offset(0, -5),
                   )
                 ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildNavItem(Icons.home, 'Home', true),
                   _buildNavItem(Icons.groups, 'Patients', false),
                   
                   // FAB equivalent
                   Container(
                     width: 56,
                     height: 56,
                     transform: Matrix4.translationValues(0, -16, 0),
                     decoration: BoxDecoration(
                       color: const Color(0xffDC2626),
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                             color: Colors.red.withOpacity(0.3),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                          )
                        ]
                     ),
                     child: const Icon(Icons.add, color: Colors.white, size: 28),
                   ),
                   
                   _buildNavItem(Icons.calendar_month, 'Schedule', false),
                   _buildNavItem(Icons.account_circle, 'Profile', false),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
           Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
           const SizedBox(height: 4),
           Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
        ],
      ),
    );
  }

  Widget _buildNoteButton(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
       decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
             width: 48,
             height: 48,
             decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
             child: Icon(icon, color: color[600], size: 24),
          ),
          const SizedBox(height: 12),
           Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          )
        ],
      ),
    );
  }

   Widget _buildAppointmentCard(
     BuildContext context, {
     required String name,
     required String time,
     required String type,
     required String id,
     required Color statusColor,
     required Color statusBorderColor,
     required IconData imagePlaceholder,
     bool isWarning = false,
   }) {
     return GestureDetector(
       onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientDetailScreen()));
       },
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(12),
           border: Border(
             left: BorderSide(color: statusBorderColor, width: 4),
             top: BorderSide(color: Colors.grey[100]!),
             right: BorderSide(color: Colors.grey[100]!),
             bottom: BorderSide(color: Colors.grey[100]!),
           )
         ),
       child: Row(
         children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(imagePlaceholder, color: Colors.grey[400]),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                     decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      isWarning ? Icons.priority_high : Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isWarning ? Colors.transparent : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isWarning ? Colors.grey[500] : const Color(0xffDC2626),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                         padding: isWarning ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : EdgeInsets.zero,
                         decoration: isWarning ? BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(4)) : null,
                         child: Text(
                           isWarning ? id : type,
                           style: TextStyle(
                             fontSize: 12,
                             fontWeight: isWarning ? FontWeight.bold : FontWeight.w500,
                             color: isWarning ? Colors.amber[700] : Colors.grey[600],
                             letterSpacing: isWarning ? 1 : 0,
                           ),
                         ),
                      ),
                       const SizedBox(width: 8),
                       Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                       const SizedBox(width: 8),
                         Text(
                           isWarning ? type : id,
                           style: TextStyle(
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                             color: Colors.grey[500],
                           ),
                         ),
                    ],
                  )
                ],
              ),
            )
         ],
       ),
     ),
    );
   }

   Widget _buildNavItem(IconData icon, String label, bool isActive) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(icon, color: isActive ? const Color(0xffDC2626) : Colors.grey[400], size: 24),
         const SizedBox(height: 4),
         Text(
           label,
           style: TextStyle(
             fontSize: 10,
             fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
             color: isActive ? const Color(0xffDC2626) : Colors.grey[500]
           ),
         )
       ],
     );
   }
}
