import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class MedicalTimelineScreen extends StatefulWidget {
  final String patientId;
  const MedicalTimelineScreen({super.key, required this.patientId});

  @override
  State<MedicalTimelineScreen> createState() => _MedicalTimelineScreenState();
}

class _MedicalTimelineScreenState extends State<MedicalTimelineScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      final events = await FirestoreService.getTimeline(widget.patientId);
      if (mounted) setState(() { _events = events; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Medical History', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                        child: const Icon(Icons.history_edu, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Patient Timeline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xff1E293B), letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text('Chronological medical history records.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  if (_events.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No timeline events yet.', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Events will appear as you upload reports, get AI advice, and more.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_events.length, (index) {
                      final event = _events[index];
                      final eventText = event['event'] ?? 'Unknown event';
                      final date = event['date'] != null
                          ? DateFormat('MMM dd, yyyy').format((event['date'] as dynamic).toDate())
                          : 'Unknown date';

                      // Determine icon based on event text
                      IconData icon = Icons.event_note;
                      Color iconColor = Colors.blue;
                      if (eventText.toString().contains('Report')) { icon = Icons.upload_file; iconColor = Colors.green; }
                      if (eventText.toString().contains('AI')) { icon = Icons.smart_toy; iconColor = Colors.purple; }
                      if (eventText.toString().contains('Note')) { icon = Icons.note_add; iconColor = Colors.orange; }
                      if (eventText.toString().contains('medicine') || eventText.toString().contains('prescription') || eventText.toString().contains('extracted')) { icon = Icons.medication; iconColor = Colors.teal; }

                      return _buildTimelineItem(
                        year: date,
                        title: eventText,
                        description: '',
                        icon: icon,
                        iconColor: iconColor,
                        isFirst: index == 0,
                        isLast: index == _events.length - 1,
                      );
                    }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineItem({required String year, required String title, required String description, required IconData icon, required Color iconColor, bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(width: 2, height: 20, color: isFirst ? Colors.transparent : Colors.grey[300]),
                Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: iconColor, width: 4))),
                Expanded(child: Container(width: isLast ? 0 : 2, color: isLast ? Colors.transparent : Colors.grey[300])),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(year, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Icon(icon, color: iconColor.withValues(alpha: 0.8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
