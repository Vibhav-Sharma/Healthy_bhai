import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ------------------------------------------------------------------------
// BOOK APPOINTMENT SCREEN 
// ------------------------------------------------------------------------

class BookAppointmentScreen extends StatefulWidget {
  final String patientId; // <-- This MUST be here
  
  const BookAppointmentScreen({Key? key, required this.patientId}) : super(key: key); // <-- And this!

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];

  // Alphabetized 50 Specialties List
  final List<Map<String, dynamic>> specialties = [
    {'name': 'Acupuncture', 'icon': Icons.auto_awesome},
    {'name': 'Allergy & Immunology', 'icon': Icons.masks},
    {'name': 'Alternative Medicine', 'icon': Icons.spa},
    {'name': 'Anesthesiology', 'icon': Icons.vaccines},
    {'name': 'Audiology', 'icon': Icons.volume_up},
    {'name': 'Bariatric Surgery', 'icon': Icons.monitor_weight},
    {'name': 'Cardiac Surgery', 'icon': Icons.monitor_heart},
    {'name': 'Cardiology', 'icon': Icons.favorite},
    {'name': 'Chiropractic', 'icon': Icons.airline_seat_recline_extra},
    {'name': 'Dental Care', 'icon': Icons.health_and_safety},
    {'name': 'Dermatology', 'icon': Icons.face},
    {'name': 'Emergency Medicine', 'icon': Icons.emergency},
    {'name': 'Endocrinology', 'icon': Icons.bloodtype},
    {'name': 'ENT (Ear, Nose, Throat)', 'icon': Icons.hearing},
    {'name': 'Family Medicine', 'icon': Icons.family_restroom},
    {'name': 'Gastroenterology', 'icon': Icons.medication_liquid},
    {'name': 'General Physician', 'icon': Icons.medical_information},
    {'name': 'General Surgery', 'icon': Icons.content_cut},
    {'name': 'Gynaecology', 'icon': Icons.pregnant_woman},
    {'name': 'Hematology', 'icon': Icons.invert_colors},
    {'name': 'Hepatology', 'icon': Icons.waves},
    {'name': 'Infectious Disease', 'icon': Icons.coronavirus},
    {'name': 'Intensive Care (ICU)', 'icon': Icons.local_hospital},
    {'name': 'Internal Medicine', 'icon': Icons.health_and_safety},
    {'name': 'Medical Genetics', 'icon': Icons.biotech},
    {'name': 'Neonatology', 'icon': Icons.baby_changing_station},
    {'name': 'Nephrology', 'icon': Icons.clean_hands},
    {'name': 'Neurology', 'icon': Icons.psychology},
    {'name': 'Nutrition & Dietetics', 'icon': Icons.apple},
    {'name': 'Obstetrics', 'icon': Icons.stroller},
    {'name': 'Occupational Therapy', 'icon': Icons.work},
    {'name': 'Oncology (Cancer)', 'icon': Icons.healing},
    {'name': 'Ophthalmology', 'icon': Icons.visibility},
    {'name': 'Optometry', 'icon': Icons.remove_red_eye},
    {'name': 'Orthopedics', 'icon': Icons.accessibility_new},
    {'name': 'Pain Management', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Pathology', 'icon': Icons.science},
    {'name': 'Pediatrics', 'icon': Icons.child_care},
    {'name': 'Physiotherapy', 'icon': Icons.directions_walk},
    {'name': 'Plastic Surgery', 'icon': Icons.face_retouching_natural},
    {'name': 'Podiatry', 'icon': Icons.do_not_step},
    {'name': 'Psychiatry', 'icon': Icons.self_improvement},
    {'name': 'Pulmonology', 'icon': Icons.air},
    {'name': 'Radiology', 'icon': Icons.scanner},
    {'name': 'Rheumatology', 'icon': Icons.accessible},
    {'name': 'Sleep Medicine', 'icon': Icons.bedtime},
    {'name': 'Speech Therapy', 'icon': Icons.record_voice_over},
    {'name': 'Sports Medicine', 'icon': Icons.directions_run},
    {'name': 'Urology', 'icon': Icons.water_drop},
    {'name': 'Vascular Surgery', 'icon': Icons.route},
  ];

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      if (!recentSearches.contains(query)) {
        recentSearches.insert(0, query);
      }
      if (recentSearches.length > 5) recentSearches.removeLast();
    });

    _searchController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorListScreen(
          searchQuery: query, 
          patientId: widget.patientId,
          isCategorySearch: false, // It's a free-text search
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book appointment',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onSubmitted: _handleSearch,
                decoration: InputDecoration(
                  hintText: 'Search doctors by name or specialty...',
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                ),
              ),
              const SizedBox(height: 24),

              if (recentSearches.isNotEmpty) ...[
                const Text('Recent searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: recentSearches.map((searchQuery) => _buildRecentChip(searchQuery)).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Consult doctors by specialty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: specialties.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  return _buildSpecialtyCard(context, specialties[index]['name'], specialties[index]['icon']);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _handleSearch(label),
        child: Chip(
          label: Text(label, style: const TextStyle(color: Colors.red)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red.shade200)),
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorListScreen(
              searchQuery: title, 
              patientId: widget.patientId,
              isCategorySearch: true, // It's an exact specialty match
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 80, width: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100, width: 1),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Icon(icon, size: 40, color: Colors.red)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// DOCTOR LIST & BOOKING SCREEN
// ------------------------------------------------------------------------

class DoctorListScreen extends StatefulWidget {
  final String searchQuery;
  final String patientId;
  final bool isCategorySearch;

  const DoctorListScreen({
    Key? key, 
    required this.searchQuery, 
    required this.patientId,
    required this.isCategorySearch,
  }) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  
  // This function handles the booking process (Date/Time picker -> Firebase)
  Future<void> _bookAppointment(BuildContext context, Map<String, dynamic> doctorData, String doctorId) async {
    // 1. Pick a Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return; // User canceled

    // 2. Pick a Time
    if (!mounted) return;
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return; // User canceled

    // 3. Save to Firebase
    try {
      // Combine date and time
      DateTime appointmentDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, 
        pickedTime.hour, pickedTime.minute
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'doctorId': doctorId,
        'doctorName': doctorData['name'],
        'specialty': doctorData['specialty'],
        'hospital': doctorData['hospital'] ?? 'Not specified',
        'appointmentDate': appointmentDateTime,
        'status': 'Upcoming', // Can be 'Upcoming', 'Completed', 'Cancelled'
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked with ${doctorData['name']}!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to dashboard after booking
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: Text(widget.isCategorySearch ? widget.searchQuery : 'Search Results', style: const TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch all doctors from Firebase
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors found in the database.'));
          }

          // Filter the doctors based on the search query or clicked category
          var allDoctors = snapshot.data!.docs;
          var filteredDoctors = allDoctors.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = (data['name'] ?? '').toString().toLowerCase();
            String specialty = (data['specialty'] ?? '').toString().toLowerCase();
            String query = widget.searchQuery.toLowerCase();

            if (widget.isCategorySearch) {
              return specialty == query; // Exact match for grid clicks
            } else {
              return name.contains(query) || specialty.contains(query); // Fuzzy match for search bar
            }
          }).toList();

          if (filteredDoctors.isEmpty) {
            return Center(child: Text('No doctors found for "${widget.searchQuery}".', style: const TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDoctors.length,
            itemBuilder: (context, index) {
              var doctorDoc = filteredDoctors[index];
              var doctorData = doctorDoc.data() as Map<String, dynamic>;
              
              String doctorName = doctorData['name'] ?? 'Unknown Doctor';
              String specialty = doctorData['specialty'] ?? 'Specialty not listed';
              String hospital = doctorData['hospital'] ?? 'Hospital not listed';
              String doctorId = doctorDoc.id; 

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.person, color: Colors.red, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B))),
                            const SizedBox(height: 4),
                            Text(specialty, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.local_hospital, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(hospital, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _bookAppointment(context, doctorData, doctorId),
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}