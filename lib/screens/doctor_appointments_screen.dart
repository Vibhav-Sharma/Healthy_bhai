import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String doctorId;
  DoctorAppointmentsScreen({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  // Cache for patient names so we don't re-fetch on every rebuild
  final Map<String, String> _patientNameCache = {};

  // ✅ Safe date parser — handles Timestamp, String, and null
  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is DateTime) return dateData;
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    String minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $ampm';
  }

  Future<String> _getPatientName(String patientId, {String? storedName}) async {
    // If the appointment already has a name stored, use it directly
    if (storedName != null && storedName.isNotEmpty) {
      _patientNameCache[patientId] = storedName;
      return storedName;
    }
    if (_patientNameCache.containsKey(patientId)) {
      return _patientNameCache[patientId]!;
    }
    final name = await FirestoreService.getPatientName(patientId);
    _patientNameCache[patientId] = name;
    return name;
  }

  // ✅ Update appointment status (Approve / Reject / Cancel)
  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    try {
      if (newStatus == 'Cancelled') {
        TextEditingController reasonCtrl = TextEditingController();
        bool? confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Cancel Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Provide cancellation reason:'),
                SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Doctor unavailable, emergency, etc.',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Back')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  if (reasonCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
          'status': 'Cancelled',
          'cancelReason': reasonCtrl.text.trim(),
        });
      } else {
        await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
          'status': newStatus,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment $newStatus successfully'),
          backgroundColor: newStatus == 'Upcoming' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPrescriptionUploadDialog(String appointmentId, {String? existing}) async {
    final ctrl = TextEditingController(text: existing ?? '');
    bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Upload Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the prescription URL or paste prescription text:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'https://drive.google.com/... or prescription text',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved != true) return;
    try {
      await FirestoreService.uploadPrescription(appointmentId, ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription saved!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Schedule', style: TextStyle(color: Color(0xffDC2626))),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xffDC2626)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getDoctorAppointmentsStream(widget.doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xffDC2626)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading appointments: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Text('No upcoming appointments.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          // Sort: upcoming first (ascending), then past (descending)
          DateTime now = DateTime.now();
          var allDocs = snapshot.data!.docs.toList();

          var upcoming = allDocs.where((doc) {
            DateTime d = _parseDate((doc.data() as Map<String, dynamic>)['appointmentDate']);
            return d.isAfter(now) || d.isAtSameMomentAs(now);
          }).toList()
            ..sort((a, b) {
              DateTime dA = _parseDate((a.data() as Map<String, dynamic>)['appointmentDate']);
              DateTime dB = _parseDate((b.data() as Map<String, dynamic>)['appointmentDate']);
              return dA.compareTo(dB);
            });

          var past = allDocs.where((doc) {
            DateTime d = _parseDate((doc.data() as Map<String, dynamic>)['appointmentDate']);
            return d.isBefore(now);
          }).toList()
            ..sort((a, b) {
              DateTime dA = _parseDate((a.data() as Map<String, dynamic>)['appointmentDate']);
              DateTime dB = _parseDate((b.data() as Map<String, dynamic>)['appointmentDate']);
              return dB.compareTo(dA);
            });

          var sorted = [...upcoming, ...past];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              var doc = sorted[index];
              var data = doc.data() as Map<String, dynamic>;

              String appointmentId = doc.id;
              String patientId = data['patientId']?.toString() ?? 'Unknown';
              String status = data['status']?.toString() ?? 'Waiting';
              String reason = data['reason']?.toString() ?? data['symptoms']?.toString() ?? 'Not provided';
              String type = data['type']?.toString() ?? 'Offline';
              String? cancelReason = data['cancelReason']?.toString();
              DateTime date = _parseDate(data['appointmentDate']);

              // Status colors
              Color statusColor = Colors.grey;
              Color statusBg = Colors.grey.shade100;
              if (status == 'Waiting') {
                statusColor = Colors.orange.shade800;
                statusBg = Colors.orange.shade100;
              } else if (status == 'Upcoming') {
                statusColor = Colors.green.shade800;
                statusBg = Colors.green.shade100;
              } else if (status == 'Cancelled' || status == 'Rejected') {
                statusColor = Colors.red.shade800;
                statusBg = Colors.red.shade100;
              } else if (status == 'Completed') {
                statusColor = Colors.blue.shade800;
                statusBg = Colors.blue.shade100;
              }

              return Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Patient info + Status pill ───
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.person, color: Colors.blue, size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getPatientName(patientId, storedName: data['patientName']?.toString()),
                              builder: (context, nameSnap) {
                                String displayName = nameSnap.data ?? patientId;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                    SizedBox(height: 2),
                                    Text('ID: $patientId', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),

                      // ─── Date & Type ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(_formatDateTime(date), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          ]),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: type == 'Online' ? Colors.purple.shade50 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: type == 'Online' ? Colors.purple.shade200 : Colors.teal.shade200),
                            ),
                            child: Row(children: [
                              Icon(type == 'Online' ? Icons.videocam : Icons.business, size: 14, color: type == 'Online' ? Colors.purple : Colors.teal),
                              SizedBox(width: 4),
                              Text(type == 'Online' ? 'Online' : 'In-Clinic', style: TextStyle(color: type == 'Online' ? Colors.purple : Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // ─── Reason ───
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor, ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reason for visit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text(reason, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),

                      // ─── Cancellation reason ───
                      if ((status == 'Cancelled' || status == 'Rejected') && cancelReason != null && cancelReason.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cancellation Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              SizedBox(height: 4),
                              Text(cancelReason, style: TextStyle(fontSize: 13, color: Colors.red.shade900)),
                            ],
                          ),
                        ),
                      ],

                      // ─── Action Buttons ───
                      if (status == 'Waiting') ...[
                        SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(appointmentId, 'Upcoming'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(appointmentId, 'Rejected'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]),
                      ],

                      if (status == 'Upcoming') ...[
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(appointmentId, 'Cancelled'),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: Text('Cancel Appointment', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],

                      // ─── Prescription Upload ───
                      if (status == 'Upcoming' || status == 'Completed') ...[
                        SizedBox(height: 12),
                        if (data['prescriptionUrl'] != null && data['prescriptionUrl'].toString().isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                SizedBox(width: 8),
                                Expanded(child: Text('Prescription uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
                                TextButton(
                                  onPressed: () => _showPrescriptionUploadDialog(appointmentId, existing: data['prescriptionUrl'].toString()),
                                  child: Text('Update', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showPrescriptionUploadDialog(appointmentId),
                              icon: Icon(Icons.upload_file, size: 18),
                              label: Text('Upload Prescription'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(color: Colors.blue.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                      ],
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
