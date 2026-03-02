import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/encryption_service.dart';

// ------------------------------------------------------------------------
// BOOK APPOINTMENT SCREEN (SEARCH & CATEGORIES)
// ------------------------------------------------------------------------

class BookAppointmentScreen extends StatefulWidget {
  final String patientId; 
  
  BookAppointmentScreen({Key? key, required this.patientId}) : super(key: key); 

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book appointment',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onSubmitted: _handleSearch,
                decoration: InputDecoration(
                  hintText: 'Search doctors by name or specialty...',
                  prefixIcon: Icon(Icons.search, color: Colors.red),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red, width: 2)),
                ),
              ),
              SizedBox(height: 24),

              if (recentSearches.isNotEmpty) ...[
                Text('Recent searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: recentSearches.map((searchQuery) => _buildRecentChip(searchQuery)).toList(),
                  ),
                ),
                SizedBox(height: 24),
              ],

              Text('Consult doctors by specialty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 16),
              
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: specialties.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
      padding: EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _handleSearch(label),
        child: Chip(
          label: Text(label, style: TextStyle(color: Colors.red)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Center(child: Icon(icon, size: 40, color: Colors.red)),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
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

  DoctorListScreen({
    Key? key, 
    required this.searchQuery, 
    required this.patientId,
    required this.isCategorySearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isCategorySearch ? searchQuery : 'Search Results', style: TextStyle(color: Colors.red)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong!'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No doctors found in the database.'));
          }

          var allDoctors = snapshot.data!.docs;
          var filteredDoctors = allDoctors.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // Decrypt the name field (it's stored encrypted)
            String name = EncryptionService.decryptData((data['name'] ?? '').toString()).toLowerCase();
            String specialty = (data['specialty'] ?? '').toString().toLowerCase();
            String query = searchQuery.toLowerCase();

            if (isCategorySearch) {
              return specialty == query; 
            } else {
              return name.contains(query) || specialty.contains(query); 
            }
          }).toList();

          if (filteredDoctors.isEmpty) {
            return Center(child: Text('No doctors found for "$searchQuery".', style: TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredDoctors.length,
            itemBuilder: (context, index) {
              var doctorDoc = filteredDoctors[index];
              var doctorData = doctorDoc.data() as Map<String, dynamic>;
              
              // Decrypt the doctor name for display
              String doctorName = EncryptionService.decryptData(doctorData['name'] ?? 'Unknown Doctor');
              String specialty = doctorData['specialty'] ?? 'Specialty not listed';
              String hospital = doctorData['hospital'] ?? 'Hospital not listed';
              String doctorId = doctorDoc.id; 

              return GestureDetector(
                onTap: () {
                  // Create a decrypted copy of doctor data for the booking screen
                  var decryptedDoctorData = Map<String, dynamic>.from(doctorData);
                  decryptedDoctorData['name'] = doctorName; // Already decrypted above

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailBookingScreen(
                        doctorData: decryptedDoctorData,
                        doctorId: doctorId,
                        patientId: patientId,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.person, color: Colors.red, size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                              SizedBox(height: 4),
                              Text(specialty, style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.local_hospital, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(child: Text(hospital, style: TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
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

  DoctorDetailBookingScreen({
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a reason for your visit.')));
      return;
    }

    // 1. Pick a Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.red)), child: child!),
    );

    if (pickedDate == null) return; 

    // 2. Pick a Time
    if (!mounted) return;
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.red)), child: child!),
    );

    if (pickedTime == null) return; 

    // 3. Save to Firebase
    try {
      DateTime appointmentDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day, 
        pickedTime.hour, pickedTime.minute
      );

      // Use the custom doctorId (e.g. DR-5281-KM) that the doctor queries by
      String customDoctorId = widget.doctorData['doctorId']?.toString() ?? widget.doctorId;

      // Check for time conflict
      bool conflict = await FirestoreService.hasTimeConflict(
        doctorId: customDoctorId,
        proposedTime: appointmentDateTime,
      );
      if (conflict) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This doctor already has an appointment at that time. Please choose a different slot.'), backgroundColor: Colors.orange),
        );
        return;
      }

      String defaultMeetLink = 'https://meet.google.com/abc-defg-hij';

      // Fetch the patient's name for the appointment record
      String patientName = await FirestoreService.getPatientName(widget.patientId);

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': widget.patientId,
        'patientName': patientName,
        'doctorId': customDoctorId,
        'doctorUid': widget.doctorId,
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

      // Add to patient timeline
      await FirestoreService.addTimelineEvent(
        patientId: widget.patientId,
        event: 'Booked appointment with Dr. ${widget.doctorData['name']}',
      );

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
              title: Text('Rate this Doctor'),
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
                  SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
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
                  child: Text('Submit', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Doctor Profile', style: TextStyle(color: Colors.red)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
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
                    child: Icon(Icons.person, color: Colors.red, size: 50),
                  ),
                  SizedBox(height: 16),
                  Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  Text(specialty, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
                  Text(hospital, style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            
            SizedBox(height: 32),

            // --- APPOINTMENT TYPE TOGGLE ---
            Text('Appointment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text('In-Clinic'),
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
                SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text('Online (Video)'),
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

            SizedBox(height: 24),

            // --- REASON FOR APPOINTMENT ---
            Text('Reason for Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Briefly describe your symptoms or reason for visit...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true, fillColor: Color(0xffF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              ),
            ),

            Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),

            // --- REVIEWS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Patient Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                TextButton.icon(
                  onPressed: _showWriteReviewDialog, 
                  icon: Icon(Icons.edit, size: 16, color: Colors.red), 
                  label: Text('Write a Review', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            SizedBox(height: 8),

            // StreamBuilder to fetch live reviews
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var review = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor, )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) => Icon(
                              starIndex < (review['rating'] ?? 5) ? Icons.star : Icons.star_border, 
                              color: Colors.amber, size: 16
                            )),
                          ),
                          SizedBox(height: 8),
                          Text(review['comment'] ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 100), // Spacing for bottom button
          ],
        ),
      ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _bookAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Request Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}