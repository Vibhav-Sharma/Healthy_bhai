import 'package:flutter/material.dart';
import 'doctor_notes_screen.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  const DoctorPatientDetailScreen({super.key});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HB-8429-XT',
          style: TextStyle(
            color: Color(0xff1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add, color: Colors.blue),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorNotesScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jane Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                      SizedBox(height: 4),
                      Text('34 yrs • Female • O+', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Emergency Alerts
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffFEF2F2),
              border: Border.all(color: const Color(0xffFECACA)),
              borderRadius: BorderRadius.circular(12),
            ),
             child: ListTile(
               leading: const Icon(Icons.warning_amber_rounded, color: Color(0xffDC2626)),
               title: const Text('SEVERE ALLERGIES', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
               subtitle: const Text('Peanuts, Penicillin, Latex', style: TextStyle(color: Color(0xff991B1B), fontWeight: FontWeight.w600)),
               minTileHeight: 60,
             ),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xffDC2626),
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: const Color(0xffDC2626),
              tabs: const [
                Tab(text: 'HISTORY'),
                Tab(text: 'MEDICINES'),
                Tab(text: 'REPORTS'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. History (Timeline)
                 ListView(
                   padding: const EdgeInsets.all(24),
                   children: [
                     _buildTimelineItem(year: '2025', title: 'Diabetes Diagnosis', desc: 'Type 2 Diabetes diagnosed. Metformin prescribed.', isFirst: true),
                     _buildTimelineItem(year: '2024', title: 'Allergy Detected', desc: 'Severe rash from peanuts. Epipen advised.'),
                     _buildTimelineItem(year: '2023', title: 'Appendectomy', desc: 'Surgical removal without complication.', isLast: true),
                   ],
                 ),
                 
                 // 2. Medicines
                 ListView(
                   padding: const EdgeInsets.all(24),
                   children: [
                     _buildMedicineCard('Metformin', '500mg • Daily • Active'),
                     _buildMedicineCard('Albuterol Inhaler', 'As Needed • Active'),
                     _buildMedicineCard('Amoxicillin', '500mg • 14 Days • Completed 2022', inactive: true),
                   ],
                 ),
                 
                 // 3. Reports
                 ListView(
                   padding: const EdgeInsets.all(24),
                   children: [
                     _buildReportCard('Blood Test (Dec 2024)'),
                     _buildReportCard('Chest X-Ray (Nov 2024)'),
                     _buildReportCard('Surgical Report (2023)'),
                   ],
                 ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem({required String year, required String title, required String desc, bool isFirst = false, bool isLast = false}) {
     return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(width: 2, height: 20, color: isFirst ? Colors.transparent : Colors.grey[300]),
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xffDC2626), shape: BoxShape.circle)),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[300]))
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(year, style: const TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedicineCard(String name, String details, {bool inactive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inactive ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, color: inactive ? Colors.grey : Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: inactive ? Colors.grey : const Color(0xff1E293B))),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportCard(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1E293B)))),
          Icon(Icons.download, color: Colors.grey[400])
        ],
      ),
    );
  }
}
