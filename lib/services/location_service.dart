import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';

class RollLocation {
  final double latitude;
  final double longitude;
  final String? label;

  const RollLocation({required this.latitude, required this.longitude, this.label});
}

/// Wraps geolocator + geocoding so the rest of the app just gets a nullable
/// [RollLocation] back — every failure mode (denied permission, disabled
/// service, no network for reverse geocoding) degrades gracefully instead of
/// throwing.
class LocationService {
  final Geocoding _geocoding = Geocoding();

  Future<RollLocation?> currentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final label = await _reverseGeocode(position.latitude, position.longitude);
      return RollLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: label,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [p.locality, p.administrativeArea, p.country]
          .where((s) => s != null && s.trim().isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
