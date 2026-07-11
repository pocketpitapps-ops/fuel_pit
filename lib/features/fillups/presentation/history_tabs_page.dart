// lib/features/fillups/presentation/history_tabs_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/fuel_type.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../../shared/widgets/login_required_screen.dart';
import '../data/fillups_repository.dart';
import '../domain/fill_up.dart';
import '../domain/fillup_stats.dart';
import '../../coupons/domain/coupon.dart';
import '../../coupons/domain/discount_engine.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../vehicles/domain/vehicle.dart';
import 'new_fillup_page.dart';
import 'history_fillup_tile.dart';

class HistoryTabsPage extends StatefulWidget {
  const HistoryTabsPage({super.key});

  @override
  State<HistoryTabsPage> createState() => _HistoryTabsPageState();
}

enum HistoryFilter { currentMonth, last6Months, thisYear }

class _HistoryTabsPageState extends State<HistoryTabsPage> {
  final _fillUpsRepo = FillUpsRepository();
  final _vehiclesRepo = VehiclesRepository();

  bool _isLoading = true;
  String? _error;

  List<FillUp> _allFillups = const [];
  Map<String, Coupon> _couponsById = const {};

  List<Vehicle> _vehicles = const [];
  Vehicle? _selectedVehicle; // null => todos os veículos

  HistoryFilter _selectedFilter = HistoryFilter.currentMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fillups = await _fillUpsRepo.getAllFillUps();

      final couponIds = fillups
          .map((f) => f.userCouponId)
          .whereType<String>()
          .toSet();

      final couponsById = await _fillUpsRepo.getCouponsById(couponIds);

      final vehicles = await _vehiclesRepo.getAllVehicles();

      if (!mounted) return;

