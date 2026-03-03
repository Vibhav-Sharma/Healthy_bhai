import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xffDC2626)),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('About Swasthya', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info_outline, color: Color(0xffDC2626)),
          ),
          Divider(),
          ListTile(
            title: Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Contact us for any issues'),
            leading: Icon(Icons.help_outline, color: Color(0xffDC2626)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact support@swasthya.com')));
            },
          ),
          Divider(),
          ListTile(
            title: Text('Terms & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Read our data policies'),
            leading: Icon(Icons.privacy_tip_outlined, color: Color(0xffDC2626)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terms & Privacy clicked')));
            },
          ),
        ],
      ),
    );
  }
}
