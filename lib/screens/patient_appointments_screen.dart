import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final String patientId;
  const PatientAppointmentsScreen({super.key, required this.patientId});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
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
      final data = await FirestoreService.getPatientAppointments(widget.patientId);
      if (mounted) setState(() { _appointments = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookAppointmentDialog() async {
    final doctors = await FirestoreService.getAllDoctors();
    if (!mounted) return;

    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No doctors available.')));
      return;
    }

    String? selectedDoctorId;
    String? selectedDoctorName;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final symptomsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Book Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Doctor'),
                      items: doctors.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc['doctorId'],
                          child: Text('Dr. ${doc['name']} (${doc['specialization'] ?? 'General'})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedDoctorId = val;
                          final doc = doctors.firstWhere((element) => element['doctorId'] == val);
                          selectedDoctorName = doc['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(selectedDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) setStateDialog(() => selectedDate = date);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 10, minute: 0),
                        );
                        if (time != null) setStateDialog(() => selectedTime = time);
                      },
                    ),
                    TextField(
                      controller: symptomsController,
                      decoration: const InputDecoration(labelText: 'Symptoms (Optional)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDoctorId == null || selectedDate == null || selectedTime == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    Navigator.pop(ctx);
                    final appointmentDateTime = DateTime(
                      selectedDate!.year, selectedDate!.month, selectedDate!.day,
                      selectedTime!.hour, selectedTime!.minute,
                    );
                    
                    await FirestoreService.bookAppointment(
                      patientId: widget.patientId,
                      doctorId: selectedDoctorId!,
                      doctorName: selectedDoctorName ?? 'Unknown',
                      appointmentDate: appointmentDateTime,
                      symptoms: symptomsController.text,
                    );
                    _loadAppointments();
                  },
                  child: const Text('Book'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(color: Color(0xffDC2626))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xffDC2626)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookAppointmentDialog,
        backgroundColor: const Color(0xffDC2626),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Now', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No appointments booked yet.'))
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
                          backgroundColor: Colors.red[50],
                          child: const Icon(Icons.medical_services, color: Color(0xffDC2626)),
                        ),
                        title: Text('Dr. ${apt['doctorName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          label: Text(apt['status'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                          backgroundColor: Colors.blue[50],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
