import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/places_service.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      final hospitals = await PlacesService.searchNearbyHospitals(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  Widget _buildStarRating(double rating) {
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(Icons.star, color: Colors.amber, size: 16),
        if (hasHalf)
          Icon(Icons.star_half, color: Colors.amber, size: 16),
        for (int i = 0; i < (5 - fullStars - (hasHalf ? 1 : 0)); i++)
          Icon(Icons.star_border, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 16),
        SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xff64748B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xffDC2626), Color(0xffB91C1C)],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🏥 Nearby Hospitals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _isLoading ? null : _fetchHospitals,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Body ───
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xffDC2626)),
                          SizedBox(height: 16),
                          Text(
                            'Finding nearby hospitals...',
                            style: TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Getting your location & searching',
                            style: TextStyle(
                              color: Color(0xff94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? _buildErrorView()
                      : _hospitals.isEmpty
                          ? _buildEmptyView()
                          : _buildHospitalList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xffFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xffFECACA)),
              ),
              child: Icon(Icons.location_off, color: Color(0xffDC2626), size: 48),
            ),
            SizedBox(height: 24),
            Text(
              'Unable to Find Hospitals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xff64748B),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHospitals,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffDC2626),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), size: 64),
            SizedBox(height: 16),
            Text(
              'No Hospitals Found Nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No hospitals or clinics found within 5 km of your location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchHospitals,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffDC2626),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalList() {
    return Column(
      children: [
        // Results count
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Theme.of(context).cardColor,
          child: Text(
            '${_hospitals.length} hospital${_hospitals.length != 1 ? 's' : ''} found within 5 km',
            style: TextStyle(
              color: Color(0xff64748B),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _hospitals.length,
            itemBuilder: (context, index) {
              final hospital = _hospitals[index];
              return _buildHospitalCard(hospital);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    final isOpen = hospital['open_now'] as bool;
    return GestureDetector(
      onTap: () async {
        try {
          await LocationService.openInMaps(
            hospital['lat'],
            hospital['lng'],
            hospital['name'],
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Color(0xffDC2626),
              ),
            );
          }
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color(0xffFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_hospital,
                color: Color(0xffDC2626),
                size: 28,
              ),
            ),
            SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital['name'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    hospital['address'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if ((hospital['rating'] as double) > 0)
                        _buildStarRating(hospital['rating']),
                      if ((hospital['rating'] as double) > 0)
                        SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Distance + Navigate
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDistance(hospital['distance']),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffDC2626),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xffDC2626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
