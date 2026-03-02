import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'doctor_notes_screen.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  final Map<String, dynamic>? qrData;
  const DoctorPatientDetailScreen({super.key, required this.patientId, required this.doctorId, this.qrData});

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
    final allergies = List<String>.from(_patient['allergies'] ?? []);
    final diseases = List<String>.from(_patient['diseases'] ?? []);
    final currentMeds = List<String>.from(_patient['currentMedicines'] ?? []);
    final oldMeds = List<String>.from(_patient['oldMedicines'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: Text(widget.patientId, style: const TextStyle(color: Color(0xff1E293B), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add, color: Colors.blue),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorNotesScreen(patientId: widget.patientId, doctorId: widget.doctorId)));
              _loadAll(); // Refresh after adding note
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Patient Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.person, size: 32, color: Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                            const SizedBox(height: 4),
                            Text('$age yrs • $bloodGroup', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Allergies alert
                if (allergies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEF2F2),
                      border: Border.all(color: const Color(0xffFECACA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Color(0xffDC2626)),
                      title: const Text('SEVERE ALLERGIES', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(allergies.join(', '), style: const TextStyle(color: Color(0xff991B1B), fontWeight: FontWeight.w600)),
                      minTileHeight: 60,
                    ),
                  ),

                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xffDC2626),
                    unselectedLabelColor: Colors.grey[500],
                    indicatorColor: const Color(0xffDC2626),
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
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (diseases.isNotEmpty) ...[
                            const Text('Active Diseases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                            const SizedBox(height: 8),
                            ...diseases.map((d) => _buildSimpleItem(d, Icons.coronavirus_outlined, Colors.orange)),
                            const SizedBox(height: 16),
                          ],
                          if (_timeline.isNotEmpty) ...[
                            const Text('Timeline Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            const SizedBox(height: 8),
                            ..._timeline.map((e) {
                              final date = e['date'] != null ? DateFormat('MMM dd, yyyy').format((e['date'] as dynamic).toDate()) : '';
                              return _buildSimpleItem('${e['event']}${date.isNotEmpty ? ' • $date' : ''}', Icons.event_note, Colors.blue);
                            }),
                          ],
                          if (_notes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Doctor Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                            const SizedBox(height: 8),
                            ..._notes.map((n) {
                              final date = n['date'] != null ? DateFormat('MMM dd').format((n['date'] as dynamic).toDate()) : '';
                              return _buildSimpleItem('${n['note']} • $date', Icons.note, Colors.purple);
                            }),
                          ],
                          if (_timeline.isEmpty && _notes.isEmpty && diseases.isEmpty)
                            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No history yet.', style: TextStyle(color: Colors.grey[400])))),
                        ],
                      ),

                      // 2. Medicines
                      ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (currentMeds.isNotEmpty) ...[
                            const Text('Current Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                            const SizedBox(height: 8),
                            ...currentMeds.map((m) => _buildMedicineCard(m, 'Active', inactive: false)),
                          ],
                          if (oldMeds.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Old Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            ...oldMeds.map((m) => _buildMedicineCard(m, 'Completed', inactive: true)),
                          ],
                          if (currentMeds.isEmpty && oldMeds.isEmpty)
                            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No medicines listed.', style: TextStyle(color: Colors.grey[400])))),
                        ],
                      ),

                      // 3. Reports
                      ListView(
                        padding: const EdgeInsets.all(24),
                        children: _reports.isEmpty
                            ? [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No reports uploaded.', style: TextStyle(color: Colors.grey[400]))))]
                            : _reports.map((r) {
                                final fileName = r['fileName'] ?? 'Unknown';
                                final date = r['date'] != null ? DateFormat('MMM dd, yyyy').format((r['date'] as dynamic).toDate()) : '';
                                return _buildReportCard('$fileName${date.isNotEmpty ? ' ($date)' : ''}');
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xff1E293B)))),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(String name, String status, {bool inactive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: inactive ? Colors.grey[50] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Icon(Icons.medication, color: inactive ? Colors.grey : Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: inactive ? Colors.grey : const Color(0xff1E293B))),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf, color: Colors.red)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B)))),
          Icon(Icons.download, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
