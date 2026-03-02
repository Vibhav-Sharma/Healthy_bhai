import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class MedicalTimelineScreen extends StatefulWidget {
  final String patientId;
  MedicalTimelineScreen({super.key, required this.patientId});

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Medical History', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.history_edu, color: Colors.blue, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Patient Timeline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
                            SizedBox(height: 4),
                            Text('Chronological medical history records.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),

                  if (_events.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          SizedBox(height: 16),
                          Text('No timeline events yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Events will appear as you upload reports, get AI advice, and more.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13)),
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

                  SizedBox(height: 40),
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
                Container(width: 16, height: 16, decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, border: Border.all(color: iconColor, width: 4))),
                Expanded(child: Container(width: isLast ? 0 : 2, color: isLast ? Colors.transparent : Colors.grey[300])),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor, ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(year, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Icon(icon, color: iconColor.withValues(alpha: 0.8), size: 20),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    if (description.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(description, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
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
