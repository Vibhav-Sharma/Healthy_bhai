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
                  // Navigate to the Detail Screen
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
// DOCTOR DETAIL & BOOKING SCREEN (UPDATED WITH ONLINE/OFFLINE)
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
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  
  int _selectedRating = 5;
  bool _isOnline = false; // Tracks the Online/Offline toggle

  @override
  void dispose() {
    _reasonController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _bookAppointment() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason for your visit.')));
      return;
    }

    // 1. Pick a Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)), child: child!),
    );

    if (pickedDate == null) return; 

    // 2. Pick a Time
    if (!mounted) return;
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.red)), child: child!),
    );

    if (pickedTime == null) return; 

    // 3. Save to Firebase
    // 3. Save to Firebase
    try {
      DateTime appointmentDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, 
        pickedTime.hour, pickedTime.minute
      );

      String defaultMeetLink = 'https://meet.google.com/abc-defg-hij';

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['name'],
        'specialty': widget.doctorData['specialty'],
        'hospital': widget.doctorData['hospital'] ?? 'Not specified',
        'appointmentDate': appointmentDateTime,
        'reason': _reasonController.text.trim(),
        'status': 'Waiting',
        'type': _isOnline ? 'Online' : 'Offline', 
        'meetLink': _isOnline ? defaultMeetLink : null, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment request sent to ${widget.doctorData['name']}!'), backgroundColor: Colors.green),
      );
      
      // Stay on the same page: clear the form and reset UI instead of navigating away
      _reasonController.clear();
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book: $e'), backgroundColor: Colors.red));
    }
  }

  // --- REVIEW SYSTEM ---
  void _showWriteReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate this Doctor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                        onPressed: () => setDialogState(() => _selectedRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (_reviewController.text.trim().isEmpty) return;
                    
                    await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('reviews').add({
                      'patientId': widget.patientId,
                      'rating': _selectedRating,
                      'comment': _reviewController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    _reviewController.clear();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.doctorData['name'] ?? 'Unknown';
    String specialty = widget.doctorData['specialty'] ?? 'Specialty not listed';
    String hospital = widget.doctorData['hospital'] ?? 'Hospital not listed';
    
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle, border: Border.all(color: Colors.red.shade100, width: 2)),
                    child: const Icon(Icons.person, color: Colors.red, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                  Text(specialty, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
                  Text(hospital, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // --- APPOINTMENT TYPE TOGGLE ---
            const Text('Appointment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text('In-Clinic'),
                    ),
                    selected: !_isOnline,
                    onSelected: (val) => setState(() => _isOnline = false),
                    selectedColor: Colors.red.shade50,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: !_isOnline ? Colors.red.shade700 : Colors.grey.shade600, 
                      fontWeight: FontWeight.bold
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: !_isOnline ? Colors.red.shade200 : Colors.transparent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: const Text('Online (Video)'),
                    ),
                    selected: _isOnline,
                    onSelected: (val) => setState(() => _isOnline = true),
                    selectedColor: Colors.red.shade50,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: _isOnline ? Colors.red.shade700 : Colors.grey.shade600, 
                      fontWeight: FontWeight.bold
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _isOnline ? Colors.red.shade200 : Colors.transparent)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- REASON FOR APPOINTMENT ---
            const Text('Reason for Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Briefly describe your symptoms or reason for visit...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true, fillColor: const Color(0xffF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

            // --- REVIEWS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Patient Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff1E293B))),
                TextButton.icon(
                  onPressed: _showWriteReviewDialog, 
                  icon: const Icon(Icons.edit, size: 16, color: Colors.red), 
                  label: const Text('Write a Review', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            const SizedBox(height: 8),

            // StreamBuilder to fetch live reviews
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xffF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) => Icon(
                              starIndex < (review['rating'] ?? 5) ? Icons.star : Icons.star_border, 
                              color: Colors.amber, size: 16
                            )),
                          ),
                          const SizedBox(height: 8),
                          Text(review['comment'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xff1E293B))),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 100), // Spacing for bottom button
          ],
        ),
      ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _bookAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Request Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}