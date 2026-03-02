import 'package:flutter/material.dart';

class MedicalTimelineScreen extends StatelessWidget {
  const MedicalTimelineScreen({super.key});

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
          'Medical History',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_edu, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Timeline',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chronological medical history records.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Timeline Content
            _buildTimelineItem(
              year: '2025',
              title: 'Diabetes Diagnosis',
              description: 'Diagnosed with Type 2 Diabetes during routine checkup. Prescribed Metformin 500mg. Recommended dietary lifestyle changes.',
              icon: Icons.monitor_weight_outlined,
              iconColor: Colors.orange,
              isFirst: true,
            ),
             _buildTimelineItem(
              year: '2024',
              title: 'Allergy Detected',
              description: 'Patient reported severe rash after consuming peanuts. Epipen prescribed.',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
            ),
            _buildTimelineItem(
              year: '2023',
              title: 'Appendectomy Surgery',
              description: 'Emergency appendectomy performed at City General Hospital. Successful recovery without complications.',
              icon: Icons.healing,
              iconColor: Colors.purple,
            ),
             _buildTimelineItem(
              year: '2022',
              title: 'Typhoid Fever',
              description: 'Treated for severe typhoid fever with a 14-day course of antibiotics.',
              icon: Icons.coronavirus_outlined,
              iconColor: Colors.teal,
              isLast: true,
            ),
            
            const SizedBox(height: 40),
            
            // Upload button
             SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: () {},
                 icon: const Icon(Icons.add, color: Color(0xffDC2626)),
                 label: const Text('Add Missing Record', style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold)),
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   side: const BorderSide(color: Color(0xffDC2626)),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String year,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line & dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : Colors.grey[300],
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 4),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: isLast ? 0 : 2, // remove width to hide line at the end
                    color: isLast ? Colors.transparent : Colors.grey[300],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            year,
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(icon, color: iconColor.withOpacity(0.8), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
