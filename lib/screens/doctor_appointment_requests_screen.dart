import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class DoctorAppointmentRequestsScreen extends StatefulWidget {
  final String doctorId;
  DoctorAppointmentRequestsScreen({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentRequestsScreen> createState() => _DoctorAppointmentRequestsScreenState();
}

class _DoctorAppointmentRequestsScreenState extends State<DoctorAppointmentRequestsScreen> {
  final Map<String, String> _nameCache = {};

  Future<String> _getPatientName(String patientId, {String? storedName}) async {
    if (storedName != null && storedName.isNotEmpty) {
      _nameCache[patientId] = storedName;
      return storedName;
    }
    if (_nameCache.containsKey(patientId)) return _nameCache[patientId]!;
    final name = await FirestoreService.getPatientName(patientId);
    _nameCache[patientId] = name;
    return name;
  }

  DateTime _parseDate(dynamic d) {
    if (d == null) return DateTime.now();
    if (d is Timestamp) return d.toDate();
    if (d is DateTime) return d;
    if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
    return DateTime.now();
  }

  String _fmt(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m $ap';
  }

  // ─── APPROVE / REJECT ───
  Future<void> _updateStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $status'), backgroundColor: status == 'Upcoming' ? Colors.green : Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── EDIT DIALOG ───
  Future<void> _editAppointment(String appointmentId, Map<String, dynamic> data) async {
    final reasonCtrl = TextEditingController(text: data['reason']?.toString() ?? '');
    DateTime currentDate = _parseDate(data['appointmentDate']);
    String currentType = data['type']?.toString() ?? 'Offline';

    DateTime? newDate = currentDate;
    TimeOfDay? newTime = TimeOfDay(hour: currentDate.hour, minute: currentDate.minute);
    bool isOnline = currentType == 'Online';

    bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                Text('Reason', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'Reason for visit',
                  ),
                ),
                SizedBox(height: 16),

                // Date picker
                Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: newDate!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 60)),
                    );
                    if (picked != null) setDialogState(() => newDate = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor, ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('${newDate!.day}/${newDate!.month}/${newDate!.year}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Time picker
                Text('Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(context: ctx, initialTime: newTime!);
                    if (picked != null) setDialogState(() => newTime = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor, ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(newTime!.format(ctx)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Type toggle
                Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('In-Clinic'),
                      selected: !isOnline,
                      selectedColor: Colors.blue.shade100,
                      onSelected: (_) => setDialogState(() => isOnline = false),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Online'),
                      selected: isOnline,
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setDialogState(() => isOnline = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final updatedDateTime = DateTime(
        newDate!.year, newDate!.month, newDate!.day,
        newTime!.hour, newTime!.minute,
      );

      // Check for time conflict (exclude this appointment)
      bool conflict = await FirestoreService.hasTimeConflict(
        doctorId: widget.doctorId,
        proposedTime: updatedDateTime,
        excludeAppointmentId: appointmentId,
      );
      if (conflict) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You already have an appointment at that time.'), backgroundColor: Colors.orange),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'reason': reasonCtrl.text.trim(),
        'appointmentDate': Timestamp.fromDate(updatedDateTime),
        'type': isOnline ? 'Online' : 'Offline',
        'meetLink': isOnline ? 'https://meet.google.com/abc-defg-hij' : null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment updated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text('Appointment Requests', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey[200], height: 1)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: widget.doctorId)
            .where('status', isEqualTo: 'Waiting')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text('No pending requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  SizedBox(height: 4),
                  Text('New patient bookings will appear here.', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          // Sort by date descending (newest first)
          final sorted = docs.toList()
            ..sort((a, b) {
              final dA = _parseDate((a.data() as Map<String, dynamic>)['appointmentDate']);
              final dB = _parseDate((b.data() as Map<String, dynamic>)['appointmentDate']);
              return dB.compareTo(dA);
            });

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final doc = sorted[index];
              final data = doc.data() as Map<String, dynamic>;
              final patientId = data['patientId']?.toString() ?? 'Unknown';
              final reason = data['reason']?.toString() ?? data['symptoms']?.toString() ?? 'Not provided';
              final type = data['type']?.toString() ?? 'Offline';
              final date = _parseDate(data['appointmentDate']);

              return Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header — patient name + type badge
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.person, color: Colors.orange.shade700, size: 26),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getPatientName(patientId, storedName: data['patientName']?.toString()),
                              builder: (_, snap) {
                                final name = snap.data ?? patientId;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                    SizedBox(height: 2),
                                    Text('ID: $patientId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: type == 'Online' ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(type == 'Online' ? Icons.videocam : Icons.local_hospital, size: 14, color: type == 'Online' ? Colors.green.shade700 : Colors.blue.shade700),
                                SizedBox(width: 4),
                                Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: type == 'Online' ? Colors.green.shade700 : Colors.blue.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24),

                      // Date + Reason
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                          SizedBox(width: 6),
                          Text(_fmt(date), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey.shade500),
                          SizedBox(width: 6),
                          Expanded(child: Text('Reason: $reason', style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Action buttons — Edit / Approve / Reject
                      Row(
                        children: [
                          // Edit
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editAppointment(doc.id, data),
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Approve
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(doc.id, 'Upcoming'),
                              icon: Icon(Icons.check, size: 18),
                              label: Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Reject
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(doc.id, 'Rejected'),
                              icon: Icon(Icons.close, size: 18),
                              label: Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
