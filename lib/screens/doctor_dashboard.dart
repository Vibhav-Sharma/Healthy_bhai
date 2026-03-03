import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/encryption_service.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_appointment_requests_screen.dart';
import 'doctor_patient_detail_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_crypto_service.dart';

class DoctorDashboard extends StatefulWidget {
  final String doctorId;
  DoctorDashboard({super.key, required this.doctorId});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final int _navIndex = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _allPatients = [];
  String _doctorName = 'Doctor';
  Map<String, dynamic>? _nextAppointment;
  String? _nextPatientName;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadRecentActivity();
    _loadAllPatients();
    _loadNextAppointment();
    _expireOldAppointments();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final profile = await FirestoreService.getDoctorProfile(widget.doctorId);
      if (profile != null && mounted) {
        setState(() {
          _doctorName = profile['name']?.toString() ?? 'Doctor';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNextAppointment() async {
    try {
      final next = await FirestoreService.getNextAppointment(widget.doctorId);
      if (next != null && mounted) {
        final patientId = next['patientId']?.toString() ?? '';
        String name = next['patientName']?.toString() ?? '';
        if (name.isEmpty) {
          name = await FirestoreService.getPatientName(patientId);
        }
        setState(() {
          _nextAppointment = next;
          _nextPatientName = name;
        });
      }
    } catch (_) {}
  }

  Future<void> _expireOldAppointments() async {
    try {
      await FirestoreService.expirePastAppointments(widget.doctorId, isDoctor: true);
    } catch (_) {}
  }

  Future<void> _loadAllPatients() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      if (mounted) setState(() => _allPatients = patients);
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    _loadDoctorProfile();
    _loadNextAppointment();
    _loadRecentActivity();
    _loadAllPatients();
    _expireOldAppointments();
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
    switch (index) {
      case 0: break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientSearchScreen(doctorId: widget.doctorId)));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: widget.doctorId))).then((_) => _loadDoctorProfile());
        break;
    }
  }

  void _openQRScanner() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _QRScannerPage(
        onPatientFound: (patientId) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DoctorPatientDetailScreen(patientId: patientId, doctorId: widget.doctorId),
          ));
        },
      ),
    ));
  }

  DateTime _parseDate(dynamic d) {
    if (d is Timestamp) return d.toDate();
    if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return 'Now';
    if (diff.inDays > 0) return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'in ${diff.inMinutes}m';
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} at $h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(0xffDC2626).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.health_and_safety, color: Color(0xffDC2626), size: 24),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Swasthya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xffDC2626), letterSpacing: -0.5)),
                Text('Doctor Portal • ${widget.doctorId}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorSettingsScreen(doctorId: widget.doctorId))),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xffDC2626)),
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
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome with actual name
                Text('Welcome, Dr. $_doctorName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.inverseSurface)),
                SizedBox(height: 4),
                Text('Manage your patients and records.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                SizedBox(height: 24),

                // ─── Next Appointment Card ───
                if (_nextAppointment != null)
                  _buildNextAppointmentCard(),

                if (_nextAppointment != null)
                  SizedBox(height: 24),

                // Search bar with QR scanner button
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
                            hintText: 'Search by Name, ID or Phone...',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.qr_code_scanner, color: Color(0xffDC2626)),
                              tooltip: 'Scan Patient QR',
                              onPressed: _openQRScanner,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                                padding: EdgeInsets.all(8),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: Icon(Icons.person, color: Color(0xffDC2626))),
                                    title: Text(option['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
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

                SizedBox(height: 32),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.inbox,
                        title: 'Requests',
                        subtitle: 'Pending requests',
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentRequestsScreen(doctorId: widget.doctorId))).then((_) => _refreshAll()),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Schedule',
                        subtitle: 'All appointments',
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorAppointmentsScreen(doctorId: widget.doctorId))).then((_) => _refreshAll()),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _buildStatCard('Your ID', widget.doctorId)),
                  ],
                ),

                SizedBox(height: 32),

                // Recent Activity
                Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface)),
                SizedBox(height: 16),

                if (_recentActivity.isEmpty)
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
                    child: Center(child: Text('No recent activity yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)))),
                  )
                else
                  ...(_recentActivity.map((event) {
                    final eventText = event['action'] ?? '';
                    IconData icon = Icons.event_note;
                    Color iconColor = Colors.blue[600]!;
                    Color iconBg = Colors.blue.withValues(alpha: 0.1)!;
                    if (eventText.contains('Viewed')) { icon = Icons.visibility; iconColor = Colors.green[600]!; iconBg = Colors.green.withValues(alpha: 0.1)!; }
                    else if (eventText.contains('Note')) { icon = Icons.note; iconColor = Colors.orange[600]!; iconBg = Colors.orange.withValues(alpha: 0.1)!; }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
                        child: Row(
                          children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(eventText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.inverseSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),

                SizedBox(height: 100),
              ],
            ),
          ),

          // Bottom nav
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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

  // ─── Next Appointment Widget ───
  Widget _buildNextAppointmentCard() {
    final data = _nextAppointment!;
    final date = _parseDate(data['appointmentDate']);
    final type = data['type']?.toString() ?? 'Offline';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xff3B82F6), Color(0xff1D4ED8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0xff3B82F6).withValues(alpha: 0.3), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upcoming, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Next Appointment', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(_formatCountdown(date), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(_nextPatientName ?? 'Patient', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(_formatDateTime(date), style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(width: 16),
              Icon(type == 'Online' ? Icons.videocam : Icons.local_hospital, color: Colors.white70, size: 14),
              SizedBox(width: 4),
              Text(type, style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor, )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 1)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.inverseSurface, letterSpacing: 1)),
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
          Icon(icon, color: isActive ? Theme.of(context).colorScheme.inverseSurface : Colors.grey[400], size: 24),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: isActive ? Theme.of(context).colorScheme.inverseSurface : Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── QR Scanner Page ───
class _QRScannerPage extends StatefulWidget {
  final Function(String patientId) onPatientFound;
  const _QRScannerPage({required this.onPatientFound});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _scanned = true);

    final raw = barcode.rawValue!;

    // Try encrypted QR first
    final decrypted = QrCryptoService.decrypt(raw);
    if (decrypted != null && decrypted.containsKey('patientId')) {
      Navigator.pop(context);
      widget.onPatientFound(decrypted['patientId'].toString());
      return;
    }

    // Fallback: raw text might be the patient ID directly
    if (raw.startsWith('HB-')) {
      Navigator.pop(context);
      widget.onPatientFound(raw);
      return;
    }

    // Unknown QR
    setState(() => _scanned = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Not a valid patient QR code'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Patient QR'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
