import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ------------------------------------------------------------------------
// BOOK APPOINTMENT SCREEN (SEARCH & CATEGORIES)
// ------------------------------------------------------------------------

class BookAppointmentScreen extends StatefulWidget {
  final String patientId; 
  
  const BookAppointmentScreen({Key? key, required this.patientId}) : super(key: key); 

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
          isCategorySearch: false, 
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
              isCategorySearch: true, 
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
// DOCTOR LIST SCREEN (SEARCH RESULTS)
// ------------------------------------------------------------------------

class DoctorListScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: Text(isCategorySearch ? searchQuery : 'Search Results', style: const TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          var allDoctors = snapshot.data!.docs;
          var filteredDoctors = allDoctors.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = (data['name'] ?? '').toString().toLowerCase();
            String specialty = (data['specialty'] ?? '').toString().toLowerCase();
            String query = searchQuery.toLowerCase();

            if (isCategorySearch) {
              return specialty == query; 
            } else {
              return name.contains(query) || specialty.contains(query); 
            }
          }).toList();

          if (filteredDoctors.isEmpty) {
            return Center(child: Text('No doctors found for "$searchQuery".', style: const TextStyle(fontSize: 16)));
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

              return GestureDetector(
                onTap: () {
                  // Navigate to the new Detail Screen instead of booking immediately
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailBookingScreen(
                        doctorData: doctorData,
                        doctorId: doctorId,
                        patientId: patientId,
                      ),
                    ),
                  );
                },
                child: Card(
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
                        // Changed Book button to View Profile arrow
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
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

// ------------------------------------------------------------------------
// NEW: DOCTOR DETAIL & BOOKING SCREEN
// ------------------------------------------------------------------------

class DoctorDetailBookingScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;
  final String patientId;

  const DoctorDetailBookingScreen({
    Key? key,
    required this.doctorData,
    required this.doctorId,
    required this.patientId,
  }) : super(key: key);

  @override
  State<DoctorDetailBookingScreen> createState() => _DoctorDetailBookingScreenState();
}

class _DoctorDetailBookingScreenState extends State<DoctorDetailBookingScreen> {

  Future<void> _bookAppointment() async {
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

    if (pickedDate == null) return; 

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

    if (pickedTime == null) return; 

    // 3. Save to Firebase
    try {
      DateTime appointmentDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, 
        pickedTime.hour, pickedTime.minute
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['name'],
        'specialty': widget.doctorData['specialty'],
        'hospital': widget.doctorData['hospital'] ?? 'Not specified',
        'appointmentDate': appointmentDateTime,
        'status': 'Upcoming', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked with ${widget.doctorData['name']}!'), backgroundColor: Colors.green),
      );
      
      // Pops all screens until the user is back at the Home Dashboard!
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.doctorData['name'] ?? 'Unknown';
    String specialty = widget.doctorData['specialty'] ?? 'Specialty not listed';
    String hospital = widget.doctorData['hospital'] ?? 'Hospital not listed';
    String email = widget.doctorData['email'] ?? 'Email not provided';
    String phone = widget.doctorData['phone'] ?? 'Phone not provided';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Doctor Profile', style: TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.red, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
            const SizedBox(height: 4),
            Text(specialty, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
            
            const SizedBox(height: 32),

            // Information Cards
            _buildInfoCard(Icons.local_hospital, 'Hospital / Clinic', hospital),
            const SizedBox(height: 16),
            _buildInfoCard(Icons.phone, 'Contact Number', phone),
            const SizedBox(height: 16),
            _buildInfoCard(Icons.email, 'Email Address', email),
            const SizedBox(height: 32),
            
            // About Section Placeholder
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
            ),
            const SizedBox(height: 8),
            Text(
              '$name is a dedicated professional specializing in $specialty. They are currently practicing at $hospital and are committed to providing the best care for their patients.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
      
      // Floating Booking Button stuck to bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _bookAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xff1E293B), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}