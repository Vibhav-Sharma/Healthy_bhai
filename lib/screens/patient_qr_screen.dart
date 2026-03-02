import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/firestore_service.dart';
import '../services/qr_crypto_service.dart';

class PatientQRScreen extends StatefulWidget {
  final String patientId;
  PatientQRScreen({super.key, required this.patientId});

  @override
  State<PatientQRScreen> createState() => _PatientQRScreenState();
}

class _PatientQRScreenState extends State<PatientQRScreen> {
  String? _encryptedData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndEncryptPatientData();
  }

  Future<void> _loadAndEncryptPatientData() async {
    try {
      Map<String, dynamic>? data;

      // Try 1: Direct lookup by Firebase Auth UID (no index needed)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('[QR] Looking up patient by UID: ${currentUser.uid}');
        data = await FirestoreService.getPatientByUid(currentUser.uid);
      }

      // Try 2: Query by patientId field
      if (data == null) {
        debugPrint('[QR] UID lookup returned null, trying patientId: ${widget.patientId}');
        data = await FirestoreService.getPatientByPatientId(widget.patientId);
      }

      debugPrint('[QR] Patient data found: ${data != null}');

      // Build the medical payload — keep it compact for QR capacity
      final payload = <String, dynamic>{
        'patientId': widget.patientId,
      };

      if (data != null) {
        if (data['name'] != null) payload['name'] = data['name'];
        if (data['age'] != null) payload['age'] = data['age'];
        if (data['gender'] != null) payload['gender'] = data['gender'];
        if (data['bloodGroup'] != null) payload['bloodGroup'] = data['bloodGroup'];
        if (data['phone'] != null) payload['phone'] = data['phone'];
        if (data['email'] != null) payload['email'] = data['email'];
        if (data['emergencyContact'] != null) payload['emergencyContact'] = data['emergencyContact'];
        if (data['allergies'] != null) {
          final allergies = List<String>.from(data['allergies'] ?? []);
          if (allergies.isNotEmpty) payload['allergies'] = allergies;
        }
        if (data['diseases'] != null) {
          final diseases = List<String>.from(data['diseases'] ?? []);
          if (diseases.isNotEmpty) payload['diseases'] = diseases;
        }
        if (data['currentMedicines'] != null) {
          final meds = List<String>.from(data['currentMedicines'] ?? []);
          if (meds.isNotEmpty) payload['currentMedicines'] = meds;
        }
        if (data['oldMedicines'] != null) {
          final oldMeds = List<String>.from(data['oldMedicines'] ?? []);
          if (oldMeds.isNotEmpty) payload['oldMedicines'] = oldMeds;
        }
        if (data['surgeries'] != null) {
          final surgeries = List<String>.from(data['surgeries'] ?? []);
          if (surgeries.isNotEmpty) payload['surgeries'] = surgeries;
        }
      }

      final encrypted = QrCryptoService.encrypt(payload);
      debugPrint('[QR] Encrypted data length: ${encrypted.length} chars');

      if (mounted) {
        setState(() {
          _encryptedData = encrypted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[QR] Error loading patient data: $e');
      // Fallback: encrypt just the patientId so QR still works
      try {
        final fallbackPayload = <String, dynamic>{'patientId': widget.patientId};
        final encrypted = QrCryptoService.encrypt(fallbackPayload);

        if (mounted) {
          setState(() {
            _encryptedData = encrypted;
            _isLoading = false;
          });
        }
      } catch (e2) {
        debugPrint('[QR] Even fallback encryption failed: $e2');
        if (mounted) {
          setState(() {
            _error = "Failed to generate QR code. Please try again.";
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator(color: Color(0xffDC2626))
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                      SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          setState(() { _isLoading = true; _error = null; });
                          _loadAndEncryptPatientData();
                        },
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24)),
                        child: Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : _buildQRContent(),
      ),
    );
  }

  Widget _buildQRContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Patient ID QR', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(height: 8),
        Text(
          'Show this to your doctor \nto grant instant access to your records.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 14, height: 1.5),
        ),

        SizedBox(height: 48),

        // QR Code Card
        Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            children: [
              // Encrypted QR Code
              QrImageView(
                data: _encryptedData!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
              ),

              SizedBox(height: 24),

              // Secure badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.green[700], size: 14),
                    SizedBox(width: 6),
                    Text('Encrypted', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'ID: ${widget.patientId}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xffDC2626)),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Info text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'This QR can only be read by the Healthy Bhai app. Other scanners will see encrypted data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, height: 1.5),
          ),
        ),

        SizedBox(height: 32),

        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.share, color: Colors.white),
          label: Text('Share ID', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.white24),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }
}
