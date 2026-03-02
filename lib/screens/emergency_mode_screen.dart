import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class EmergencyModeScreen extends StatefulWidget {
  final String? patientId;
  EmergencyModeScreen({super.key, this.patientId});

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen> {
  bool _isLoading = true;
  String _name = 'Unknown';
  String _age = '—';
  String _bloodGroup = '—';
  List<String> _allergies = [];
  List<String> _diseases = [];
  List<String> _medicines = [];
  String _emergencyContact = '—';

  // Location state
  bool _locationLoading = false;
  String? _locationText;
  String? _locationLink;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchLocation(); // Auto-fetch location on screen open
  }

  Future<void> _loadData() async {
    try {
      if (widget.patientId != null) {
        final data = await FirestoreService.getPatientByPatientId(widget.patientId!);
        if (data != null) {
          _name = data['name'] ?? 'Unknown';
          _age = data['age']?.toString() ?? '—';
          _bloodGroup = data['bloodGroup'] ?? '—';
          _allergies = List<String>.from(data['allergies'] ?? []);
          _diseases = List<String>.from(data['diseases'] ?? []);
          _medicines = List<String>.from(data['currentMedicines'] ?? []);
          _emergencyContact = data['emergencyContact'] ?? '—';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('emergency_name', _name);
          await prefs.setString('emergency_age', _age);
          await prefs.setString('emergency_bloodGroup', _bloodGroup);
          await prefs.setStringList('emergency_allergies', _allergies);
          await prefs.setStringList('emergency_diseases', _diseases);
          await prefs.setStringList('emergency_medicines', _medicines);
          await prefs.setString('emergency_contact', _emergencyContact);
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        _name = prefs.getString('emergency_name') ?? 'Unknown';
        _age = prefs.getString('emergency_age') ?? '—';
        _bloodGroup = prefs.getString('emergency_bloodGroup') ?? '—';
        _allergies = prefs.getStringList('emergency_allergies') ?? [];
        _diseases = prefs.getStringList('emergency_diseases') ?? [];
        _medicines = prefs.getStringList('emergency_medicines') ?? [];
        _emergencyContact = prefs.getString('emergency_contact') ?? '—';
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('emergency_name') ?? 'No Data';
      _bloodGroup = prefs.getString('emergency_bloodGroup') ?? '—';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Location ─────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _locationText = LocationService.formatPosition(position);
          _locationLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _locationLoading = false;
        });
      }
    }
  }

  // ─── Call Ambulance ───────────────────────────────────────

  // ⚠️ CHANGE THIS NUMBER for production — replace with 108
  static const String _ambulanceNumber = '108';

  Future<void> _callAmbulance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text('🚑', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(child: Text('Call Ambulance?')),
          ],
        ),
        content: Text(
          'This will open your phone dialer with number $_ambulanceNumber.',
          style: TextStyle(fontSize: 14, color: Color(0xff64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xffDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Call $_ambulanceNumber'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri(scheme: 'tel', path: _ambulanceNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer.'), backgroundColor: Color(0xffDC2626)),
          );
        }
      }
    }
  }

  // ─── Share Location ───────────────────────────────────────

  Future<void> _shareLocation() async {
    if (_locationLink == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not available yet. Please wait or tap Retry.'), backgroundColor: Color(0xffDC2626)),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('📍 My Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
              child: SelectableText(_locationLink!, style: TextStyle(fontSize: 13, color: Color(0xff3B82F6))),
            ),
            SizedBox(height: 8),
            Text(_locationText ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse(_locationLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(Icons.map),
              label: Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 10),
            // SMS with location
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final smsUri = Uri(
                  scheme: 'sms',
                  path: '',
                  queryParameters: {'body': 'I need help! My location: $_locationLink'},
                );
                if (await canLaunchUrl(smsUri)) {
                  await launchUrl(smsUri);
                }
              },
              icon: Icon(Icons.sms),
              label: Text('Send via SMS'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: Container(height: 200, color: Color(0xffDC2626))),
            Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 8),
                          Text('EMERGENCY DATA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ═══ QUICK ACTIONS (at TOP for visibility) ═══
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Color(0xffFECACA)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.red.withOpacity(0.08), blurRadius: 16, offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Color(0xffFEF2F2), borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.emergency, color: Color(0xffDC2626), size: 20),
                                          ),
                                          SizedBox(width: 12),
                                          Text('QUICK ACTIONS', style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      // Call Ambulance
                                      _buildActionButton(
                                        emoji: '🚑', label: 'Call Ambulance', subtitle: 'Dial $_ambulanceNumber for emergency',
                                        gradient: const [Color(0xffDC2626), Color(0xffB91C1C)],
                                        onTap: _callAmbulance,
                                      ),
                                      SizedBox(height: 12),
                                      // Share Location
                                      _buildActionButton(
                                        emoji: '📍', label: 'Share My Location', subtitle: 'Send GPS coordinates via SMS / Maps',
                                        gradient: const [Color(0xff2563EB), Color(0xff1D4ED8)],
                                        onTap: _shareLocation,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 16),

                                // ═══ MY CURRENT LOCATION ═══
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Icon(Icons.my_location, color: Colors.blue[700], size: 20),
                                          ),
                                          SizedBox(width: 12),
                                          Text('MY CURRENT LOCATION', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                                          Spacer(),
                                          if (!_locationLoading)
                                            GestureDetector(
                                              onTap: _fetchLocation,
                                              child: Icon(Icons.refresh, color: Colors.blue[400], size: 20),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      if (_locationLoading)
                                        Row(
                                          children: [
                                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600])),
                                            SizedBox(width: 10),
                                            Text('Getting your location...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                                          ],
                                        )
                                      else if (_locationError != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_locationError!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                                            SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: _fetchLocation,
                                              child: Text('Tap to retry', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w600, fontSize: 13)),
                                            ),
                                          ],
                                        )
                                      else if (_locationText != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_locationText!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                            if (_locationLink != null) ...[
                                              SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: () async {
                                                  final uri = Uri.parse(_locationLink!);
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  }
                                                },
                                                child: Text('Open in Maps ↗', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w600, fontSize: 13)),
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 24),

                                // Patient Card
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20, offset: Offset(0, 10))],
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(radius: 40, backgroundColor: Color(0xffF1F5F9), child: Icon(Icons.person, size: 40, color: Colors.grey)),
                                      SizedBox(height: 16),
                                      Text(_name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                      SizedBox(height: 4),
                                      Text('Age: $_age', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                                      SizedBox(height: 24),
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                        decoration: BoxDecoration(
                                          color: Color(0xffFEF2F2), borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Color(0xffFECACA)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text('BLOOD GROUP', style: TextStyle(color: Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            Text(_bloodGroup, style: TextStyle(color: Color(0xffDC2626), fontSize: 32, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 24),

                                _buildWarningCard(
                                  title: 'SEVERE ALLERGIES', icon: Icons.warning_amber_rounded,
                                  items: _allergies.isEmpty ? ['None reported'] : _allergies,
                                  color: Color(0xffDC2626), bgColor: Color(0xffFEF2F2),
                                ),
                                SizedBox(height: 16),
                                _buildWarningCard(
                                  title: 'ACTIVE DISEASES', icon: Icons.coronavirus_outlined,
                                  items: _diseases.isEmpty ? ['None reported'] : _diseases,
                                  color: Colors.orange[800]!, bgColor: Colors.orange.withValues(alpha: 0.1)!,
                                ),
                                SizedBox(height: 16),
                                _buildWarningCard(
                                  title: 'CURRENT MEDICINES', icon: Icons.medication,
                                  items: _medicines.isEmpty ? ['None reported'] : _medicines,
                                  color: Colors.blue[800]!, bgColor: Colors.blue.withValues(alpha: 0.1)!,
                                ),
                                SizedBox(height: 16),

                                // Emergency Contact
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Theme.of(context).dividerColor, ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                                        child: Icon(Icons.phone_in_talk, color: Colors.green),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('EMERGENCY CONTACT', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            Text(_emergencyContact, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                          ],
                                        ),
                                      ),
                                      if (_emergencyContact != '—')
                                        GestureDetector(
                                          onTap: () async {
                                            final uri = Uri(scheme: 'tel', path: _emergencyContact);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                            child: Icon(Icons.call, color: Colors.green[700], size: 20),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action Button Widget ─────────────────────────────────

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 28)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Warning Card Widget ──────────────────────────────────

  Widget _buildWarningCard({required String title, required IconData icon, required List<String> items, required Color color, required Color bgColor}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            SizedBox(width: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
          ]),
          SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8.0, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(top: 6), child: CircleAvatar(radius: 3, backgroundColor: color)),
                SizedBox(width: 8),
                Expanded(child: Text(item, style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
