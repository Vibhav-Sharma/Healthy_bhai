import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/qr_crypto_service.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientId;
  PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _encryptedQR;

  // Editable controllers
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _allergiesController;
  late TextEditingController _pastDiseasesController;
  late TextEditingController _currentDiseasesController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _currentMedController;
  late TextEditingController _oldMedController;
  late TextEditingController _surgeriesController;
  late TextEditingController _treatmentsController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await FirestoreService.getPatientByPatientId(widget.patientId);
      if (mounted && data != null) {
        // Build QR payload from fresh data
        _buildQR(data);
        setState(() {
          _data = data;
          _initControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildQR(Map<String, dynamic> data) {
    try {
      final payload = <String, dynamic>{'patientId': widget.patientId};
      if (data['name'] != null) payload['name'] = data['name'];
      if (data['age'] != null) payload['age'] = data['age'];
      if (data['gender'] != null) payload['gender'] = data['gender'];
      if (data['bloodGroup'] != null) payload['bloodGroup'] = data['bloodGroup'];
      if (data['height'] != null) payload['height'] = data['height'];
      if (data['weight'] != null) payload['weight'] = data['weight'];
      if (data['phone'] != null) payload['phone'] = data['phone'];
      if (data['email'] != null) payload['email'] = data['email'];
      if (data['emergencyContact'] != null) payload['emergencyContact'] = data['emergencyContact'];

      void addList(String key) {
        final list = List<String>.from(data[key] ?? []);
        if (list.isNotEmpty) payload[key] = list;
      }
      addList('allergies');
      addList('pastDiseases');
      addList('currentDiseases');
      addList('chronicDiseases');
      addList('currentMedicines');
      addList('oldMedicines');
      addList('surgeries');
      addList('treatments');

      _encryptedQR = QrCryptoService.encrypt(payload);
    } catch (e) {
      debugPrint('[Profile QR] encrypt error: $e');
      // Fallback — just the patient ID
      try {
        _encryptedQR = QrCryptoService.encrypt({'patientId': widget.patientId});
      } catch (_) {}
    }
  }

  void _initControllers() {
    _heightController = TextEditingController(text: _data!['height']?.toString() ?? '');
    _weightController = TextEditingController(text: _data!['weight']?.toString() ?? '');
    _ageController = TextEditingController(text: _data!['age']?.toString() ?? '');
    _bloodGroupController = TextEditingController(text: _data!['bloodGroup']?.toString() ?? '');
    _allergiesController = TextEditingController(text: (_data!['allergies'] as List?)?.join(', ') ?? '');
    _pastDiseasesController = TextEditingController(text: (_data!['pastDiseases'] as List?)?.join(', ') ?? '');
    _currentDiseasesController = TextEditingController(text: (_data!['currentDiseases'] as List?)?.join(', ') ?? '');
    _chronicDiseasesController = TextEditingController(text: (_data!['chronicDiseases'] as List?)?.join(', ') ?? '');
    _currentMedController = TextEditingController(text: (_data!['currentMedicines'] as List?)?.join(', ') ?? '');
    _oldMedController = TextEditingController(text: (_data!['oldMedicines'] as List?)?.join(', ') ?? '');
    _surgeriesController = TextEditingController(text: (_data!['surgeries'] as List?)?.join(', ') ?? '');
    _treatmentsController = TextEditingController(text: (_data!['treatments'] as List?)?.join(', ') ?? '');
  }

  List<String> _parseList(String text) {
    if (text.trim().isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid != null) {
        await FirestoreService.updatePatientProfile(uid, {
          'height': _heightController.text.trim(),
          'weight': _weightController.text.trim(),
          'age': _ageController.text.trim(),
          'bloodGroup': _bloodGroupController.text.trim(),
          'allergies': _parseList(_allergiesController.text),
          'pastDiseases': _parseList(_pastDiseasesController.text),
          'currentDiseases': _parseList(_currentDiseasesController.text),
          'chronicDiseases': _parseList(_chronicDiseasesController.text),
          'currentMedicines': _parseList(_currentMedController.text),
          'oldMedicines': _parseList(_oldMedController.text),
          'surgeries': _parseList(_surgeriesController.text),
          'treatments': _parseList(_treatmentsController.text),
        });

        await FirestoreService.addTimelineEvent(
          patientId: widget.patientId,
          event: 'Updated profile details.',
        );

        // Reload data → QR regenerates automatically
        await _loadData();
        if (mounted) {
          setState(() { _isEditing = false; _isSaving = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated! QR code refreshed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showQRPopup() {
    if (_encryptedQR == null) return;
    showDialog(
      context: context,
      barrierColor: Color(0xEE1E293B),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Scan My QR', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 8),
                Text('Tap anywhere to close', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: QrImageView(
                    data: _encryptedQR!,
                    version: QrVersions.auto,
                    size: 280.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('ID: ${widget.patientId}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xffDC2626))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _data != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.blue),
              onPressed: () {
                setState(() {
                  if (_isEditing) _initControllers();
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text('Failed to load profile.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── QR CODE + IDENTITY HEADER ──
                      Center(
                        child: Column(
                          children: [
                            // QR Code
                            if (_encryptedQR != null) ...[
                              GestureDetector(
                                onLongPress: () => _showQRPopup(),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Theme.of(context).dividerColor, ),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: Offset(0, 4))],
                                  ),
                                  child: Column(
                                    children: [
                                      QrImageView(
                                        data: _encryptedQR!,
                                        version: QrVersions.auto,
                                        size: 180.0,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(color: Colors.black),
                                        dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, color: Colors.green[700], size: 13),
                                            SizedBox(width: 4),
                                            Text('AES-256 Encrypted', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text('Hold to enlarge', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                            // Name + ID
                            Text(_data!['name'] ?? '-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('ID: ${widget.patientId}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xffDC2626))),
                            ),
                            SizedBox(height: 6),
                            Text('Show this QR to your doctor for instant access.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // ── PERSONAL INFO ──
                      _sectionHeader('PERSONAL INFO'),
                      SizedBox(height: 12),
                      _isEditing
                          ? Column(children: [
                              _editField('Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number),
                              _editField('Blood Group', _bloodGroupController, Icons.bloodtype_outlined),
                              _editField('Height (cm)', _heightController, Icons.height, keyboardType: TextInputType.number),
                              _editField('Weight (kg)', _weightController, Icons.monitor_weight_outlined, keyboardType: TextInputType.number),
                            ])
                          : Column(children: [
                              _infoRow(Icons.cake_outlined, 'Age', _data!['age'] ?? '-'),
                              _infoRow(Icons.bloodtype_outlined, 'Blood Group', _data!['bloodGroup'] ?? '-'),
                              _infoRow(Icons.height, 'Height', _data!['height'] == null || _data!['height'].toString().trim().isEmpty ? '-' : '${_data!['height']} cm'),
                              _infoRow(Icons.monitor_weight_outlined, 'Weight', _data!['weight'] == null || _data!['weight'].toString().trim().isEmpty ? '-' : '${_data!['weight']} kg'),
                              _infoRow(Icons.phone_outlined, 'Emergency Contact', _formatPhone(_data!['emergencyContact'])),
                            ]),

                      SizedBox(height: 28),

                      // ── MEDICAL HISTORY ──
                      _sectionHeader('MEDICAL HISTORY'),
                      SizedBox(height: 12),
                      _isEditing
                          ? Column(children: [
                              _editField('Allergies', _allergiesController, Icons.warning_amber_rounded),
                              _editField('Past Diseases', _pastDiseasesController, Icons.history),
                              _editField('Current Diseases', _currentDiseasesController, Icons.coronavirus_outlined),
                              _editField('Chronic Diseases', _chronicDiseasesController, Icons.favorite_border),
                              _editField('Current Medicines', _currentMedController, Icons.medication),
                              _editField('Past Medicines', _oldMedController, Icons.medication_outlined),
                              _editField('Past Surgeries', _surgeriesController, Icons.content_cut_outlined),
                              _editField('Ongoing Treatments', _treatmentsController, Icons.healing_outlined),
                            ])
                          : Column(children: [
                              _infoRow(Icons.warning_amber_rounded, 'Allergies', _listStr('allergies')),
                              _infoRow(Icons.history, 'Past Diseases', _listStr('pastDiseases')),
                              _infoRow(Icons.coronavirus_outlined, 'Current Diseases', _listStr('currentDiseases')),
                              _infoRow(Icons.favorite_border, 'Chronic Diseases', _listStr('chronicDiseases')),
                              _infoRow(Icons.medication, 'Current Medicines', _listStr('currentMedicines')),
                              _infoRow(Icons.medication_outlined, 'Past Medicines', _listStr('oldMedicines')),
                              _infoRow(Icons.content_cut_outlined, 'Past Surgeries', _listStr('surgeries')),
                              _infoRow(Icons.healing_outlined, 'Treatments', _listStr('treatments')),
                            ]),

                      SizedBox(height: 28),

                      // ── ACTIONS ──
                      if (_isEditing) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xffDC2626),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await AuthService.signOut();
                              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: Icon(Icons.logout, color: Colors.red),
                            label: Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  String _listStr(String key) {
    final list = _data![key] as List?;
    if (list == null || list.isEmpty) return 'None';
    return list.join(', ');
  }

  String _formatPhone(dynamic raw) {
    if (raw == null) return '-';
    final digits = raw.toString().replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits.isEmpty ? '-' : digits;
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
