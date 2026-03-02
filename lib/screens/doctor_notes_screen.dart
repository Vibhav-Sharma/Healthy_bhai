import 'package:flutter/material.dart';

class DoctorNotesScreen extends StatelessWidget {
  const DoctorNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Medical Note',
          style: TextStyle(
            color: Color(0xff1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
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
                  child: const Text('Patient HB-8429-XT', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('Today at 10:30 AM', style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            TextField(
              maxLines: null,
               decoration: InputDecoration(
                 hintText: 'Type your clinical notes here...\n\ne.g., "Patient reports mild headache. Advised to avoid sugar and continue medicine for 5 more days."',
                 hintStyle: TextStyle(color: Colors.grey[400], height: 1.5),
                 border: InputBorder.none,
               ),
               style: const TextStyle(
                 fontSize: 16,
                 color: Color(0xff1E293B),
                 height: 1.5,
               ),
            )
          ],
        ),
      )
    );
  }
}
