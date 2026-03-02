import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacesService {
  /// Search for nearby hospitals using Google Places Nearby Search API.
  /// Returns a list of maps with keys: name, address, rating, lat, lng, distance.
  static Future<List<Map<String, dynamic>>> searchNearbyHospitals(
    double lat,
    double lng, {
    int radius = 5000,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=hospital'
      '&key=${dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw 'Failed to fetch nearby hospitals. Please check your internet connection.';
    }

    final data = json.decode(response.body);

    if (data['status'] == 'REQUEST_DENIED') {
      throw 'Google Places API request denied. Please check your API key.';
    }

    if (data['status'] == 'ZERO_RESULTS' ||
        data['results'] == null ||
        (data['results'] as List).isEmpty) {
      return [];
    }

    final results = data['results'] as List;

    return results.map<Map<String, dynamic>>((place) {
      final placeLat = place['geometry']['location']['lat'] as double;
      final placeLng = place['geometry']['location']['lng'] as double;
      final distanceKm = _calculateDistance(lat, lng, placeLat, placeLng);

      return {
        'name': place['name'] ?? 'Unknown Hospital',
        'address': place['vicinity'] ?? 'Address not available',
        'rating': place['rating']?.toDouble() ?? 0.0,
        'user_ratings_total': place['user_ratings_total'] ?? 0,
        'lat': placeLat,
        'lng': placeLng,
        'distance': distanceKm,
        'open_now': place['opening_hours']?['open_now'] ?? false,
      };
    }).toList()
      ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
  }

  /// Calculate distance between two geographic points using Haversine formula.
  /// Returns distance in kilometres.
  static double _calculateDistance(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
