import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientAppointmentsScreen extends StatelessWidget {
  final String patientId;

  const PatientAppointmentsScreen({Key? key, required this.patientId}) : super(key: key);

  // Helper to format the Date and Time nicely
  String _formatDateTime(DateTime dateTime) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch only the appointments that belong to THIS patient
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xffDC2626)));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading appointments.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments booked yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // Sort locally by date to avoid Firebase Indexing errors
          var appointments = snapshot.data!.docs.toList();
          appointments.sort((a, b) {
            var dateA = (a['appointmentDate'] as Timestamp).toDate();
            var dateB = (b['appointmentDate'] as Timestamp).toDate();
            return dateB.compareTo(dateA); // Newest / furthest out first
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var data = appointments[index].data() as Map<String, dynamic>;
              
              String doctorName = data['doctorName'] ?? 'Unknown Doctor';
              String specialty = data['specialty'] ?? '';
              String hospital = data['hospital'] ?? 'Hospital not listed';
              String status = data['status'] ?? 'Waiting';
              String reason = data['reason'] ?? 'Not provided';
              String? cancelReason = data['cancelReason']; // Might be null
              
              DateTime appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
              
              // Dynamic Color coding for the Status Pill
              Color statusColor = Colors.grey;
              Color statusBgColor = Colors.grey.shade100;
              
              if (status == 'Waiting') {
                statusColor = Colors.orange.shade800;
                statusBgColor = Colors.orange.shade100;
              } else if (status == 'Upcoming') {
                statusColor = Colors.green.shade800;
                statusBgColor = Colors.green.shade100;
              } else if (status == 'Cancelled' || status == 'Rejected') {
                statusColor = Colors.red.shade800;
                statusBgColor = Colors.red.shade100;
              } else if (status == 'Completed') {
                statusColor = Colors.blue.shade800;
                statusBgColor = Colors.blue.shade100;
              }

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Doctor Info & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.person, color: Color(0xffDC2626), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B))),
                                const SizedBox(height: 2),
                                Text(specialty, style: const TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      
                      // Middle Row: Date & Location
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(appointmentDate),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hospital,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // Bottom Row: Reason for Visit
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reason for visit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(reason, style: const TextStyle(fontSize: 13, color: Color(0xff1E293B), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),

                      // Conditional: Show Doctor's Cancellation Reason if applicable
                      if (status == 'Cancelled' && cancelReason != null && cancelReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cancellation Reason from Doctor:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 4),
                              Text(cancelReason, style: TextStyle(fontSize: 13, color: Colors.red.shade900)),
                            ],
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