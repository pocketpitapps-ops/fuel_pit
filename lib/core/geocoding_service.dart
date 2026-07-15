import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  /// Retorna uma label de localidade (ex: "Lisboa", "Porto"),
  /// ou, em último caso, concelho/distrito, ou null se não for possível.
  Future<String?> getCityLabelFromPosition(Position position) async {
    try {
      // Versão 4.x: sem localeIdentifier
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final pm = placemarks.first;

      final locality = pm.locality;
      final subLocality = pm.subLocality;
      final subAdmin = pm.subAdministrativeArea;
      final admin = pm.administrativeArea;

      if (locality != null && locality.isNotEmpty) return locality;
      if (subLocality != null && subLocality.isNotEmpty) return subLocality;
      if (subAdmin != null && subAdmin.isNotEmpty) return subAdmin;
      if (admin != null && admin.isNotEmpty) return admin;

      return null;
    } catch (_) {
      // Silently ignore: geocoding failure is non-critical
      return null;
    }
  }
}