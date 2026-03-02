import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import '../services/qr_crypto_service.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  final String doctorId;
  DoctorPatientSearchScreen({super.key, required this.doctorId});

  @override
  State<DoctorPatientSearchScreen> createState() => _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadAllPatients();
  }

  Future<void> _loadAllPatients() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      if (mounted) {
        setState(() {
          _allPatients = patients;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _filteredPatients = []);
      return;
    }
    final q = query.trim().toLowerCase();
    final matches = _allPatients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final id = (p['patientId'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      
      return name.contains(q) || id.contains(q) || phone.contains(q);
    }).toList();

    if (mounted) {
      setState(() => _filteredPatients = matches);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPatient(String patientId) async {
    if (patientId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a Patient ID.')));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final data = await FirestoreService.getPatientByPatientId(patientId.trim());

      if (!mounted) return;

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Patient not found. Check the ID and try again.')));
      } else {
        await FirestoreService.addDoctorActivity(
          doctorId: widget.doctorId,
          action: 'Viewed Patient $patientId',
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => DoctorPatientDetailScreen(patientId: patientId.trim(), doctorId: widget.doctorId),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _scanQR() {
    bool hasNavigated = false;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Scan Patient QR'), backgroundColor: Theme.of(context).colorScheme.onSurface),
        body: MobileScanner(
          onDetect: (capture) {
            if (hasNavigated) return; // prevent multiple navigations

            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              final code = barcodes.first.rawValue!;
              hasNavigated = true;
              Navigator.pop(context); // close scanner

              // Try to decrypt the QR data (encrypted by Healthy Bhai app)
              final decryptedData = QrCryptoService.decrypt(code);

              if (decryptedData != null && decryptedData.containsKey('patientId')) {
                // Valid Healthy Bhai QR — use the embedded patient ID to navigate
                final patientId = decryptedData['patientId'] as String;
                _searchController.text = patientId;
                // Navigate directly with QR data so name/age/etc show immediately
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DoctorPatientDetailScreen(
                    patientId: patientId,
                    doctorId: widget.doctorId,
                    qrData: decryptedData,
                  ),
                ));
              } else {
                // Not a Healthy Bhai QR — show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(child: Text('Invalid QR code — not a Healthy Bhai patient QR.')),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Patient Search', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Access Patient Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 8),
                Text('Enter the Patient ID or scan their QR code.', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Enter Name, ID or Phone',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          filled: true, fillColor: Color(0xffF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onSubmitted: _searchPatient,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                        onPressed: _scanQR,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: _isSearching
                      ? Center(child: CircularProgressIndicator(color: Color(0xffDC2626)))
                      : ElevatedButton(
                          onPressed: () => _searchPatient(_searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffDC2626),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('SEARCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _filteredPatients.isNotEmpty || _searchController.text.isNotEmpty
                ? _buildDynamicSearchResults()
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        SizedBox(height: 16),
                        Text('Search for a patient by Name, ID or Phone', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 16)),
                        Text('or scan their QR code', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 14)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSearchResults() {
    if (_filteredPatients.isEmpty) {
      return Center(child: Text('No matching patients found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final p = _filteredPatients[index];
        final id = p['patientId'] ?? '';
        final name = p['name'] ?? 'Unknown';

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          elevation: 0,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: Color(0xffDC2626)),
            ),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            subtitle: Text('ID: $id\nPhone: ${p['phone'] ?? 'N/A'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            isThreeLine: true,
            onTap: () {
              FocusScope.of(context).unfocus();
              _searchController.text = id;
              _searchPatient(id);
            },
          ),
        );
      },
    );
  }
}
