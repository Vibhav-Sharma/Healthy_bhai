import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';

class AiAssistantScreen extends StatefulWidget {
  final String? patientId;

  AiAssistantScreen({super.key, this.patientId});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _symptomsController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicinesController = TextEditingController();

  String _aiResponse = '';
  bool _isLoading = false;
  bool _hasError = false;
  bool _isLoadingPatient = false;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) _fetchPatientData();
  }

  /// Auto-fetch patient data from Firestore and pre-fill fields
  Future<void> _fetchPatientData() async {
    setState(() => _isLoadingPatient = true);
    try {
      final data = await FirestoreService.getPatientByPatientId(widget.patientId!);
      if (data != null && mounted) {
        _bloodGroupController.text = data['bloodGroup'] ?? '';
        _diseasesController.text = (data['diseases'] as List?)?.join(', ') ?? '';
        _allergiesController.text = (data['allergies'] as List?)?.join(', ') ?? '';
        _medicinesController.text = (data['currentMedicines'] as List?)?.join(', ') ?? '';
      }
    } catch (e) {
      // Silently fail — user can still type manually
    }
    if (mounted) setState(() => _isLoadingPatient = false);
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _bloodGroupController.dispose();
    _diseasesController.dispose();
    _allergiesController.dispose();
    _medicinesController.dispose();
    super.dispose();
  }

  Future<void> _getAdvice() async {
    if (_symptomsController.text.trim().isEmpty) {
      setState(() { _hasError = true; _aiResponse = 'Please enter your symptoms first.'; });
      return;
    }

    setState(() { _isLoading = true; _hasError = false; _aiResponse = ''; });

    final response = await GeminiService.getEmergencyAdvice(
      symptoms: _symptomsController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : 'Not provided',
      diseases: _diseasesController.text.trim().isNotEmpty ? _diseasesController.text.trim() : 'None',
      allergies: _allergiesController.text.trim().isNotEmpty ? _allergiesController.text.trim() : 'None',
      medicines: _medicinesController.text.trim().isNotEmpty ? _medicinesController.text.trim() : 'None',
    );

    setState(() { _isLoading = false; _aiResponse = response; _hasError = response.startsWith('Error:'); });

    // Optionally save to timeline
    if (!_hasError && widget.patientId != null) {
      try {
        await FirestoreService.addTimelineEvent(
          patientId: widget.patientId!,
          event: 'AI Advice: ${_symptomsController.text.trim()}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Emergency Assistant'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This AI provides basic first-aid guidance only. Always consult a doctor for medical advice.',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Patient Info Section
            Row(
              children: [
                Text('Patient Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (_isLoadingPatient) ...[
                  SizedBox(width: 8),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 4),
                  Text('Loading...', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ] else if (widget.patientId != null) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Auto-filled', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                ],
              ],
            ),
            SizedBox(height: 8),
            _buildTextField(_bloodGroupController, 'Blood Group', 'e.g., O+'),
            _buildTextField(_diseasesController, 'Known Diseases', 'e.g., Diabetes'),
            _buildTextField(_allergiesController, 'Allergies', 'e.g., Penicillin'),
            _buildTextField(_medicinesController, 'Current Medicines', 'e.g., Metformin'),
            SizedBox(height: 16),

            // Symptoms
            Text('Describe Your Symptoms *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Fever and headache since 2 days',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.redAccent, width: 2)),
              ),
            ),
            SizedBox(height: 16),

            // Get Advice Button
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getAdvice,
                icon: Icon(Icons.health_and_safety),
                label: Text('Get Advice', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Loading
            if (_isLoading)
              Center(child: Column(children: [CircularProgressIndicator(color: Colors.redAccent), SizedBox(height: 10), Text('Analyzing symptoms...')])),

            // Response
            if (_aiResponse.isNotEmpty && !_isLoading)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _hasError ? Colors.red : Colors.green, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(_hasError ? Icons.error_outline : Icons.check_circle_outline, color: _hasError ? Colors.red : Colors.green),
                        SizedBox(width: 8),
                        Text(_hasError ? 'Error' : 'AI Advice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _hasError ? Colors.red : Colors.green)),
                      ]),
                      Divider(),
                      MarkdownBody(
                        data: _aiResponse,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(fontSize: 14, height: 1.5),
                          h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          listBullet: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
