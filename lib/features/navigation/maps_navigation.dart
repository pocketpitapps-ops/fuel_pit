import 'package:url_launcher/url_launcher.dart';

class MapsNavigationService {
  static Future<bool> openStationOnMaps({
    String? stationName,
    String? brand,
    String? address,
    String? locality,
    String? municipality,
    String? district,
    double? latitude,
    double? longitude,
  }) async {
    // Se não tivermos coordenadas, usamos a pesquisa por texto (fallback)
    if (latitude == null || longitude == null) {
      final parts = <String>[];

      if (brand != null && brand.isNotEmpty) parts.add(brand);
      if (stationName != null && stationName.isNotEmpty) parts.add(stationName);
      if (address != null && address.isNotEmpty) parts.add(address);
      if (locality != null && locality.isNotEmpty) parts.add(locality);
      if (municipality != null && municipality.isNotEmpty) {
        parts.add(municipality);
      }
      if (district != null && district.isNotEmpty) parts.add(district);

      if (parts.isEmpty) return false;

      final searchText = parts.join(', ');
      final encodedDest = Uri.encodeComponent(searchText);
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedDest',
      );

      if (!await canLaunchUrl(uri)) return false;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }

    // Caso normal: temos coordenadas → usa sempre navegação por coordenadas
    final destination = '$latitude,$longitude';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    if (!await canLaunchUrl(uri)) return false;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }
}
