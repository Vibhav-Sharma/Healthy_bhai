import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../main.dart'; // To access themeNotifier
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'home_selection_screen.dart';

class PatientSettingsScreen extends StatefulWidget {
  final String patientId;

  PatientSettingsScreen({super.key, required this.patientId});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _medReminders = true;
  bool _appointmentAlerts = true;

  // ─── Clear AI Memory ───
  Future<void> _clearAiMemory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear AI Memory?'),
        content: Text('This will delete all AI advice history from your timeline. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final count = await FirestoreService.deleteAiTimelineEvents(widget.patientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(count > 0 ? 'Cleared $count AI memory entries!' : 'No AI memory to clear.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing AI memory: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Export Records ───
  Future<void> _exportRecords() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing your records...')),
    );

    try {
      // Fetch all data
      final patientData = await FirestoreService.getPatientByPatientId(widget.patientId);
      final reports = await FirestoreService.getReports(widget.patientId);
      final notes = await FirestoreService.getNotes(widget.patientId);
      final timeline = await FirestoreService.getTimeline(widget.patientId);
      final medicines = await FirestoreService.getMedicines(widget.patientId);
      final appointments = await FirestoreService.getPatientAppointments(widget.patientId);

      // Format the export
      final buf = StringBuffer();
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      buf.writeln('═══════════════════════════════════════════');
      buf.writeln('       SWASTHYA — PATIENT HEALTH RECORDS');
      buf.writeln('═══════════════════════════════════════════');
      buf.writeln('Exported on: $now');
      buf.writeln('Patient ID:  ${widget.patientId}');
      buf.writeln('');

      // ── Profile ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  PROFILE');
      buf.writeln('───────────────────────────────────────────');
      if (patientData != null) {
        buf.writeln('Name:             ${patientData['name'] ?? 'N/A'}');
        buf.writeln('Blood Group:      ${patientData['bloodGroup'] ?? 'N/A'}');
        buf.writeln('Phone:            ${patientData['phone'] ?? 'N/A'}');
        buf.writeln('Emergency Contact: ${patientData['emergencyContact'] ?? 'N/A'}');
        buf.writeln('Allergies:        ${_formatList(patientData['allergies'])}');
        buf.writeln('Current Diseases: ${_formatList(patientData['currentDiseases'])}');
        buf.writeln('Chronic Diseases: ${_formatList(patientData['chronicDiseases'])}');
        buf.writeln('Past Diseases:    ${_formatList(patientData['pastDiseases'])}');
        buf.writeln('Current Medicines: ${_formatList(patientData['currentMedicines'])}');
        buf.writeln('Old Medicines:    ${_formatList(patientData['oldMedicines'])}');
        buf.writeln('Surgeries:        ${_formatList(patientData['surgeries'])}');
        buf.writeln('Treatments:       ${_formatList(patientData['treatments'])}');
      } else {
        buf.writeln('  No profile data found.');
      }
      buf.writeln('');

      // ── Medicines / Prescriptions ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  MEDICINES (${medicines.length})');
      buf.writeln('───────────────────────────────────────────');
      if (medicines.isEmpty) {
        buf.writeln('  No medicines found.');
      } else {
        for (int i = 0; i < medicines.length; i++) {
          final m = medicines[i];
          final active = m['active'] == true ? '✓ Active' : '✗ Expired';
          buf.writeln('  ${i + 1}. ${m['name'] ?? 'Unknown'} — $active');
          buf.writeln('     Dosage:    ${m['dosage'] ?? 'N/A'}');
          buf.writeln('     Frequency: ${m['frequency'] ?? 'N/A'}');
          buf.writeln('     Duration:  ${m['duration'] ?? 'N/A'}');
          final expires = (m['expiresAt'] as Timestamp?)?.toDate();
          if (expires != null) {
            buf.writeln('     Expires:   ${DateFormat('dd MMM yyyy').format(expires)}');
          }
          buf.writeln('');
        }
      }

      // ── Reports ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  UPLOADED REPORTS (${reports.length})');
      buf.writeln('───────────────────────────────────────────');
      if (reports.isEmpty) {
        buf.writeln('  No reports uploaded.');
      } else {
        for (int i = 0; i < reports.length; i++) {
          final r = reports[i];
          final date = _formatTimestamp(r['date']);
          buf.writeln('  ${i + 1}. ${r['fileName'] ?? 'Unnamed'}');
          buf.writeln('     Type: ${r['type'] ?? 'N/A'}  |  Date: $date');
          buf.writeln('');
        }
      }

      // ── Doctor Notes ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  DOCTOR NOTES (${notes.length})');
      buf.writeln('───────────────────────────────────────────');
      if (notes.isEmpty) {
        buf.writeln('  No doctor notes.');
      } else {
        for (int i = 0; i < notes.length; i++) {
          final n = notes[i];
          final date = _formatTimestamp(n['date']);
          buf.writeln('  ${i + 1}. [$date] by Dr. ${n['doctorId'] ?? 'Unknown'}');
          buf.writeln('     ${n['note'] ?? ''}');
          buf.writeln('');
        }
      }

      // ── Appointments ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  APPOINTMENTS (${appointments.length})');
      buf.writeln('───────────────────────────────────────────');
      if (appointments.isEmpty) {
        buf.writeln('  No appointments.');
      } else {
        for (int i = 0; i < appointments.length; i++) {
          final a = appointments[i];
          final date = (a['appointmentDate'] as Timestamp?)?.toDate();
          final dateStr = date != null ? DateFormat('dd MMM yyyy, hh:mm a').format(date) : 'N/A';
          buf.writeln('  ${i + 1}. Dr. ${a['doctorName'] ?? 'Unknown'} — ${a['status'] ?? ''}');
          buf.writeln('     Date: $dateStr  |  Type: ${a['type'] ?? 'N/A'}');
          buf.writeln('     Reason: ${a['reason'] ?? 'N/A'}');
          buf.writeln('');
        }
      }

      // ── Timeline ──
      buf.writeln('───────────────────────────────────────────');
      buf.writeln('  TIMELINE (${timeline.length})');
      buf.writeln('───────────────────────────────────────────');
      if (timeline.isEmpty) {
        buf.writeln('  No timeline events.');
      } else {
        for (final t in timeline) {
          final date = _formatTimestamp(t['date']);
          buf.writeln('  [$date] ${t['event'] ?? ''}');
        }
      }

      buf.writeln('');
      buf.writeln('═══════════════════════════════════════════');
      buf.writeln('          END OF HEALTH RECORDS');
      buf.writeln('═══════════════════════════════════════════');

      // Save to file using FilePicker
      final content = buf.toString();
      final fileName = 'Swasthya_Records_${widget.patientId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
      final bytes = utf8.encode(content);

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Health Records',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: Uint8List.fromList(bytes),
      );

