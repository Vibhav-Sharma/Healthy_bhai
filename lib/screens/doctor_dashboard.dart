import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final String doctorId;
  const DoctorDashboard({super.key, required this.doctorId});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0: break; // HOME — already here
      case 1: // SEARCH
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientSearchScreen(doctorId: widget.doctorId)));
        break;
      case 2: // PROFILE
        _showProfileDialog();
        break;
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doctor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor ID: ${widget.doctorId}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Manage your account settings.', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper to format the Date and Time nicely
  String _formatDateTime(DateTime dateTime) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xff1E293B),
        elevation: 2,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Healthy Bhai', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Doctor Portal • ${widget.doctorId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white54)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome, Doctor', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                const SizedBox(height: 4),
                Text('Manage your patients and records.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                const SizedBox(height: 32),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.search,
                        title: 'Search Patient',
                        subtitle: 'Enter Patient ID or scan QR',
                        color: const Color(0xffDC2626),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientSearchScreen(doctorId: widget.doctorId))),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Upcoming Appointments Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upcoming Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                    Icon(Icons.calendar_month, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 16),

                // --- LIVE APPOINTMENTS STREAM ---
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('doctorId', isEqualTo: widget.doctorId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xffDC2626)));
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading appointments.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No upcoming appointments', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }

                    // Sort locally by date to avoid Firebase Indexing errors
                    var appointments = snapshot.data!.docs.toList();
                    appointments.sort((a, b) {
                      var dateA = (a['appointmentDate'] as Timestamp).toDate();
                      var dateB = (b['appointmentDate'] as Timestamp).toDate();
                      return dateA.compareTo(dateB);
                    });

                    return ListView.builder(
                      shrinkWrap: true, // Crucial for using ListView inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        var data = appointments[index].data() as Map<String, dynamic>;
                        String patientId = data['patientId'] ?? 'Unknown ID';
                        String status = data['status'] ?? 'Upcoming';
                        DateTime appointmentDate = (data['appointmentDate'] as Timestamp).toDate();

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.person, color: Colors.blue, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Patient: $patientId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1E293B))),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(_formatDateTime(appointmentDate), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // View Profile Button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorPatientDetailScreen(
                                          patientId: patientId, doctorId: widget.doctorId
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xff1E293B).withOpacity(0.05),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('View Profile', style: TextStyle(color: Color(0xff1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Bottom nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home, 'HOME', 0),
                  _buildNavItem(Icons.search, 'SEARCH', 1),
                  _buildNavItem(Icons.account_circle, 'PROFILE', 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[100]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xff1E293B), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _navIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xff1E293B) : Colors.grey[400], size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isActive ? const Color(0xff1E293B) : Colors.grey[400])),
        ],
      ),
    );
  }
}