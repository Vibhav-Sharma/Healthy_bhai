import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorDashboard extends StatefulWidget {
  final String doctorId;

  const DoctorDashboard({super.key, required this.doctorId});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _navIndex = 0;
  final Map<String, String> _patientNameCache = {};

  Future<String> _getPatientName(String patientId) async {
    if (_patientNameCache.containsKey(patientId)) {
      return _patientNameCache[patientId]!;
    }
    final name = await FirestoreService.getPatientName(patientId);
    _patientNameCache[patientId] = name;
    return name;
  }

  // ✅ SAFE DATE PARSER (Prevents Timestamp crash)
  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();

    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is DateTime) return dateData;

    if (dateData is String) {
      try {
        return DateTime.parse(dateData);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  String _formatDateTime(DateTime dateTime) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    String ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }

  // ✅ UPDATE STATUS (Approve / Reject / Cancel)
  Future<void> _updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      if (newStatus == 'Cancelled') {
        TextEditingController reasonController =
            TextEditingController();

        bool? confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Provide cancellation reason:'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Doctor unavailable, emergency, etc.',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({
          'status': 'Cancelled',
          'cancelReason': reasonController.text.trim(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({
          'status': newStatus,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment $newStatus successfully'),
          backgroundColor:
              newStatus == 'Upcoming' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;

    if (index == 0) {
      setState(() {
        _navIndex = 0;
      });
      return;
    }

    // for other indices we navigate but reset back to appointments once done
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorPatientSearchScreen(doctorId: widget.doctorId),
        ),
      ).then((_) {
        if (mounted) setState(() => _navIndex = 0);
      });
    } else if (index == 2) {
      _showProfileDialog();
      if (mounted) setState(() => _navIndex = 0);
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doctor Profile'),
        content: Text(
            'Doctor ID: ${widget.doctorId}\nManage account settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context)
                    .popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Logout',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xff1E293B),
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _navIndex == 0
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('doctorId', isEqualTo: widget.doctorId)
                  .orderBy('appointmentDate')
                  .snapshots(),
              builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading appointments: ${snapshot.error}'));
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No appointments yet.'));
          }

          var appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var doc = appointments[index];
              var data =
                  doc.data() as Map<String, dynamic>;

              String appointmentId = doc.id;
              String patientId =
                  data['patientId']?.toString() ?? 'Unknown';
              String status =
                  data['status']?.toString() ?? 'Waiting';
              String reason =
                  data['reason']?.toString() ??
                      'No reason provided';

              DateTime date =
                  _parseDate(data['appointmentDate']);

              return Card(
                margin:
                    const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getPatientName(patientId),
                              builder: (context, nameSnap) {
                                String displayName = nameSnap.data ?? patientId;
                                return Text(
                                  displayName,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: status ==
                                        'Upcoming'
                                    ? Colors.green
                                    : status ==
                                            'Waiting'
                                        ? Colors.orange
                                        : Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_formatDateTime(date)),
                      const SizedBox(height: 8),
                      Text('Reason: $reason'),
                      const SizedBox(height: 12),

                      // ACTION BUTTONS
                      if (status == 'Waiting')
                        Row(
                          children: [
                            Expanded(
                              child:
                                  ElevatedButton(
                                onPressed: () =>
                                    _updateAppointmentStatus(
                                        appointmentId,
                                        'Upcoming'),
                                style: ElevatedButton
                                    .styleFrom(
                                        backgroundColor:
                                            Colors
                                                .green),
                                child: const Text(
                                    'Approve',
                                    style: TextStyle(
                                        color: Colors
                                            .white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  ElevatedButton(
                                onPressed: () =>
                                    _updateAppointmentStatus(
                                        appointmentId,
                                        'Rejected'),
                                style: ElevatedButton
                                    .styleFrom(
                                        backgroundColor:
                                            Colors.red),
                                child: const Text(
                                    'Reject',
                                    style: TextStyle(
                                        color: Colors
                                            .white)),
                              ),
                            ),
                          ],
                        ),

                      if (status == 'Upcoming')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                _updateAppointmentStatus(
                                    appointmentId,
                                    'Cancelled'),
                            style: OutlinedButton
                                .styleFrom(
                                    side:
                                        const BorderSide(
                                            color:
                                                Colors
                                                    .red)),
                            child: const Text(
                                'Cancel Appointment',
                                style: TextStyle(
                                    color:
                                        Colors.red)),
                          ),
                        ),

                      if (status == 'Cancelled' &&
                          data['cancelReason'] !=
                              null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  top: 8),
                          child: Text(
                            'Cancellation Reason: ${data['cancelReason']}',
                            style: const TextStyle(
                                color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DoctorPatientDetailScreen(
                              patientId: patientId,
                              doctorId:
                                  widget.doctorId,
                            ),
                          ),
                        ),
                        child: const Text(
                            'View Patient Profile'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )
          : const SizedBox.shrink(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}