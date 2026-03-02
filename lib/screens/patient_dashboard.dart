import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'medical_timeline_screen.dart';
import 'document_upload_screen.dart';
import 'emergency_mode_screen.dart';
import 'patient_qr_screen.dart';
import 'ai_assistant_screen.dart';
import 'patient_appointments_screen.dart';

class PatientDashboard extends StatefulWidget {
  final String patientId;
  const PatientDashboard({super.key, required this.patientId});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _navIndex = 0;
  String _patientName = 'Patient';
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _loadRecentActivity();
  }

  Future<void> _loadPatientData() async {
    try {
      final data = await FirestoreService.getPatientByPatientId(widget.patientId);
      if (data != null && mounted) {
        setState(() => _patientName = data['name'] ?? 'Patient');
      }
    } catch (_) {}
  }

  Future<void> _loadRecentActivity() async {
    try {
      final events = await FirestoreService.getTimeline(widget.patientId);
      if (mounted) {
        setState(() => _recentActivity = events.take(3).toList());
      }
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0: // HOME — already here
        break;
      case 1: // RECORDS
        Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentUploadScreen(patientId: widget.patientId)));
        break;
      case 2: // TIMELINE
        Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalTimelineScreen(patientId: widget.patientId)));
        break;
      case 3: // PROFILE
        _showProfileDialog();
        break;
    }
  }

  void _showProfileDialog() async {
    final data = await FirestoreService.getPatientByPatientId(widget.patientId);
    if (!mounted || data == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My Profile'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _profileRow('Patient ID', widget.patientId),
              _profileRow('Name', data['name'] ?? '-'),
              _profileRow('Age', data['age'] ?? '-'),
              _profileRow('Blood Group', data['bloodGroup'] ?? '-'),
              _profileRow('Emergency Contact', data['emergencyContact'] ?? '-'),
              _profileRow('Allergies', (data['allergies'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Diseases', (data['diseases'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Current Medicines', (data['currentMedicines'] as List?)?.join(', ') ?? 'None'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); },
            child: const Text('Close'),
          ),
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

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.health_and_safety, color: Color(0xffDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Healthy Bhai', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xffDC2626), letterSpacing: -0.5)),
                Text('Patient Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xffDC2626)),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(patientId: widget.patientId))),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('Hello, $_patientName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                const SizedBox(height: 4),
                Text('ID: ${widget.patientId}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),

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
                    _buildGridButton(context, icon: Icons.history_edu, title: 'Medical History', subtitle: 'Detailed logs of your past treatments.', destination: MedicalTimelineScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.upload_file, title: 'Upload Reports', subtitle: 'Add new lab results or documents.', destination: DocumentUploadScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.calendar_today, title: 'Appointments', subtitle: 'Book or view your schedule.', destination: PatientAppointmentsScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.local_hospital, title: 'Emergency Info', subtitle: 'Critical medical data for responders.', destination: EmergencyModeScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.qr_code_2, title: 'My QR Code', subtitle: 'Your unique patient identifier.', destination: PatientQRScreen(patientId: widget.patientId)),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalTimelineScreen(patientId: widget.patientId))),
                      child: const Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xffDC2626))),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dynamic activity cards from Firestore
                if (_recentActivity.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
                    child: Center(child: Text('No recent activity yet.', style: TextStyle(color: Colors.grey[400]))),
                  )
                else
                  ...(_recentActivity.map((event) {
                    final eventText = event['event'] ?? '';
                    IconData icon = Icons.event_note;
                    Color iconColor = Colors.blue[600]!;
                    Color iconBg = Colors.blue[50]!;
                    if (eventText.contains('Upload')) { icon = Icons.upload_file; iconColor = Colors.green[600]!; iconBg = Colors.green[50]!; }
                    else if (eventText.contains('AI')) { icon = Icons.smart_toy; iconColor = Colors.purple[600]!; iconBg = Colors.purple[50]!; }
                    else if (eventText.contains('Note')) { icon = Icons.note; iconColor = Colors.orange[600]!; iconBg = Colors.orange[50]!; }

                    final dateObj = event['date'];
                    String dateStr = '';
                    if (dateObj != null) {
                      dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format((dateObj as dynamic).toDate());
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityCard(icon: icon, iconColor: iconColor, iconBgColor: iconBg, title: eventText, subtitle: dateStr),
                    );
                  })),

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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, -4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(Icons.home, 'HOME', 0),
                  _buildNavItem(Icons.folder_open, 'RECORDS', 1),
                  _buildNavItem(Icons.timeline, 'TIMELINE', 2),
                  _buildNavItem(Icons.account_circle, 'PROFILE', 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, {required IconData icon, required String title, required String subtitle, required Widget destination}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, -1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle), child: Icon(icon, color: const Color(0xffDC2626), size: 24)),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xffDC2626))),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey[500], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({required IconData icon, required Color iconColor, required Color iconBgColor, required String title, required String subtitle}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalTimelineScreen(patientId: widget.patientId))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
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
          Icon(icon, color: isActive ? const Color(0xffDC2626) : Colors.grey[400], size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isActive ? const Color(0xffDC2626) : Colors.grey[400])),
        ],
      ),
    );
  }
}
