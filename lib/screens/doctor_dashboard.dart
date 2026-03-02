import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final String doctorId;
  const DoctorDashboard({super.key, required this.doctorId});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _navIndex = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _allPatients = [];

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
    _loadAllPatients();
  }

  Future<void> _loadAllPatients() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      if (mounted) setState(() => _allPatients = patients);
    } catch (_) {}
  }

  Future<void> _loadRecentActivity() async {
    try {
      final events = await FirestoreService.getDoctorActivity(widget.doctorId);
      if (mounted) {
        setState(() => _recentActivity = events.take(3).toList());
      }
    } catch (_) {}
  }

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
              decoration: BoxDecoration(color: const Color(0xffDC2626).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.health_and_safety, color: Color(0xffDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Healthy Bhai', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xffDC2626), letterSpacing: -0.5)),
                Text('Doctor Portal • ${widget.doctorId}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xffDC2626)),
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
                const SizedBox(height: 24),

                // Persistent Search Bar
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        final q = textEditingValue.text.toLowerCase();
                        return _allPatients.where((p) {
                          final name = (p['name'] ?? '').toString().toLowerCase();
                          final id = (p['patientId'] ?? '').toString().toLowerCase();
                          final phone = (p['phone'] ?? '').toString().toLowerCase();
                          return name.contains(q) || id.contains(q) || phone.contains(q);
                        });
                      },
                      displayStringForOption: (option) => option['name'] ?? 'Unknown',
                      onSelected: (option) async {
                        await FirestoreService.addDoctorActivity(
                          doctorId: widget.doctorId,
                          action: 'Viewed Patient ${option['patientId']}',
                        );
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => DoctorPatientDetailScreen(patientId: option['patientId']!, doctorId: widget.doctorId),
                        )).then((_) {
                          _loadRecentActivity();
                          _loadAllPatients();
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search by Patient Name, ID or Phone...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    leading: CircleAvatar(backgroundColor: Colors.red[50], child: const Icon(Icons.person, color: Color(0xffDC2626))),
                                    title: Text(option['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('ID: ${option['patientId']} • Phone: ${option['phone'] ?? 'N/A'}'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Schedule',
                        subtitle: 'View upcoming appointments',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(doctorId: widget.doctorId))),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _buildStatCard('Your ID', widget.doctorId)),
                  ],
                ),

                const SizedBox(height: 32),

                // Recent Activity Header
                const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
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
                    final eventText = event['action'] ?? '';
                    IconData icon = Icons.event_note;
                    Color iconColor = Colors.blue[600]!;
                    Color iconBg = Colors.blue[50]!;
                    if (eventText.contains('Viewed')) { icon = Icons.visibility; iconColor = Colors.green[600]!; iconBg = Colors.green[50]!; }
                    else if (eventText.contains('Note')) { icon = Icons.note; iconColor = Colors.orange[600]!; iconBg = Colors.orange[50]!; }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
                        child: Row(
                          children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(eventText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
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
