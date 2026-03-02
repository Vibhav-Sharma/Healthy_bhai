import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firestore_service.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  final String doctorId;
  const DoctorPatientSearchScreen({super.key, required this.doctorId});

  @override
  State<DoctorPatientSearchScreen> createState() => _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPatient(String patientId) async {
    if (patientId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Patient ID.')));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final data = await FirestoreService.getPatientByPatientId(patientId.trim());

      if (!mounted) return;

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient not found. Check the ID and try again.')));
      } else {
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
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Patient QR'), backgroundColor: const Color(0xff1E293B)),
        body: MobileScanner(
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              final code = barcodes.first.rawValue!;
              Navigator.pop(context); // close scanner
              _searchController.text = code;
              _searchPatient(code);
            }
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Patient Search', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Access Patient Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xff1E293B))),
                const SizedBox(height: 8),
                Text('Enter the Patient ID or scan their QR code.', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter Patient ID (e.g. HB-8429-XT)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true, fillColor: const Color(0xffF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        onSubmitted: _searchPatient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(color: const Color(0xff1E293B), borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        onPressed: _scanQR,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator(color: Color(0xffDC2626)))
                      : ElevatedButton(
                          onPressed: () => _searchPatient(_searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffDC2626),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('SEARCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Search for a patient by their ID', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  Text('or scan their QR code', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
