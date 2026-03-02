import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class DoctorNotesScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  const DoctorNotesScreen({super.key, required this.patientId, required this.doctorId});

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write a note first.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save note to Firestore
      await FirestoreService.addNote(
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        note: _noteController.text.trim(),
      );

      // Add timeline event
      await FirestoreService.addTimelineEvent(
        patientId: widget.patientId,
        event: 'Doctor Note added by ${widget.doctorId}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved successfully!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Color(0xff1E293B)), onPressed: () => Navigator.pop(context)),
        title: const Text('Add Medical Note', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(onPressed: _save, child: const Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey[100], height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                  child: Text('Patient ${widget.patientId}', style: const TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('Doctor ${widget.doctorId}', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: null,
              minLines: 10,
              decoration: InputDecoration(
                hintText: 'Type your clinical notes here...\n\ne.g., "Patient reports mild headache. Advised to avoid sugar and continue medicine for 5 more days."',
                hintStyle: TextStyle(color: Colors.grey[400], height: 1.5),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xff1E293B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
