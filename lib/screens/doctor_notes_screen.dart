import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class DoctorNotesScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  DoctorNotesScreen({super.key, required this.patientId, required this.doctorId});

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please write a note first.')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note saved successfully!')));
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Add Medical Note', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _isSaving
              ? Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(onPressed: _save, child: Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(color: Colors.grey.withValues(alpha: 0.2), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('Patient ${widget.patientId}', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Spacer(),
                Text('Doctor ${widget.doctorId}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: null,
              minLines: 10,
              decoration: InputDecoration(
                hintText: 'Type your clinical notes here...\n\ne.g., "Patient reports mild headache. Advised to avoid sugar and continue medicine for 5 more days."',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), height: 1.5),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
