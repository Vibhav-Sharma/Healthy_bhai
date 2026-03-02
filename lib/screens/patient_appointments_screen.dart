import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final String patientId;

  PatientAppointmentsScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {

  // --- SAFE DATE PARSER ---
  // Prevents crashes if old test data was saved as Strings and new data as Timestamps
  DateTime _parseDate(dynamic dateData) {
    if (dateData == null) return DateTime.now();
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
    return DateTime.now(); // Fallback for any other weird data
  }

  // --- Helper to format the Date and Time nicely ---
  String _formatDateTime(DateTime dateTime) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }

  // --- Cancel Appointment Logic ---
  Future<void> _cancelAppointment(String appointmentId, String currentStatus) async {
    bool confirm = true;

    if (currentStatus == 'Upcoming') {
      bool? result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Cancel Appointment?'),
            ],
          ),
          content: Text('The doctor has already confirmed this appointment. Are you sure you want to cancel it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: Text('Keep it', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      confirm = result ?? false; 
    }

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
          'status': 'Cancelled',
          'cancelReason': 'Cancelled by patient.',
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment successfully cancelled.'), backgroundColor: Colors.red)
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Appointments',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: widget.patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xffDC2626)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading appointments.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Text(
                    'No appointments booked yet.',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // --- SMART SORTING ALGORITHM (Using the safe parser) ---
          DateTime now = DateTime.now();
          var allAppointments = snapshot.data!.docs.toList();
          
          var upcoming = allAppointments.where((doc) {
            DateTime d = _parseDate((doc.data() as Map<String, dynamic>)['appointmentDate']);
            return d.isAfter(now) || d.isAtSameMomentAs(now);
          }).toList();
          
          var past = allAppointments.where((doc) {
            DateTime d = _parseDate((doc.data() as Map<String, dynamic>)['appointmentDate']);
            return d.isBefore(now);
          }).toList();

          upcoming.sort((a, b) {
            DateTime dateA = _parseDate((a.data() as Map<String, dynamic>)['appointmentDate']);
            DateTime dateB = _parseDate((b.data() as Map<String, dynamic>)['appointmentDate']);
            return dateA.compareTo(dateB);
          });
          
          past.sort((a, b) {
            DateTime dateA = _parseDate((a.data() as Map<String, dynamic>)['appointmentDate']);
            DateTime dateB = _parseDate((b.data() as Map<String, dynamic>)['appointmentDate']);
            return dateB.compareTo(dateA); 
          });

          var sortedAppointments = [...upcoming, ...past];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sortedAppointments.length,
            itemBuilder: (context, index) {
              var doc = sortedAppointments[index];
              var data = doc.data() as Map<String, dynamic>;
              
              String appointmentId = doc.id; 
              
              // Safe String Casting for all Firebase fields
              String rawDoctorName = (data['doctorName'] ?? 'Unknown').toString();
              String doctorName = rawDoctorName.toLowerCase().startsWith('dr') 
                  ? rawDoctorName 
                  : 'Dr. $rawDoctorName';

              String specialty = (data['specialty'] ?? '').toString();
              String type = (data['type'] ?? 'Offline').toString(); 
              String hospital = (data['hospital'] ?? '').toString();
              if (hospital == 'Not specified') hospital = ''; 
              
              String locationText = type == 'Online' 
                  ? 'Online Video Consultation' 
                  : (hospital.isNotEmpty ? hospital : 'In-Clinic Consultation');
              
              String status = (data['status'] ?? 'Waiting').toString();
              String reason = (data['reason'] ?? 'Not provided').toString();
              String? cancelReason = data['cancelReason']?.toString(); 
              String? meetLink = data['meetLink']?.toString(); 
              
              // Safely pull the date
              DateTime appointmentDate = _parseDate(data['appointmentDate']);
              
              // Status Pill Colors
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
                      // Top Row: Doctor Info & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.person, color: Color(0xffDC2626), size: 28),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                SizedBox(height: 2),
                                Text(specialty, style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.w500, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                      
                      // --- Date & Online/Offline Mode ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                _formatDateTime(appointmentDate),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],
                          ),
                          
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: type == 'Online' ? Colors.purple.shade50 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: type == 'Online' ? Colors.purple.shade200 : Colors.teal.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(type == 'Online' ? Icons.videocam : Icons.business, size: 14, color: type == 'Online' ? Colors.purple : Colors.teal),
                                SizedBox(width: 4),
                                Text(type == 'Online' ? 'Online' : 'In-Clinic', style: TextStyle(color: type == 'Online' ? Colors.purple : Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        ],
                      ),

                      if (type == 'Offline' && hospital.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text(hospital, style: TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                      
                      SizedBox(height: 16),

                      // --- Reason for Visit ---
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

                      // --- Cancellation Reason ---
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

                      // --- GOOGLE MEET LINK ---
                      if (type == 'Online' && meetLink != null && status != 'Cancelled' && status != 'Rejected') ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.link, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Meeting Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                              SizedBox(height: 8),
                              SelectableText(
                                meetLink, 
                                style: TextStyle(fontSize: 13, color: Colors.blue.shade900, decoration: TextDecoration.underline)
                              ),
                              
                              if (status == 'Upcoming') ...[
                                SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Opening Meet: $meetLink'), backgroundColor: Colors.blue)
                                      );
                                    },
                                    icon: Icon(Icons.video_call, color: Colors.white),
                                    label: Text('Join Google Meet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(height: 8),
                                Text(
                                  'Link will become active once the doctor approves the appointment.', 
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontStyle: FontStyle.italic)
                                )
                              ]
                            ],
                          ),
                        ),
                      ],

                      // --- CANCEL BUTTON FOR PATIENT ---
                      if (status == 'Waiting' || status == 'Upcoming') ...[
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _cancelAppointment(appointmentId, status),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Cancel Appointment', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],

                      // --- PRESCRIPTION STATUS ---
                      if (status == 'Completed' || status == 'Upcoming') ...[
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                    SizedBox(width: 8),
                                    Text('Prescription Available', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                SizedBox(height: 8),
                                SelectableText(
                                  data['prescriptionUrl'].toString(),
                                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          )
                        else if (status == 'Completed')
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_empty, color: Colors.amber.shade700, size: 18),
                                SizedBox(width: 8),
                                Text('Prescription pending from doctor', style: TextStyle(color: Colors.amber.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
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