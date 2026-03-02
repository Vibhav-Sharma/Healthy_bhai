import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../services/reminder_service.dart';
import '../services/med_abbreviation_service.dart';
import '../services/calendar_service.dart';

class PrescriptionScanScreen extends StatefulWidget {
  final String patientId;
  const PrescriptionScanScreen({super.key, required this.patientId});

  @override
  State<PrescriptionScanScreen> createState() => _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState extends State<PrescriptionScanScreen> {
  File? _image;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _extractedMedicines = [];
  String _processingStatus = '';

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedMedicines = []; // Reset on new image
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Reading prescription with AI...';
    });

    try {
      final bytes = await _image!.readAsBytes();

      // Try extraction with auto-retry on rate-limit
      Map<String, dynamic> data;
      try {
        data = await GeminiService.extractPrescription(bytes);
      } catch (e) {
        if (e.toString().toLowerCase().contains('quota') ||
            e.toString().toLowerCase().contains('rate') ||
            e.toString().toLowerCase().contains('429') ||
            e.toString().toLowerCase().contains('resource_exhausted')) {
          // Rate-limited — wait and retry once
          if (mounted) setState(() => _processingStatus = 'Rate-limited, retrying in 10s...');
          await Future.delayed(const Duration(seconds: 10));
          if (mounted) setState(() => _processingStatus = 'Retrying prescription read...');
          data = await GeminiService.extractPrescription(bytes);
        } else {
          rethrow;
        }
      }

      final medicines = List<Map<String, dynamic>>.from(data['medicines']);

      if (medicines.isNotEmpty) {
        // Step 2: Spell-check medicine names via Gemini
        if (mounted) setState(() => _processingStatus = 'Verifying medicine names...');
        final names = medicines.map((m) => (m['name'] ?? '') as String).where((n) => n.isNotEmpty).toList();
        final corrections = await GeminiService.correctMedicineNames(names);

        // Apply corrections
        for (final med in medicines) {
          final original = (med['name'] ?? '') as String;
          if (corrections.containsKey(original)) {
            final corrected = corrections[original]!;
            if (corrected != original) {
              med['original_name'] = original;  // Keep OCR name for reference
              med['name'] = corrected;          // Use corrected name
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _extractedMedicines = medicines;
          _isProcessing = false;
          _processingStatus = '';
        });

        if (_extractedMedicines.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find any medicines in this image.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveAndSetReminders() async {
    if (_extractedMedicines.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Save to Firestore
      await FirestoreService.saveMedicinesFromPrescription(
        patientId: widget.patientId,
        medicines: _extractedMedicines,
      );

      // 2. Schedule Local Notifications using smart abbreviation parsing
      int baseId = DateTime.now().millisecondsSinceEpoch ~/ 100000;
      for (int i = 0; i < _extractedMedicines.length; i++) {
        final med = _extractedMedicines[i];
        final frequency = (med['frequency'] as String?) ?? '';
        final timingContext = (med['timing_context'] as String?) ?? '';
        final fallbackTimings = List<String>.from(med['timings'] ?? []);

        await ReminderService.scheduleMedicineReminder(
          id: baseId + i,
          medicineName: med['name'] ?? 'Medicine',
          dosage: med['dosage'] ?? '',
          frequency: frequency,
          timingContext: timingContext,
          fallbackTimings: fallbackTimings,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicines saved & reminders set!')),
        );

        // 3. Offer Google Calendar integration
        _showCalendarPrompt();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _showCalendarPrompt() {
    setState(() => _isProcessing = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Add to Google Calendar?', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: const Text(
          'Would you like to add these medicine reminders to your Google Calendar? '
          'You\'ll get calendar alerts on all your devices!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('ADD TO CALENDAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _addToGoogleCalendar();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addToGoogleCalendar() async {
    setState(() => _isProcessing = true);

    try {
      int addedCount = 0;
      for (final med in _extractedMedicines) {
        final name = med['name'] ?? 'Medicine';
        final dosage = med['dosage'] ?? '';
        final frequency = (med['frequency'] as String?) ?? '';
        final timingContext = (med['timing_context'] as String?) ?? '';
        final duration = (med['duration'] as String?) ?? '';
        final fallbackTimings = List<String>.from(med['timings'] ?? []);

        // Resolve schedule times
        List<ScheduleTime> schedule = MedAbbreviationService.resolve(frequency);
        if (schedule.isEmpty && timingContext.isNotEmpty) {
          schedule = MedAbbreviationService.resolve(timingContext);
        }
        if (schedule.isEmpty) {
          for (final t in fallbackTimings) {
            schedule.addAll(MedAbbreviationService.resolve(t));
          }
        }
        if (schedule.isEmpty) {
          schedule = [const ScheduleTime(hour: 9, minute: 0, label: 'Morning')];
        }

        // Parse duration into days
        int durationDays = CalendarService.parseDurationToDays(duration);

        for (final time in schedule) {
          await CalendarService.addMedicineEvent(
            medicineName: name,
            dosage: dosage,
            scheduleTime: time,
            durationDays: durationDays,
          );
          addedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $addedCount calendar events!')),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calendar error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Prescription', style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Extract Medicines with AI',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xff1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a clear photo of your prescription. Our AI will read the medicines and set daily reminders automatically.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),

            // Image Area
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 250, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!, width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner, size: 64, color: Colors.blue[200]),
                    const SizedBox(height: 16),
                    Text('No Image Selected', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAMERA'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('GALLERY'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Results Area
            if (_isProcessing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              if (_processingStatus.isNotEmpty)
                Center(child: Text(_processingStatus, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
            ] else if (_extractedMedicines.isNotEmpty) ...[
              const Text('Extracted Medicines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
              const SizedBox(height: 16),
              ..._extractedMedicines.map((med) => _buildMedicineCard(med)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAndSetReminders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE & SET REMINDERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final name = med['name'] ?? 'Unknown';
    final dosage = med['dosage'] ?? 'N/A';
    final frequency = (med['frequency'] as String?) ?? '';
    final timingContext = (med['timing_context'] as String?) ?? '';
    final duration = (med['duration'] as String?) ?? '';
    final fallbackTimings = List<String>.from(med['timings'] ?? []);

    // Resolve actual schedule times for display
    List<ScheduleTime> schedule = MedAbbreviationService.resolve(frequency);
    if (schedule.isEmpty && timingContext.isNotEmpty) {
      schedule = MedAbbreviationService.resolve(timingContext);
    }
    if (schedule.isEmpty) {
      for (final t in fallbackTimings) {
        schedule.addAll(MedAbbreviationService.resolve(t));
      }
    }

    final bool isAsNeeded = MedAbbreviationService.isAsNeeded(frequency);
    final String? freqDescription = MedAbbreviationService.describe(frequency);
    final scheduleText = isAsNeeded
        ? 'Take as needed'
        : schedule.isNotEmpty
            ? schedule.map((s) => s.formatted).join(', ')
            : fallbackTimings.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medication, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B))),
                    if (med['original_name'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'OCR: ${med['original_name']}',
                              style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text('Dosage: $dosage', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Frequency badge
          if (frequency.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoBadge(Icons.repeat, frequency.toUpperCase(), Colors.blue),
                if (freqDescription != null)
                  _infoBadge(Icons.info_outline, freqDescription, Colors.indigo),
                if (timingContext.isNotEmpty)
                  _infoBadge(Icons.restaurant, timingContext.toUpperCase(), Colors.orange),
                if (duration.isNotEmpty)
                  _infoBadge(Icons.date_range, duration, Colors.purple),
              ],
            ),
          const SizedBox(height: 8),
          // Schedule times
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  style: TextStyle(fontSize: 13, color: isAsNeeded ? Colors.orange[700] : Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
