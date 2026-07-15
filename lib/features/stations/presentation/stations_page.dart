// lib\features\stations\presentation\stations_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/station.dart';
import '../domain/municipality.dart';
import '../../coupons/domain/coupon.dart';
import '../../profile/domain/user_profile.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../coupons/data/coupons_repository.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../data/fuel_stations_repository.dart';
import '../data/locations_repository.dart';
import '../../../core/location_service.dart';
import '../../../core/location_session_state.dart';
import '../../../core/geocoding_service.dart';
import '../../../shared/models/fuel_type.dart';
import '../../navigation/presentation/bottom_nav_scope.dart';

import 'widgets/stations_header.dart';
import 'widgets/awaiting_location.dart';
import 'widgets/stations_list.dart';
import 'widgets/city_filter.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  final _couponsRepository = CouponsRepository();
  final _profileRepository = UserProfileRepository();
  final _vehiclesRepository = VehiclesRepository();
  final _stationsRepository = FuelStationsRepository();
  final _locationService = LocationService();
  final _geocodingService = GeocodingService();
  final _locationsRepository = LocationsRepository(Supabase.instance.client);

  late Future<UserProfile?> _futureProfile;
  late Future<List<Coupon>> _futureCoupons;
  Future<List<Station>>? _futureStations;

  Vehicle? _defaultVehicle;
  bool _loadingVehicle = false;

  String? _selectedMunicipality;
  bool _sortAscending = true;

  Map<String, List<String>> _districtsMap = {};

  LocationResult? _lastLocationResult;
  String? _currentCityLabel;
  bool _isLoadingStations = false;

  @override
  void initState() {
    super.initState();
    _futureProfile = _loadProfileSafe();
    _futureCoupons = _loadActiveCouponsSafe();
    _loadMunicipalities();
    _loadDefaultVehicleAndStations();
  }

  Future<UserProfile?> _loadProfileSafe() async {
    try {
      return await _profileRepository.getForCurrentUser();
    } catch (_) {
      // Silently ignore: profile load failure is non-critical for stations view
      return null;
    }
  }

  Future<List<Coupon>> _loadActiveCouponsSafe() async {
    try {
      return await _loadActiveCoupons();
    } catch (_) {
      // Silently ignore: coupon load failure is non-critical
      return const <Coupon>[];
    }
  }

  Future<List<Coupon>> _loadActiveCoupons() async {
    final all = await _couponsRepository.getAllCoupons();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return all.where((c) {
      if (!c.isActive) return false;
      final v = c.validUntil;
      if (v == null) return true;
      final expiry = DateTime(v.year, v.month, v.day);
      return !today.isAfter(expiry);
    }).toList();
  }

  Future<void> _loadMunicipalities() async {
    try {
      final list = await _locationsRepository.getAllMunicipalities();
      if (!mounted) return;
      setState(() {
        _districtsMap = _groupByDistrict(list);
      });
    } catch (_) {
      // Silently ignore: municipality load failure — filter stays empty
    }
  }

  Map<String, List<String>> _groupByDistrict(List<Municipality> list) {
    final map = <String, List<String>>{};
    for (final m in list) {
      map.putIfAbsent(m.district, () => []);
      map[m.district]!.add(m.municipality);
    }
    for (final entry in map.entries) {
      entry.value.sort();
    }
    return map;
  }

  List<Station> _addDistances(List<Station> stations, Position? position) {
    if (position == null) return stations;

    return stations.map((s) {
      if (s.latitude != null && s.longitude != null) {
        final d = distanceKm(
          position.latitude,
          position.longitude,
          s.latitude!,
          s.longitude!,
        );
        return s.copyWith(distanceKm: d);
      }
      return s;
    }).toList();
  }

  Future<List<Station>> _buildStationsFuture({
    required Position? position,
  }) async {
    final fuelTypeForSearch = _defaultVehicle?.fuelType ?? FuelType.gasolina95;

    if (_selectedMunicipality == null) {
      if (position != null) {
        final nearby = await _stationsRepository.getNearbyStations(
          userLat: position.latitude,
          userLng: position.longitude,
          fuelType: fuelTypeForSearch,
          radiusKm: 50,
        );
        return nearby;
      } else {
        final all = await _stationsRepository.getAllStations(
          fuelType: fuelTypeForSearch,
        );
        return _sortStations(all);
      }
    }

    final byCity = await _stationsRepository.getByMunicipality(
      municipality: _selectedMunicipality!,
      fuelType: fuelTypeForSearch,
    );

    final withDistances = _addDistances(byCity, position);
    return _sortStations(withDistances);
  }

  Future<void> _loadDefaultVehicleAndStations() async {
    setState(() {
      _loadingVehicle = true;
      _isLoadingStations = true;
      _futureStations = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final userId = session?.user.id;

      LocationSessionState.resetForUser(userId);

      final locationResult = await _locationService.getCurrentLocation();
      _lastLocationResult = locationResult;
      _currentCityLabel = null;

      final pos = locationResult.position;
      if (pos != null) {
        final city = await _geocodingService.getCityLabelFromPosition(pos);
        if (mounted) {
          setState(() {
            _currentCityLabel = city;
          });
        }
      }

      if (session != null) {
        _defaultVehicle = await _vehiclesRepository.getDefaultVehicle();
      } else {
        _defaultVehicle = null;
      }

      if (!mounted) return;

      if (locationResult.status == LocationStatus.ok) {
        _futureStations = _buildStationsFuture(
          position: locationResult.position,
        );
      } else {
        _futureStations = null;
      }

      setState(() {
        _loadingVehicle = false;
        _isLoadingStations = false;
      });
    } catch (e) {
      debugPrint('Failed to load default vehicle and stations: $e');
      if (!mounted) return;
      setState(() {
        _defaultVehicle = null;
        _loadingVehicle = false;
        _isLoadingStations = false;
        _futureStations = null;
      });
    }
  }

  String _buildFuelLabel(Vehicle? vehicle) {
    if (vehicle != null && vehicle.fuelType != null) {
      // 1. Se houver nickname, usa nickname
      // 2. Se não houver nickname, tenta brand + model
      // 3. Se também não houver brand/model, usa texto genérico
      final hasBrandOrModel =
          (vehicle.brand != null && vehicle.brand!.isNotEmpty) ||
          (vehicle.model != null && vehicle.model!.isNotEmpty);

      final vehicleName = vehicle.nickname?.isNotEmpty == true
          ? vehicle.nickname!
          : hasBrandOrModel
          ? '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim()
          : 'Veículo favorito';

      final fuel = vehicle.fuelType!.label; // ex: Gasolina 95
      return '$vehicleName • $fuel';
    }

    // Sem veículo ou sem fuelType
    return 'Veículo não definido • Gasolina 95';
  }

  List<Station> _sortStations(List<Station> stations) {
    stations.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      final cmpDist = da.compareTo(db);
      if (cmpDist != 0) {
        return _sortAscending ? cmpDist : -cmpDist;
      }

      final mA = a.municipality ?? '';
      final mB = b.municipality ?? '';
      final cmpMun = mA.compareTo(mB);
      if (cmpMun != 0) {
        return _sortAscending ? cmpMun : -cmpMun;
      }

      final cmpName = a.name.compareTo(b.name);
      return _sortAscending ? cmpName : -cmpName;
    });
    return stations;
  }

  @override
  Widget build(BuildContext context) {
    final nav = BottomNavScope.of(context);
    final session = Supabase.instance.client.auth.currentSession;

    final hasLocation = _lastLocationResult?.position != null;
    final locationStatus = _lastLocationResult?.status;

    String? locationLabel;
    if (hasLocation) {
      if (_currentCityLabel != null && _currentCityLabel!.isNotEmpty) {
        locationLabel = 'Postos perto de ti (${_currentCityLabel!})';
      } else {
        // fallback: mostrar pelo menos "(localização ativa)"
        locationLabel = 'Postos perto de ti (localização ativa)';
      }
    } else {
      locationLabel = 'Postos perto de ti';
    }

    final showLocationFallback =
        _futureStations == null &&
        (!_isLoadingStations ||
            locationStatus == LocationStatus.serviceDisabled ||
            locationStatus == LocationStatus.denied ||
            locationStatus == LocationStatus.deniedForever);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postos'),
        centerTitle: true,
        leading: session == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  nav.setIndex(0);
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<UserProfile?>(
          future: _futureProfile,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = profileSnapshot.data;

            if (_loadingVehicle && _defaultVehicle == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isGuest = profile == null;
            final fuelLabel = isGuest
                ? 'Sessão de convidado • Gasolina 95'
                : _buildFuelLabel(_defaultVehicle);

            return FutureBuilder<List<Coupon>>(
              future: _futureCoupons,
              builder: (context, couponsSnapshot) {
                final coupons = couponsSnapshot.data ?? const <Coupon>[];
                final textTheme = Theme.of(context).textTheme;
                final colorScheme = Theme.of(context).colorScheme;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StationsHeader(
                      fuelLabel: fuelLabel,
                      profile: profile,
                      couponsSnapshotError: couponsSnapshot.hasError,
                      hasCoupons: coupons.isNotEmpty,
                      isGuest: isGuest,
                      locationLabel: locationLabel,
                      onResetToNearby: () async {
                        setState(() {
                          _selectedMunicipality = null;
                          _loadingVehicle = true;
                        });
                        await _loadDefaultVehicleAndStations();
                      },
                      defaultVehicle: _defaultVehicle,
                    ),
                    const SizedBox(height: 8),
                    if (_districtsMap.isNotEmpty)
                      CityFilter(
                        districtsMap: _districtsMap,
                        selectedMunicipality: _selectedMunicipality,
                        onMunicipalityChanged: (municipality) async {
                          setState(() {
                            _selectedMunicipality = municipality;
                            _loadingVehicle = true;
                          });
                          await _loadDefaultVehicleAndStations();
                        },
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: showLocationFallback
                          ? AwaitingLocation(
                              textTheme: textTheme,
                              colorScheme: colorScheme,
                              serviceEnabled:
                                  locationStatus !=
                                  LocationStatus.serviceDisabled,
                              permissionDenied:
                                  locationStatus == LocationStatus.denied,
                              permissionDeniedForever:
                                  locationStatus ==
                                  LocationStatus.deniedForever,
                              onOpenLocationSettings: () async {
                                await Geolocator.openLocationSettings();
                              },
                              onOpenAppSettings: () async {
                                await Geolocator.openAppSettings();
                              },
                              onRetry: _loadDefaultVehicleAndStations,
                            )
                          : (_futureStations == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : FutureBuilder<List<Station>>(
                                    future: _futureStations,
                                    builder: (context, stationsSnapshot) {
                                      if (stationsSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      if (stationsSnapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Erro ao carregar postos:\n${stationsSnapshot.error}',
                                            textAlign: TextAlign.center,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                        );
                                      }

                                      var stations =
                                          stationsSnapshot.data ??
                                          const <Station>[];

                                      if (stations.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'Nenhum posto encontrado.',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.outline,
                                                ),
                                          ),
                                        );
                                      }

                                      stations = _sortStations(stations);

                                      return StationsList(
                                        stations: stations,
                                        sortAscending: _sortAscending,
                                        onToggleSort: () {
                                          setState(
                                            () => _sortAscending =
                                                !_sortAscending,
                                          );
                                        },
                                        coupons: coupons,
                                        profile: profile,
                                        isGuest: isGuest,
                                      );
                                    },
                                  )),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
