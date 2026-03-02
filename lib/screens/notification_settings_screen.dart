import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  /// Pass 'patient' or 'doctor' to show relevant toggles.
  final String role;
  const NotificationSettingsScreen({super.key, required this.role});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final med = await ReminderService.isMedicationRemindersEnabled();
    final appt = await ReminderService.isAppointmentRemindersEnabled();
    if (mounted) {
      setState(() {
        _medicationReminders = med;
        _appointmentReminders = appt;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notification Settings',
            style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff3B82F6), Color(0xff1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Push Notifications',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Control which alerts you receive.',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Patient: Medication Reminders ──
                  if (widget.role == 'patient') ...[
                    const Text('MEDICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      icon: Icons.medication,
                      iconColor: Colors.green,
                      title: 'Medication Reminders',
                      subtitle: 'Get push notifications when it\'s time to take your medicines (from scanned prescriptions).',
                      value: _medicationReminders,
                      onChanged: (val) async {
                        setState(() => _medicationReminders = val);
                        await ReminderService.setMedicationRemindersEnabled(val);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(val ? 'Medication reminders enabled' : 'Medication reminders disabled')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Doctor / Patient: Appointment Reminders ──
                  const Text('APPOINTMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  _buildToggleTile(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    title: 'Appointment Alerts',
                    subtitle: widget.role == 'doctor'
                        ? 'Get notified 30 minutes before your upcoming patient appointments.'
                        : 'Get notified 30 minutes before your upcoming doctor appointments.',
                    value: _appointmentReminders,
                    onChanged: (val) async {
                      setState(() => _appointmentReminders = val);
                      await ReminderService.setAppointmentRemindersEnabled(val);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Appointment alerts enabled' : 'Appointment alerts disabled')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFED7AA)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xffF59E0B), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Medication reminders are set automatically when you scan a prescription with AI. '
                            'Disabling them will cancel all active medicine notifications.',
                            style: TextStyle(fontSize: 13, color: Color(0xff92400E), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff1E293B))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xff16A34A),
          ),
        ],
      ),
    );
  }
}