      setState(() {
        _allFillups = fillups;
        _couponsById = couponsById;
        _vehicles = vehicles;
        _selectedVehicle = null; // default: todos os veículos
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  List<FillUp> _applyFilter(List<FillUp> data) {
    final now = DateTime.now();

    // Filtrar por veículo (se houver)
    final byVehicle = _selectedVehicle == null
        ? data
        : data.where((f) => f.vehicleId == _selectedVehicle!.id).toList();

    switch (_selectedFilter) {
      case HistoryFilter.currentMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return byVehicle
            .where(
              (fill) =>
                  !fill.filledAt.isBefore(start) && fill.filledAt.isBefore(end),
            )
            .toList();

      case HistoryFilter.last6Months:
        final start = DateTime(now.year, now.month - 5, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return byVehicle
            .where(
              (fill) =>
                  !fill.filledAt.isBefore(start) && fill.filledAt.isBefore(end),
            )
            .toList();

      case HistoryFilter.thisYear:
        final startYear = DateTime(now.year, 1, 1);
        final endYear = DateTime(now.year + 1, 1, 1);
        return byVehicle
            .where(
              (fill) =>
                  !fill.filledAt.isBefore(startYear) &&
                  fill.filledAt.isBefore(endYear),
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'O histórico e estatísticas são calculados com base nos teus abastecimentos guardados na conta.',
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Histórico & estatísticas'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Erro ao carregar histórico:\n$_error',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    final filteredFillups = _applyFilter(_allFillups);

    if (filteredFillups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Histórico & estatísticas'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Ainda não tens abastecimentos registados.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ),
      );
    }

    final filteredStats = computeFillUpStats(
      fillups: filteredFillups,
      coupons: _couponsById.values.toList(),
    );

    final data = HistoryTabsData(
      fillups: filteredFillups,
      couponsById: _couponsById,
      stats: filteredStats,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico & estatísticas'),
          centerTitle: true,
          bottom: TabBar(
            labelColor: colorScheme.onSurface, // texto da tab selecionada
            unselectedLabelColor:
                colorScheme.onSurfaceVariant, // texto das tabs não selecionadas
            indicatorColor: colorScheme.primary, // linha/indicador da tab
            tabs: const [
              Tab(text: 'Resumo'),
              Tab(text: 'Registos'),
              Tab(text: 'Cupões'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              // Filtros (tempo + veículo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: HistoryFilterChips(
                  selected: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _VehicleFilterDropdown(
                  vehicles: _vehicles,
                  selected: _selectedVehicle,
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicle = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SummaryTab(data: data),
                    ListTab(data: data, onRefresh: _refresh),
                    CouponsTab(data: data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryTabsData {
  final List<FillUp> fillups;
  final Map<String, Coupon> couponsById;
  final FillUpStats stats;

  HistoryTabsData({
    required this.fillups,
    required this.couponsById,
    required this.stats,
  });
}

class HistoryFilterChips extends StatelessWidget {
  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onChanged;

  const HistoryFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Mês atual'),
            selected: selected == HistoryFilter.currentMonth,
            onSelected: (value) {
              if (!value) return;
              onChanged(HistoryFilter.currentMonth);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Últimos 6 meses'),
            selected: selected == HistoryFilter.last6Months,
            onSelected: (value) {
              if (!value) return;
              onChanged(HistoryFilter.last6Months);
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Este ano'),
            selected: selected == HistoryFilter.thisYear,
            onSelected: (value) {
              if (!value) return;
              onChanged(HistoryFilter.thisYear);
            },
          ),
        ],
      ),
    );
  }
}

class _VehicleFilterDropdown extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle? selected;
  final ValueChanged<Vehicle?> onChanged;

  const _VehicleFilterDropdown({
    required this.vehicles,
    required this.selected,
    required this.onChanged,
  });

  String _displayVehicleTitle(Vehicle v) {
    final nickname = v.nickname?.trim() ?? '';
    final brand = v.brand?.trim() ?? '';
    final model = v.model?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    final combined = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
    return combined.isNotEmpty ? combined : 'Veículo';
  }

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<Vehicle?>(
      initialValue: vehicles.contains(selected) ? selected : null,
      decoration: const InputDecoration(labelText: 'Filtrar por veículo'),
      items: [
        const DropdownMenuItem<Vehicle?>(
          value: null,
          child: Text('Todos os veículos'),
        ),
        ...vehicles.map((v) {
          return DropdownMenuItem<Vehicle?>(
            value: v,
            child: Text(_displayVehicleTitle(v)),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}

class SummaryTab extends StatelessWidget {
  final HistoryTabsData data;

  const SummaryTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumo do período', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${stats.totalPaid.toStringAsFixed(2)} € gastos em ${stats.totalLiters.toStringAsFixed(1)} L',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Poupança direta: ${stats.totalDirectDiscount.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  'Saldo acumulado em cartão: ${stats.totalCardBalance.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Poupança total: ${stats.totalSavings.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ListTab extends StatelessWidget {
  final HistoryTabsData data;
  final Future<void> Function() onRefresh;

  const ListTab({super.key, required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final fillups = data.fillups;
    final couponsById = data.couponsById;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fillups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final fill = fillups[index];
        final coupon = couponsById[fill.userCouponId];
        final hasCoupon = coupon != null;

        final discountResult = hasCoupon
            ? calculateDiscounts(
                liters: fill.liters,
                pricePerLiter: fill.pricePerLiter,
                coupons: [coupon],
              )
            : null;

        final savings = discountResult?.savings ?? 0.0;
        final cashback = discountResult?.cashbackOnCard ?? 0.0;

        return HistoryFillUpTile(
          fillUp: fill,
          coupon: coupon,
          savings: savings,
          cashback: cashback,
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => NewFillUpPage(
                  existingFillUp: fill,
                  initialStationName: fill.stationName,
                  initialFuelType: fill.fuelType.label,
                  initialCoupon: coupon,
                  station: null,
                ),
              ),
            );

            if (updated == true) {
              await onRefresh();
            }
          },
        );
      },
    );
  }
}

class CouponsTab extends StatelessWidget {
  final HistoryTabsData data;

  const CouponsTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fillups = data.fillups;
    final couponsById = data.couponsById;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final Map<String, _CouponStats> statsByCouponId = {};

    for (final f in fillups) {
      final couponId = f.userCouponId;
      if (couponId == null) continue;

      final coupon = couponsById[couponId];
      if (coupon == null) continue;

      final discountResult = calculateDiscounts(
        liters: f.liters,
        pricePerLiter: f.pricePerLiter,
        coupons: [coupon],
      );

      final entry = statsByCouponId.putIfAbsent(
        couponId,
        () => _CouponStats(coupon: coupon),
      );

      entry.count++;
      entry.totalSavings += discountResult.savings;
      entry.totalCardBalance += discountResult.cashbackOnCard;
    }

    if (statsByCouponId.isEmpty) {
      return Center(
        child: Text(
          'Ainda não utilizaste cupões em abastecimentos.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    final entries = statsByCouponId.values.toList()
      ..sort((a, b) => b.totalSavings.compareTo(a.totalSavings));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = entries[index];
        final total = s.totalSavings + s.totalCardBalance;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.coupon.customName ?? s.coupon.effectiveCode,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.count} abastecimentos com este cupão',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Desconto direto: ${s.totalSavings.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  'Saldo em cartão: ${s.totalCardBalance.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Poupança total: ${total.toStringAsFixed(2)} €',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CouponStats {
  final Coupon coupon;
  int count = 0;
  double totalSavings = 0.0;
  double totalCardBalance = 0.0;

  _CouponStats({required this.coupon});
}
