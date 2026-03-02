import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class EmergencyModeScreen extends StatefulWidget {
  final String? patientId;
  const EmergencyModeScreen({super.key, this.patientId});

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (widget.patientId != null) {
        // Fetch from Firestore and cache locally
        final data = await FirestoreService.getPatientByPatientId(widget.patientId!);
        if (data != null) {
          _name = data['name'] ?? 'Unknown';
          _age = data['age']?.toString() ?? '—';
          _bloodGroup = data['bloodGroup'] ?? '—';
          _allergies = List<String>.from(data['allergies'] ?? []);
          _diseases = List<String>.from(data['diseases'] ?? []);
          _medicines = List<String>.from(data['currentMedicines'] ?? []);
          _emergencyContact = data['emergencyContact'] ?? '—';

          // Cache for offline/no-login access
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
        // No patientId — try to load from local cache
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
      // Fallback: try cache
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('emergency_name') ?? 'No Data';
      _bloodGroup = prefs.getString('emergency_bloodGroup') ?? '—';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF2F2),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: Container(height: 200, color: const Color(0xffDC2626))),
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 8),
                          Text('EMERGENCY DATA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Patient Card
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                                  ),
                                  child: Column(
                                    children: [
                                      const CircleAvatar(radius: 40, backgroundColor: Color(0xffF1F5F9), child: Icon(Icons.person, size: 40, color: Colors.grey)),
                                      const SizedBox(height: 16),
                                      Text(_name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                                      const SizedBox(height: 4),
                                      Text('Age: $_age', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFEF2F2), borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xffFECACA)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text('BLOOD GROUP', style: TextStyle(color: Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            Text(_bloodGroup, style: const TextStyle(color: Color(0xffDC2626), fontSize: 32, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                _buildWarningCard(
                                  title: 'SEVERE ALLERGIES', icon: Icons.warning_amber_rounded,
                                  items: _allergies.isEmpty ? ['None reported'] : _allergies,
                                  color: const Color(0xffDC2626), bgColor: const Color(0xffFEF2F2),
                                ),
                                const SizedBox(height: 16),
                                _buildWarningCard(
                                  title: 'ACTIVE DISEASES', icon: Icons.coronavirus_outlined,
                                  items: _diseases.isEmpty ? ['None reported'] : _diseases,
                                  color: Colors.orange[800]!, bgColor: Colors.orange[50]!,
                                ),
                                const SizedBox(height: 16),
                                _buildWarningCard(
                                  title: 'CURRENT MEDICINES', icon: Icons.medication,
                                  items: _medicines.isEmpty ? ['None reported'] : _medicines,
                                  color: Colors.blue[800]!, bgColor: Colors.blue[50]!,
                                ),
                                const SizedBox(height: 16),

                                // Emergency Contact
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                                        child: const Icon(Icons.phone_in_talk, color: Colors.green),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('EMERGENCY CONTACT', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                            Text(_emergencyContact, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
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

  Widget _buildWarningCard({required String title, required IconData icon, required List<String> items, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: CircleAvatar(radius: 3, backgroundColor: color)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 15, color: Color(0xff1E293B), fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
