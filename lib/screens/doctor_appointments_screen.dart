import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String doctorId;
  const DoctorAppointmentsScreen({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final data = await FirestoreService.getDoctorAppointments(widget.doctorId);
      if (mounted) setState(() { _appointments = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: const Text('My Schedule', style: TextStyle(color: Color(0xffDC2626))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xffDC2626)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No upcoming appointments.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final apt = _appointments[index];
                    final date = (apt['appointmentDate'] as Timestamp).toDate();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text('Patient ID: ${apt['patientId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date)),
                            if ((apt['symptoms'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Symptoms: ${apt['symptoms']}'),
                            ]
                          ],
                        ),
                        trailing: Chip(
                          label: Text(apt['status'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.green)),
                          backgroundColor: Colors.green[50],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
