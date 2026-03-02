import 'package:flutter/material.dart';
import '../../main.dart'; // To access themeNotifier
import '../services/auth_service.dart';
import 'home_selection_screen.dart';

class DoctorSettingsScreen extends StatefulWidget {
  final String doctorId;

  const DoctorSettingsScreen({super.key, required this.doctorId});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  bool _newAppointmentAlerts = true;
  bool _cancellationAlerts = true;

  @override
  Widget build(BuildContext context) {
    // Listen to theme to adjust text colors
    final isDark = themeNotifier.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xff121212) : const Color(0xffF3F4F6);
    final cardColor = isDark ? const Color(0xff1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff1E293B);
    final subheadColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text('Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: isDark ? Colors.grey[800] : Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),

            _buildSectionHeader('Availability', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.access_time,
                iconColor: Colors.blue,
                title: 'Working Hours',
                subtitle: 'Set schedule (e.g., 9AM - 5PM)',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Working hours configured!')));
                },
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.block,
                iconColor: Colors.orange,
                title: 'Manage Leaves',
                subtitle: 'Block out dates on calendar',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave dates updated!')));
                },
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Notifications', subheadColor),
            _buildCardGroup(cardColor, [
              _buildSwitchTile(
                icon: Icons.event_available,
                iconColor: Colors.teal,
                title: 'New Appointment Alerts',
                value: _newAppointmentAlerts,
                onChanged: (val) => setState(() => _newAppointmentAlerts = val),
                textColor: textColor,
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                icon: Icons.event_busy,
                iconColor: Colors.redAccent,
                title: 'Cancellation Alerts',
                value: _cancellationAlerts,
                onChanged: (val) => setState(() => _cancellationAlerts = val),
                textColor: textColor,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Account', subheadColor),
            _buildCardGroup(cardColor, [
              _buildActionTile(
                icon: Icons.security,
                iconColor: Colors.blueGrey,
                title: 'Change Password',
                textColor: textColor,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent!')));
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
                      MaterialPageRoute(builder: (_) => const HomeSelectionScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ]),

            const SizedBox(height: 48),
            Center(
              child: Text(
                'Healthy Bhai (Doctor) v1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: isDark ? Colors.grey[800] : Colors.grey[100],
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xffDC2626),
      ),
    );
  }
}