      if (savePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Records saved successfully!'), duration: Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting records: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatList(dynamic list) {
    if (list == null) return 'None';
    if (list is List) return list.isEmpty ? 'None' : list.join(', ');
    return list.toString();
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      final date = (ts as dynamic).toDate() as DateTime;
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme to adjust text colors
    final isDark = themeNotifier.value == ThemeMode.dark;
    final bgColor = isDark ? Color(0xff121212) : Color(0xffF3F4F6);
    final cardColor = isDark ? Color(0xff1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Color(0xff1E293B);
    final subheadColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: isDark ? Colors.grey[800] : Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Appearance', subheadColor!),
            _buildCardGroup(cardColor, [
              _buildSwitchTile(
                icon: Icons.dark_mode,
                iconColor: Colors.deepPurple,
                title: 'Dark Mode',
                value: isDark,
                onChanged: (val) {
                  setState(() {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  });
                },
                textColor: textColor,
              ),
            ]),
            SizedBox(height: 24),

            _buildSectionHeader('Emergency Setup', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.contact_emergency,
                iconColor: Colors.red,
                title: 'Emergency Contacts',
                subtitle: 'Manage trusted contacts',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feature coming soon!')));
                },
              ),
            ]),
            SizedBox(height: 24),

            _buildSectionHeader('Notifications', subheadColor),
            _buildCardGroup(cardColor, [
              _buildSwitchTile(
                icon: Icons.medication,
                iconColor: Colors.teal,
                title: 'Medicine Reminders',
                value: _medReminders,
                onChanged: (val) => setState(() => _medReminders = val),
                textColor: textColor,
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                icon: Icons.calendar_today,
                iconColor: Colors.blue,
                title: 'Appointment Alerts',
                value: _appointmentAlerts,
                onChanged: (val) => setState(() => _appointmentAlerts = val),
                textColor: textColor,
              ),
            ]),
            SizedBox(height: 24),

            _buildSectionHeader('Data & Privacy', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.memory,
                iconColor: Colors.orange,
                title: 'Clear AI Memory',
                subtitle: 'Reset assistant conversation',
                textColor: textColor,
                onTap: () => _clearAiMemory(),
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.download,
                iconColor: Colors.green,
                title: 'Export Records',
                subtitle: 'Download all your health data as a file',
                textColor: textColor,
                onTap: () => _exportRecords(),
              ),
            ]),
            SizedBox(height: 24),

            _buildSectionHeader('Account', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.security,
                iconColor: Colors.blueGrey,
                title: 'Change Password',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent!')));
                },
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.logout,
                iconColor: Colors.redAccent,
                title: 'Log Out',
                textColor: Colors.redAccent,
                onTap: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => HomeSelectionScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ]),
            SizedBox(height: 24),

            _buildSectionHeader('About & Support', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.info_outline,
                iconColor: Color(0xffDC2626),
                title: 'About Swasthya',
                subtitle: 'Version 1.0.0',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Swasthya v1.0.0')));
                },
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.help_outline,
                iconColor: Color(0xffDC2626),
                title: 'Help & Support',
                subtitle: 'Contact us for any issues',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact support@swasthya.com')));
                },
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Color(0xffDC2626),
                title: 'Terms & Privacy',
                subtitle: 'Read our data policies',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terms & Privacy')));
                },
              ),
            ]),

            SizedBox(height: 48),
            Center(
              child: Text(
                'Swasthya v1.0.0',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCardGroup(Color bgColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: 56),
      color: isDark ? Colors.grey[800] : Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: Color(0xffDC2626),
      ),
    );
  }
}
