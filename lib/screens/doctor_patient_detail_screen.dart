import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'doctor_notes_screen.dart';
import 'patient_summary_screen.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  final Map<String, dynamic>? qrData;
  DoctorPatientDetailScreen({super.key, required this.patientId, required this.doctorId, this.qrData});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic> _patient = {};
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _timeline = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Fetch each piece of data independently so one failure doesn't break everything
    Map<String, dynamic>? patient;
    List<Map<String, dynamic>> reports = [];
    List<Map<String, dynamic>> notes = [];
    List<Map<String, dynamic>> timeline = [];

    try {
      patient = await FirestoreService.getPatientByPatientId(widget.patientId);
    } catch (e) {
      debugPrint('[Detail] Error fetching patient: $e');
    }

    try {
      reports = await FirestoreService.getReports(widget.patientId);
    } catch (e) {
      debugPrint('[Detail] Error fetching reports: $e');
    }

    try {
      notes = await FirestoreService.getNotes(widget.patientId);
    } catch (e) {
      debugPrint('[Detail] Error fetching notes: $e');
    }

    try {
      timeline = await FirestoreService.getTimeline(widget.patientId);
    } catch (e) {
      debugPrint('[Detail] Error fetching timeline: $e');
    }

    // Merge: start with QR data (if any), then overlay Firestore data
    final merged = <String, dynamic>{};
    if (widget.qrData != null) merged.addAll(widget.qrData!);
    if (patient != null) merged.addAll(patient);

    if (mounted) {
      setState(() {
        _patient = merged;
        _reports = reports;
        _notes = notes;
        _timeline = timeline;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _patient['name'] ?? 'Unknown';
    final age = _patient['age']?.toString() ?? '—';
    final bloodGroup = _patient['bloodGroup'] ?? '—';
    final height = _patient['height']?.toString() ?? '';
    final weight = _patient['weight']?.toString() ?? '';
    final allergies = List<String>.from(_patient['allergies'] ?? []);
    final pastDiseases = List<String>.from(_patient['pastDiseases'] ?? []);
    final currentDiseases = List<String>.from(_patient['currentDiseases'] ?? []);
    final chronicDiseases = List<String>.from(_patient['chronicDiseases'] ?? []);
    final surgeries = List<String>.from(_patient['surgeries'] ?? []);
    final treatments = List<String>.from(_patient['treatments'] ?? []);
    final currentMeds = List<String>.from(_patient['currentMedicines'] ?? []);
    final oldMeds = List<String>.from(_patient['oldMedicines'] ?? []);

    // Build subtitle: "25 yrs • O+ • 170 cm • 70 kg"
    final subtitleParts = <String>['$age yrs', bloodGroup];
    if (height.isNotEmpty) subtitleParts.add('$height cm');
    if (weight.isNotEmpty) subtitleParts.add('$weight kg');
    final subtitleStr = subtitleParts.join(' • ');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text(widget.patientId, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: Color(0xffDC2626)),
            tooltip: 'AI Summary',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PatientSummaryScreen(
                  patientId: widget.patientId,
                  patient: _patient,
                  reports: _reports,
                  notes: _notes,
                  timeline: _timeline,
                ),
              ));
            },
          ),
          IconButton(
            icon: Icon(Icons.note_add, color: Colors.blue),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorNotesScreen(patientId: widget.patientId, doctorId: widget.doctorId)));
              _loadAll(); // Refresh after adding note
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Patient Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: Row(
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.person, size: 32, color: Colors.blue)),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            SizedBox(height: 4),
                            Text(subtitleStr, style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Allergies alert
                if (allergies.isNotEmpty)
                  Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Color(0xffFECACA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: Color(0xffDC2626)),
                      title: Text('SEVERE ALLERGIES', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(allergies.join(', '), style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.w600)),
                      minTileHeight: 60,
                    ),
                  ),

                // Tabs
                Container(
                  color: Theme.of(context).cardColor,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Color(0xffDC2626),
                    unselectedLabelColor: Colors.grey[500],
                    indicatorColor: Color(0xffDC2626),
                    tabs: const [Tab(text: 'HISTORY'), Tab(text: 'MEDICINES'), Tab(text: 'REPORTS')],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. History — timeline + notes
                      ListView(
                        padding: EdgeInsets.all(24),
                        children: [
                          if (currentDiseases.isNotEmpty) ...[
                            Text('Current Diseases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                            SizedBox(height: 8),
                            ...currentDiseases.map((d) => _buildSimpleItem(d, Icons.coronavirus_outlined, Colors.orange)),
                            SizedBox(height: 16),
                          ],
                          if (chronicDiseases.isNotEmpty) ...[
                            Text('Chronic Diseases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                            SizedBox(height: 8),
                            ...chronicDiseases.map((d) => _buildSimpleItem(d, Icons.favorite_border, Colors.red)),
                            SizedBox(height: 16),
                          ],

                          if (pastDiseases.isNotEmpty) ...[
                            Text('Past Diseases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                            SizedBox(height: 8),
                            ...pastDiseases.map((d) => _buildSimpleItem(d, Icons.history, Colors.grey)),
                            SizedBox(height: 16),
                          ],
                          if (surgeries.isNotEmpty) ...[
                            Text('Past Surgeries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
                            SizedBox(height: 8),
                            ...surgeries.map((s) => _buildSimpleItem(s, Icons.content_cut_outlined, Colors.indigo)),
                            SizedBox(height: 16),
                          ],
                          if (treatments.isNotEmpty) ...[
                            Text('Ongoing Treatments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                            SizedBox(height: 8),
                            ...treatments.map((t) => _buildSimpleItem(t, Icons.healing_outlined, Colors.teal)),
                            SizedBox(height: 16),
                          ],
                          if (_timeline.isNotEmpty) ...[
                            Text('Timeline Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            SizedBox(height: 8),
                            ..._timeline.map((e) {
                              final date = e['date'] != null ? DateFormat('MMM dd, yyyy').format((e['date'] as dynamic).toDate()) : '';
                              return _buildSimpleItem('${e['event']}${date.isNotEmpty ? ' • $date' : ''}', Icons.event_note, Colors.blue);
                            }),
                          ],
                          if (_notes.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text('Doctor Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                            SizedBox(height: 8),
                            ..._notes.map((n) {
                              final date = n['date'] != null ? DateFormat('MMM dd').format((n['date'] as dynamic).toDate()) : '';
                              return _buildSimpleItem('${n['note']} • $date', Icons.note, Colors.purple);
                            }),
                          ],
                          if (_timeline.isEmpty && _notes.isEmpty && currentDiseases.isEmpty && chronicDiseases.isEmpty && pastDiseases.isEmpty && surgeries.isEmpty && treatments.isEmpty)
                            Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No history yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))),
                        ],
                      ),

                      // 2. Medicines
                      ListView(
                        padding: EdgeInsets.all(24),
                        children: [
                          if (currentMeds.isNotEmpty) ...[
                            Text('Current Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            SizedBox(height: 8),
                            ...currentMeds.map((m) => _buildMedicineCard(m, 'Active', inactive: false)),
                          ],
                          if (oldMeds.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text('Old Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                            SizedBox(height: 8),
                            ...oldMeds.map((m) => _buildMedicineCard(m, 'Completed', inactive: true)),
                          ],
                          if (currentMeds.isEmpty && oldMeds.isEmpty)
                            Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No medicines listed.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))))),
                        ],
                      ),

                      // 3. Reports
                      ListView(
                        padding: EdgeInsets.all(24),
                        children: _reports.isEmpty
                            ? [Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No reports uploaded.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)))))]
                            : _reports.map((r) {
                                final fileName = r['fileName'] ?? 'Unknown';
                                final fileUrl = r['fileUrl'] ?? '';
                                final date = r['date'] != null ? DateFormat('MMM dd, yyyy').format((r['date'] as dynamic).toDate()) : '';
                                return _buildReportCard('$fileName${date.isNotEmpty ? ' ($date)' : ''}', fileUrl);
                              }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSimpleItem(String text, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor, )),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(String name, String status, {bool inactive = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: inactive ? Colors.grey.withValues(alpha: 0.1) : Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
      child: Row(
        children: [
          Icon(Icons.medication, color: inactive ? Colors.grey : Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: inactive ? Colors.grey : Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text(status, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String fileUrl) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
      child: Row(
        children: [
          Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.picture_as_pdf, color: Colors.red)),
          SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
          IconButton(
            icon: Icon(Icons.download, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            onPressed: fileUrl.isNotEmpty ? () {
              Clipboard.setData(ClipboardData(text: fileUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Download URL copied to clipboard!')),
              );
            } : null,
          ),
        ],
      ),
    );
  }
}
