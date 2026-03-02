import 'package:flutter/material.dart';

class PatientQRScreen extends StatelessWidget {
  const PatientQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1E293B), // Dark slate background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text(
              'Patient ID QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Show this to your doctor \nto grant instant access to your records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // The QR Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ]
              ),
              child: Column(
                children: [
                   // Placeholder for actual QR code image
                   Container(
                     width: 200,
                     height: 200,
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey[300]!, width: 2),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Icon(
                       Icons.qr_code_2,
                       size: 160,
                       color: Color(0xff1E293B),
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.grey[100],
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: const Text(
                       'ID: HB-8429-XT',
                       style: TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.w900,
                         letterSpacing: 2,
                         color: Color(0xffDC2626), // Red
                       ),
                     ),
                   )
                ],
              ),
            ),
            
            const SizedBox(height: 64),
            
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Share ID', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            )
          ],
        ),
      )
    );
  }
}
