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

  // Handles updating statuses (Approve, Reject, Cancel)
  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    if (newStatus == 'Cancelled') {
      // If cancelling, ask for a reason via dialog
      TextEditingController reasonController = TextEditingController();
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a valid reason for cancellation:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Doctor unavailable, etc.'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go Back')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return; // Prevent empty reasons
                Navigator.pop(ctx, true);
              },
              child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return; // User exited dialog

      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'cancelReason': reasonController.text.trim(),
      });
      return;
    }

    // For Approve/Reject (No dialog needed)
    await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
      'status': newStatus,
    });
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0: break;
      case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientSearchScreen(doctorId: widget.doctorId))); break;
      case 2: _showProfileDialog(); break;
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doctor Profile'),
        content: Text('Doctor ID: ${widget.doctorId}\nManage your account settings.'),
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
                Text('Manage your appointments and records.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                const SizedBox(height: 32),

                // Live Appointments Stream
                const Text('Manage Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('appointments').where('doctorId', isEqualTo: widget.doctorId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No appointments yet.');

                    var appointments = snapshot.data!.docs.toList();
                    appointments.sort((a, b) => (a['appointmentDate'] as Timestamp).toDate().compareTo((b['appointmentDate'] as Timestamp).toDate()));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        var doc = appointments[index];
                        var data = doc.data() as Map<String, dynamic>;
                        
                        String appointmentId = doc.id; // Needed to update Firebase
                        String patientId = data['patientId'] ?? 'Unknown ID';
                        String status = data['status'] ?? 'Waiting';
                        String reason = data['reason'] ?? 'No reason provided';
                        DateTime date = (data['appointmentDate'] as Timestamp).toDate();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Patient: $patientId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: status == 'Waiting' ? Colors.orange.shade100 : (status == 'Upcoming' ? Colors.green.shade100 : Colors.red.shade100), borderRadius: BorderRadius.circular(8)),
                                      child: Text(status, style: TextStyle(color: status == 'Waiting' ? Colors.orange.shade800 : (status == 'Upcoming' ? Colors.green.shade800 : Colors.red.shade800), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_formatDateTime(date), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('Reason: $reason', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // --- STATUS ACTION BUTTONS ---
                                if (status == 'Waiting') 
                                  Row(
                                    children: [
                                      Expanded(child: ElevatedButton(onPressed: () => _updateAppointmentStatus(appointmentId, 'Upcoming'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Approve', style: TextStyle(color: Colors.white)))),
                                      const SizedBox(width: 12),
                                      Expanded(child: ElevatedButton(onPressed: () => _updateAppointmentStatus(appointmentId, 'Rejected'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Reject', style: TextStyle(color: Colors.white)))),
                                    ],
                                  ),
                                
                                if (status == 'Upcoming')
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _updateAppointmentStatus(appointmentId, 'Cancelled'), 
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                      child: const Text('Cancel Appointment', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),

                                if (status == 'Cancelled' && data['cancelReason'] != null)
                                  Text('Cancellation Reason: ${data['cancelReason']}', style: const TextStyle(color: Colors.red, fontSize: 12)),

                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientDetailScreen(patientId: patientId,doctorId: widget.doctorId,))),
                                  child: const Text('View Patient Profile', style: TextStyle(color: Colors.blue)),
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
          
          // Bottom nav (Hidden for brevity, it's the same as your original)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
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