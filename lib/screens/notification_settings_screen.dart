import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  /// Pass 'patient' or 'doctor' to show relevant toggles.
  final String role;
  NotificationSettingsScreen({super.key, required this.role});

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notification Settings',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff3B82F6), Color(0xff1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
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

                  SizedBox(height: 32),

                  // ── Patient: Medication Reminders ──
                  if (widget.role == 'patient') ...[
                    Text('MEDICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    SizedBox(height: 12),
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
                    SizedBox(height: 24),
                  ],

                  // ── Doctor / Patient: Appointment Reminders ──
                  Text('APPOINTMENTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  SizedBox(height: 12),
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

                  SizedBox(height: 32),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xffFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xffFED7AA)),
                    ),
                    child: Row(
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor, ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.3)),
              ],
            ),
          ),
          SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xff16A34A),
          ),
        ],
      ),
    );
  }
}
