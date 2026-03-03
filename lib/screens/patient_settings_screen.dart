import 'package:flutter/material.dart';
import '../../main.dart'; // To access themeNotifier
import '../services/auth_service.dart';
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI memory cleared!')));
                },
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.download,
                iconColor: Colors.green,
                title: 'Export Records',
                subtitle: 'Download your timeline data',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exporting records...')));
                },
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
