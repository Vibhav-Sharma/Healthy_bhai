import 'package:flutter/material.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorPatientSearchScreen extends StatelessWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Search',
          style: TextStyle(
            color: Color(0xff1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search Bar Area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Access Patient Records',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the Patient ID or scan their QR code.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter Patient ID (e.g. HB-8429-XT)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xff1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientDetailScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDC2626), // Red
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SEARCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recently Accessed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildPatientCard(context, name: 'Jane Doe', id: 'HB-8429-XT', time: '2 hours ago', hasAlert: true),
                  _buildPatientCard(context, name: 'Michael Smith', id: 'HB-1102-AQ', time: 'Yesterday', hasAlert: false),
                  _buildPatientCard(context, name: 'Emily Chen', id: 'HB-9988-ZZ', time: 'Mar 1st, 2024', hasAlert: false),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildPatientCard(BuildContext context, {required String name, required String id, required String time, required bool hasAlert}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorPatientDetailScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B)),
                      ),
                      if (hasAlert) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                          child: const Text('ALLERGIES', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(id, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(' • $time', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
