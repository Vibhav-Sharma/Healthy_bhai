import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Check if location services are enabled & permissions granted.
  /// Returns the current [Position] or throws a descriptive error string.
  static Future<Position> getCurrentLocation() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.\nPlease enable GPS in your device settings.';
    }

    // 2. Check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.\nPlease allow location access.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied.\nPlease enable it from App Settings > Permissions.';
    }

    // 3. Get current position
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      // Fallback to last known
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      throw 'Could not get your location. Please check GPS and try again.';
    }
  }

  /// Open Google Maps navigation to the given coordinates.
  static Future<void> openInMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  /// Get a shareable Google Maps link for current location.
  static Future<String> getShareableLocationLink() async {
    final position = await getCurrentLocation();
    return 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
  }

  /// Format coordinates into a readable string.
  static String formatPosition(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
  }
}
