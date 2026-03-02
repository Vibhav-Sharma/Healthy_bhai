import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';

class PatientSummaryScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patient;
  final List<Map<String, dynamic>> reports;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> timeline;

  const PatientSummaryScreen({
    super.key,
    required this.patientId,
    required this.patient,
    required this.reports,
    required this.notes,
    required this.timeline,
  });

  @override
  State<PatientSummaryScreen> createState() => _PatientSummaryScreenState();
}

class _PatientSummaryScreenState extends State<PatientSummaryScreen> {
  String _summary = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final result = await GeminiService.getPatientSummary(
      patient: widget.patient,
      reports: widget.reports,
      notes: widget.notes,
      timeline: widget.timeline,
    );

    if (mounted) {
      setState(() {
        _summary = result;
        _hasError = result.startsWith('Error:');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patient['name'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xff1E293B),
        foregroundColor: Colors.white,
        title: Text('Summary • $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xffDC2626)),
                  const SizedBox(height: 16),
                  Text('Generating AI summary...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Analysing ${widget.patientId}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasError ? const Color(0xffFEF2F2) : const Color(0xffF0FDF4),
                      border: Border.all(color: _hasError ? const Color(0xffFECACA) : const Color(0xffBBF7D0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hasError ? Icons.error_outline : Icons.auto_awesome,
                          color: _hasError ? const Color(0xffDC2626) : const Color(0xff16A34A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _hasError ? 'Failed to Generate Summary' : 'AI-Generated Clinical Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _hasError ? const Color(0xffDC2626) : const Color(0xff16A34A),
                            ),
                          ),
                        ),
                        if (_hasError)
                          TextButton(
                            onPressed: _generateSummary,
                            child: const Text('Retry', style: TextStyle(color: Color(0xffDC2626))),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary content
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: MarkdownBody(
                        data: _summary,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xff334155)),
                          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff1E293B)),
                          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B)),
                          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B)),
                          listBullet: const TextStyle(fontSize: 14, color: Color(0xff334155)),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xffDC2626)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI-generated summary. Always verify with original records.',
                            style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
