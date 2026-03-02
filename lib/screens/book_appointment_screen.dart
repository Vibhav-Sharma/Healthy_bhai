import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];

  final List<Map<String, dynamic>> specialties = [
    {'name': 'Adult Critical Care', 'icon': Icons.medical_services},
    {'name': 'Anesthesiology', 'icon': Icons.vaccines},
    {'name': 'Cancer Care', 'icon': Icons.healing},
    {'name': 'Cardiac Sciences', 'icon': Icons.favorite},
    {'name': 'Cardiac Surgery', 'icon': Icons.monitor_heart},
    {'name': 'Cardiology', 'icon': Icons.favorite_border},
    {'name': 'Clinical Hematology', 'icon': Icons.water_drop},
    {'name': 'Clinical Nutrition', 'icon': Icons.apple},
    {'name': 'Dental', 'icon': Icons.health_and_safety},
  ];

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      if (!recentSearches.contains(query)) {
        recentSearches.insert(0, query);
      }
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    });

    _searchController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorListScreen(queryCategory: query),
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
        leading: const Icon(Icons.arrow_back, color: Colors.red),
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
              TextField(
                controller: _searchController,
                onSubmitted: _handleSearch,
                decoration: InputDecoration(
                  hintText: 'Search doctors, specialties...',
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (recentSearches.isNotEmpty) ...[
                const Text(
                  'Recent searches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: recentSearches.map((searchQuery) => _buildRecentChip(searchQuery)).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Consult doctors by specialty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
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
                  return _buildSpecialtyCard(
                    context,
                    specialties[index]['name'],
                    specialties[index]['icon'],
                  );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.red.shade200),
          ),
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
            builder: (context) => DoctorListScreen(queryCategory: title),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(child: Icon(icon, size: 40, color: Colors.red)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DoctorListScreen extends StatelessWidget {
  final String queryCategory;

  const DoctorListScreen({Key? key, required this.queryCategory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$queryCategory Doctors', style: const TextStyle(color: Colors.red)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('specialty', isEqualTo: queryCategory)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No doctors found for $queryCategory.', style: const TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doctorData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String doctorName = doctorData['name'] ?? 'Unknown Doctor';
              String experience = doctorData['experience'] ?? 'Experience not listed';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade100),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: const Icon(Icons.person, color: Colors.red),
                  ),
                  title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(experience),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: const Text('Book'),
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