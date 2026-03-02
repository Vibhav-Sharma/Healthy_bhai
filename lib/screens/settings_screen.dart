import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xffDC2626)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('About Healthy Bhai', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info_outline, color: Color(0xffDC2626)),
          ),
          const Divider(),
          ListTile(
            title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Contact us for any issues'),
            leading: const Icon(Icons.help_outline, color: Color(0xffDC2626)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support@healthybhai.com')));
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Terms & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Read our data policies'),
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xffDC2626)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terms & Privacy clicked')));
            },
          ),
        ],
      ),
    );
  }
}
