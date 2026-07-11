import 'package:geolocator/geolocator.dart';

enum LocationStatus { ok, serviceDisabled, denied, deniedForever }

class LocationResult {
  final LocationStatus status;
  final Position? position;

  LocationResult({required this.status, this.position});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(status: LocationStatus.serviceDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(status: LocationStatus.denied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(status: LocationStatus.deniedForever);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(status: LocationStatus.ok, position: position);
  }
}
