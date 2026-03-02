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
import 'nearby_hospitals_screen.dart';
import 'book_appointment_screen.dart';
import 'prescription_scan_screen.dart';
import 'patient_settings_screen.dart';

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
  bool _isChatBotHovered = false;
  double? _fabX;
  double? _fabY;
  bool _needsMedicalDetails = false;
  Map<String, dynamic>? _patientData;

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
        setState(() {
          _patientData = data;
          _patientName = data['name'] ?? 'Patient';
          
          // Check if any medical history list is empty
          final allergies = data['allergies'] as List? ?? [];
          final pastDiseases = data['pastDiseases'] as List? ?? [];
          final currentDiseases = data['currentDiseases'] as List? ?? [];
          final chronicDiseases = data['chronicDiseases'] as List? ?? [];
          final currentMedicines = data['currentMedicines'] as List? ?? [];
          final oldMedicines = data['oldMedicines'] as List? ?? [];
          final surgeries = data['surgeries'] as List? ?? [];
          final treatments = data['treatments'] as List? ?? [];
          
          _needsMedicalDetails = allergies.isEmpty || pastDiseases.isEmpty || 
                                 currentDiseases.isEmpty || chronicDiseases.isEmpty || 
                                 currentMedicines.isEmpty || oldMedicines.isEmpty || 
                                 surgeries.isEmpty || treatments.isEmpty;
        });
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Profile'),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () {
                Navigator.pop(ctx);
                _showUpdateMedicalDetailsDialog();
              },
            ),
          ],
        ),
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
              _profileRow('Past Diseases', (data['pastDiseases'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Current Diseases', (data['currentDiseases'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Chronic Diseases', (data['chronicDiseases'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Current Medicines', (data['currentMedicines'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Past Medicines', (data['oldMedicines'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Surgeries', (data['surgeries'] as List?)?.join(', ') ?? 'None'),
              _profileRow('Treatments', (data['treatments'] as List?)?.join(', ') ?? 'None'),
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

  void _showUpdateMedicalDetailsDialog() {
    if (_patientData == null) return;

    final allergiesController = TextEditingController(text: (_patientData!['allergies'] as List?)?.join(', ') ?? '');
    final pastDiseasesController = TextEditingController(text: (_patientData!['pastDiseases'] as List?)?.join(', ') ?? '');
    final currentDiseasesController = TextEditingController(text: (_patientData!['currentDiseases'] as List?)?.join(', ') ?? '');
    final chronicDiseasesController = TextEditingController(text: (_patientData!['chronicDiseases'] as List?)?.join(', ') ?? '');
    final currentMedController = TextEditingController(text: (_patientData!['currentMedicines'] as List?)?.join(', ') ?? '');
    final oldMedController = TextEditingController(text: (_patientData!['oldMedicines'] as List?)?.join(', ') ?? '');
    final surgeriesController = TextEditingController(text: (_patientData!['surgeries'] as List?)?.join(', ') ?? '');
    final treatmentsController = TextEditingController(text: (_patientData!['treatments'] as List?)?.join(', ') ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Medical History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Separate multiple items with commas.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    TextField(controller: allergiesController, decoration: const InputDecoration(labelText: 'Allergies', prefixIcon: Icon(Icons.warning_amber_rounded, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: pastDiseasesController, decoration: const InputDecoration(labelText: 'Past Diseases (e.g., Jaundice)', prefixIcon: Icon(Icons.history, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: currentDiseasesController, decoration: const InputDecoration(labelText: 'Current Diseases (e.g., Covid)', prefixIcon: Icon(Icons.coronavirus_outlined, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: chronicDiseasesController, decoration: const InputDecoration(labelText: 'Chronic Diseases (e.g., Blood Pressure, Asthma)', prefixIcon: Icon(Icons.favorite_border, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: currentMedController, decoration: const InputDecoration(labelText: 'Current Medicines (e.g., Metformin)', prefixIcon: Icon(Icons.medication, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: oldMedController, decoration: const InputDecoration(labelText: 'Old Medicines', prefixIcon: Icon(Icons.medication_outlined, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: surgeriesController, decoration: const InputDecoration(labelText: 'Past Surgeries', prefixIcon: Icon(Icons.content_cut_outlined, size: 20))),
                    const SizedBox(height: 12),
                    TextField(controller: treatmentsController, decoration: const InputDecoration(labelText: 'Ongoing Treatments', prefixIcon: Icon(Icons.healing_outlined, size: 20))),
                  ],
                ),
              ),
            ),
            actions: [
              if (!isSaving)
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
              isSaving
                  ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffDC2626)),
                      onPressed: () async {
                        setDialogState(() => isSaving = true);

                        List<String> parseList(String text) {
                          if (text.trim().isEmpty) return [];
                          return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                        }

                        try {
                          final uid = AuthService.currentUser?.uid;
                          if (uid != null) {
                            await FirestoreService.updatePatientProfile(uid, {
                              'allergies': parseList(allergiesController.text),
                              'pastDiseases': parseList(pastDiseasesController.text),
                              'currentDiseases': parseList(currentDiseasesController.text),
                              'chronicDiseases': parseList(chronicDiseasesController.text),
                              'currentMedicines': parseList(currentMedController.text),
                              'oldMedicines': parseList(oldMedController.text),
                              'surgeries': parseList(surgeriesController.text),
                              'treatments': parseList(treatmentsController.text),
                            });
                            
                            // Log event
                            await FirestoreService.addTimelineEvent(
                              patientId: widget.patientId,
                              event: 'Updated medical history profile details.',
                            );

                            await _loadPatientData();
                            await _loadRecentActivity();
                          }
                          if (mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical history updated successfully!')));
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
                        }
                      },
                      child: const Text('Save Details', style: TextStyle(color: Colors.white)),
                    ),
            ],
          );
        }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PatientSettingsScreen(patientId: widget.patientId)));
            },
          ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('Hello, $_patientName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.inverseSurface)),
                const SizedBox(height: 4),
                Text('ID: ${widget.patientId}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),

                const SizedBox(height: 24),

                // Incomplete Profile Prompt Banner
                if (_needsMedicalDetails)
                  GestureDetector(
                    onTap: _showUpdateMedicalDetailsDialog,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xffF59E0B), Color(0xffD97706)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xffF59E0B).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Incomplete Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Add allergies, past surgeries & more for precise AI insights.', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                // Grid Options
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _buildGridButton(context, icon: Icons.document_scanner, title: 'Scan Prescription', subtitle: 'AI automatically reads your medicines.', destination: PrescriptionScanScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.calendar_month, title: 'Book Appointment', subtitle: 'Schedule a visit with your doctor.', destination: BookAppointmentScreen()),
                    _buildGridButton(context, icon: Icons.history_edu, title: 'Medical History', subtitle: 'Detailed logs of your past treatments.', destination: MedicalTimelineScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.upload_file, title: 'Upload Reports', subtitle: 'Add new lab results or documents.', destination: DocumentUploadScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.calendar_today, title: 'Appointments', subtitle: 'Book or view your schedule.', destination: PatientAppointmentsScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.local_hospital, title: 'Emergency Info', subtitle: 'Critical medical data for responders.', destination: EmergencyModeScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.qr_code_2, title: 'My QR Code', subtitle: 'Your unique patient identifier.', destination: PatientQRScreen(patientId: widget.patientId)),
                    _buildGridButton(context, icon: Icons.location_on, title: 'Nearby Hospitals', subtitle: 'Find hospitals & clinics near you.', destination: const NearbyHospitalsScreen()),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface)),
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
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
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
                    else if (eventText.contains('medicine') || eventText.contains('prescription') || eventText.contains('extracted')) { icon = Icons.medication; iconColor = Colors.teal[600]!; iconBg = Colors.teal[50]!; }


                    final dateObj = event['date'];
                    String dateStr = '';
                    if (dateObj != null) {
                      try {
                        dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format((dateObj as dynamic).toDate());
                      } catch (_) {}
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
                color: Theme.of(context).cardColor,
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

          // Draggable Assistive Touch Chatbot
          if (_fabX == null || _fabY == null)
            Positioned(
              right: 24,
              bottom: 110,
              child: _buildDraggableFab(),
            )
          else
            Positioned(
              left: _fabX,
              top: _fabY,
              child: _buildDraggableFab(),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableFab() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          if (_fabX == null || _fabY == null) {
            final size = MediaQuery.of(context).size;
            // rough estimations of starting pos if null
            _fabX = size.width - 24 - (_isChatBotHovered ? 120 : 56);
            _fabY = size.height - 110 - 56;
          }
          _fabX = _fabX! + details.delta.dx;
          _fabY = _fabY! + details.delta.dy;
        });
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isChatBotHovered = true),
        onExit: (_) => setState(() => _isChatBotHovered = false),
        child: FloatingActionButton.extended(
          elevation: 8,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantScreen(patientId: widget.patientId))),
          backgroundColor: Colors.blue,
          isExtended: _isChatBotHovered,
          icon: const Icon(Icons.smart_toy, color: Colors.white),
          label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, {required IconData icon, required String title, required String subtitle, required Widget destination}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
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
