import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/reminder_service.dart';
import '../services/med_abbreviation_service.dart';

class ActiveMedicinesScreen extends StatefulWidget {
  final String patientId;
  const ActiveMedicinesScreen({super.key, required this.patientId});

  @override
  State<ActiveMedicinesScreen> createState() => _ActiveMedicinesScreenState();
}

class _ActiveMedicinesScreenState extends State<ActiveMedicinesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _activeMeds = [];
  List<Map<String, dynamic>> _expiredMeds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedicines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    try {
      final allMeds = await FirestoreService.getMedicines(widget.patientId);
      if (mounted) {
        setState(() {
          _activeMeds = allMeds.where((m) => m['active'] == true).toList();
          _expiredMeds = allMeds.where((m) => m['active'] != true).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicines: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Medicines',
            style: TextStyle(color: Color(0xff1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff16A34A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xff16A34A),
          tabs: [
            Tab(text: 'ACTIVE (${_activeMeds.length})'),
            Tab(text: 'EXPIRED (${_expiredMeds.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff16A34A)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMedicineList(_activeMeds, isActive: true),
                _buildMedicineList(_expiredMeds, isActive: false),
              ],
            ),
    );
  }

  Widget _buildMedicineList(List<Map<String, dynamic>> meds, {required bool isActive}) {
    if (meds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.medication_outlined : Icons.history,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active medicines' : 'No expired medicines',
              style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Scan a prescription to add medicines.'
                  : 'Completed prescriptions will appear here.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedicines,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: meds.length,
        itemBuilder: (context, index) => _buildMedicineCard(meds[index], isActive: isActive),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med, {required bool isActive}) {
    final name = med['name'] ?? 'Unknown';
    final dosage = med['dosage'] ?? 'N/A';
    final frequency = (med['frequency'] as String?) ?? '';
    final timingContext = (med['timingContext'] as String?) ?? '';
    final duration = (med['duration'] as String?) ?? '';
    final timings = List<String>.from(med['timings'] ?? []);

    // Resolve schedule times
    List<ScheduleTime> schedule = MedAbbreviationService.resolve(frequency);
    if (schedule.isEmpty && timingContext.isNotEmpty) {
      schedule = MedAbbreviationService.resolve(timingContext);
    }
    if (schedule.isEmpty) {
      for (final t in timings) {
        schedule.addAll(MedAbbreviationService.resolve(t));
      }
    }

    final bool isAsNeeded = MedAbbreviationService.isAsNeeded(frequency);
    final String? freqDescription = MedAbbreviationService.describe(frequency);

    // Date info
    final startDate = (med['startDate'] as dynamic);
    final expiresAt = (med['expiresAt'] as dynamic);
    String startStr = '';
    String expiresStr = '';
    String daysLeft = '';

    if (startDate != null) {
      final dt = startDate.toDate();
      startStr = DateFormat('MMM d, y').format(dt);
    }
    if (expiresAt != null) {
      final dt = expiresAt.toDate();
      expiresStr = DateFormat('MMM d, y').format(dt);
      if (isActive) {
        final remaining = dt.difference(DateTime.now()).inDays;
        daysLeft = remaining > 0 ? '$remaining days left' : 'Expires today';
      }
    }

    final accentColor = isActive ? const Color(0xff16A34A) : Colors.grey;
    final bgColor = isActive ? Colors.green[50]! : Colors.grey[50]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.medication, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isActive ? const Color(0xff1E293B) : Colors.grey)),
                    const SizedBox(height: 2),
                    Text('Dosage: $dosage', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? '● Active' : '● Expired',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.green[700] : Colors.red[400]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Frequency, Timing Context, Duration badges
          if (frequency.isNotEmpty || timingContext.isNotEmpty || duration.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (frequency.isNotEmpty)
                  _infoBadge(Icons.repeat, frequency.toUpperCase(), Colors.blue),
                if (freqDescription != null)
                  _infoBadge(Icons.info_outline, freqDescription, Colors.indigo),
                if (timingContext.isNotEmpty)
                  _infoBadge(Icons.restaurant, timingContext.toUpperCase(), Colors.orange),
                if (duration.isNotEmpty)
                  _infoBadge(Icons.date_range, duration, Colors.purple),
              ],
            ),

          if (frequency.isNotEmpty || timingContext.isNotEmpty || duration.isNotEmpty)
            const SizedBox(height: 12),

          // Schedule times
          if (!isAsNeeded && schedule.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    schedule.map((s) => '${s.label} (${s.formatted})').join('  •  '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ] else if (isAsNeeded) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 15, color: Colors.orange[600]),
                const SizedBox(width: 6),
                Text('Take as needed', style: TextStyle(fontSize: 12, color: Colors.orange[600], fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Date range
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                startStr.isNotEmpty ? '$startStr → $expiresStr' : 'No date info',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Spacer(),
              if (daysLeft.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(daysLeft, style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
