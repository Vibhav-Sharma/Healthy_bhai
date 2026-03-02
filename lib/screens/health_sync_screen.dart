import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/health_connect_service.dart';
import '../services/daily_summary.dart';
import '../services/firestore_service.dart';

/// HealthSyncScreen — Manual health data sync from Health Connect.
///
/// Shows a "Sync Health Data" button that:
/// 1. Checks Health Connect availability
/// 2. Requests permissions if needed
/// 3. Fetches today's health data (steps, HR, sleep, calories)
/// 4. Uploads the DailySummary to Firestore
/// 5. Displays the results with proper error/empty handling
class HealthSyncScreen extends StatefulWidget {
  final String patientId;
  const HealthSyncScreen({super.key, required this.patientId});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen>
    with SingleTickerProviderStateMixin {
  final HealthConnectService _healthService = HealthConnectService();

  bool _isLoading = false;
  bool _isSynced = false;
  String? _errorMessage;
  DailySummary? _summary;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkExistingData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingData() async {
    // Try to load today's data from Firestore if already synced
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final existing =
          await FirestoreService.getDailySummary(widget.patientId, today);
      if (existing != null && mounted) {
        setState(() {
          _summary = DailySummary.fromMap(existing);
          _isSynced = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _syncHealthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Check availability
      final availability = await _healthService.isAvailable();
      if (availability == 'NotInstalled') {
        setState(() {
          _errorMessage =
              'Health Connect is not installed.\n\nPlease install it from the Google Play Store to sync your smartwatch data.';
          _isLoading = false;
        });
        return;
      }
      if (availability == 'NotSupported') {
        setState(() {
          _errorMessage =
              'Health Connect is not supported on this device.\n\nThis feature requires Android 9+ with Health Connect installed.';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Check / request permissions
      bool hasPerms = await _healthService.hasPermissions();
      if (!hasPerms) {
        hasPerms = await _healthService.requestPermissions();
        if (!hasPerms) {
          setState(() {
            _errorMessage =
                'Health Connect permissions were denied.\n\nTo sync your health data, please grant all requested permissions. You can update permissions in your device Settings → Apps → Health Connect.';
            _isLoading = false;
          });
          return;
        }
      }

      // Step 3: Fetch daily summary
      final summary =
          await _healthService.fetchDailySummary(widget.patientId);

      // Step 4: Check for no data
      if (!summary.hasData) {
        setState(() {
          _summary = summary;
          _errorMessage =
              'No health data found for today.\n\nMake sure your boAt Storm smartwatch is syncing with Google Fit, and that Google Fit is connected to Health Connect.';
          _isLoading = false;
        });
        return;
      }

      // Step 5: Upload to Firestore
      await FirestoreService.uploadDailySummary(
        widget.patientId,
        summary.toMap(),
      );

      // Step 6: Add timeline event
      await FirestoreService.addTimelineEvent(
        patientId: widget.patientId,
        event:
            'Health data synced — ${summary.totalSteps} steps, ${summary.avgHeartRate} bpm avg',
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isSynced = true;
          _isLoading = false;
        });
      }
    } on HealthConnectException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch health data: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xff10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.monitor_heart,
                  color: Color(0xff10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Health Sync',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff10B981))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(isDark),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: 24),
            ],

            // Health data cards
            if (_summary != null) ...[
              Text('Today\'s Health Summary',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inverseSurface)),
              const SizedBox(height: 6),
              Text(
                _isSynced
                    ? 'Last synced: ${_formatSyncTime(_summary!.syncedAt)}'
                    : 'Not yet uploaded',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 24),
            ],

            // Sync button
            _buildSyncButton(),

            const SizedBox(height: 32),

            // Info section
            _buildInfoSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff10B981), Color(0xff059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xff10B981).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.watch, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smartwatch Sync',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        'Sync health data from your boAt Storm via Google Fit & Health Connect',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final summary = _summary!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.directions_walk,
          iconColor: const Color(0xff3B82F6),
          iconBg: const Color(0xffDBEAFE),
          label: 'Steps',
          value: NumberFormat('#,###').format(summary.totalSteps),
          unit: 'steps',
        ),
        _buildStatCard(
          icon: Icons.favorite,
          iconColor: const Color(0xffEF4444),
          iconBg: const Color(0xffFEE2E2),
          label: 'Heart Rate',
          value: summary.avgHeartRate.toStringAsFixed(1),
          unit: 'bpm avg',
        ),
        _buildStatCard(
          icon: Icons.bedtime,
          iconColor: const Color(0xff8B5CF6),
          iconBg: const Color(0xffEDE9FE),
          label: 'Sleep',
          value: summary.sleepHours.toStringAsFixed(1),
          unit: 'hours',
        ),
        _buildStatCard(
          icon: Icons.local_fire_department,
          iconColor: const Color(0xffF59E0B),
          iconBg: const Color(0xffFEF3C7),
          label: 'Calories',
          value: summary.calories.toStringAsFixed(0),
          unit: 'kcal',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.inverseSurface)),
          Text(unit,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _syncHealthData,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isSynced ? const Color(0xff10B981) : const Color(0xffDC2626),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: _isLoading ? 0 : 4,
          shadowColor: (_isSynced
                  ? const Color(0xff10B981)
                  : const Color(0xffDC2626))
              .withOpacity(0.4),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('Syncing...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isSynced ? Icons.check_circle : Icons.sync, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _isSynced ? 'Synced ✓  Tap to Refresh' : 'Sync Health Data',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[500], size: 18),
              const SizedBox(width: 8),
              Text('How it works',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoStep('1', 'Your boAt Storm syncs data to Google Fit'),
          _buildInfoStep('2', 'Google Fit shares data with Health Connect'),
          _buildInfoStep(
              '3', 'This screen reads from Health Connect and uploads to your profile'),
          _buildInfoStep(
              '4', 'Your doctor can view your daily health stats'),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xff10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff10B981))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat('MMM dd, yyyy – hh:mm a').format(dt.toLocal());
    } catch (_) {
      return isoTime;
    }
  }
}
