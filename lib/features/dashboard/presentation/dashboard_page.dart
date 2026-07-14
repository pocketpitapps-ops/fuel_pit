// lib/features/dashboard/presentation/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../fillups/data/fillups_repository.dart';
import '../../navigation/presentation/bottom_nav_scope.dart';
import '../../../shared/models/news_item.dart';
import '../../../core/news_service.dart';
import '../../profile/domain/user_profile.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../coupons/domain/coupon.dart';
import '../../fillups/domain/fill_up.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../coupons/data/coupons_repository.dart';
import '../../vehicles/presentation/vehicles_page.dart';
import '../../dashboard/presentation/widgets/news_list_section.dart';
import '../../dashboard/presentation/widgets/dashboard_highlights_card.dart';
import '../../dashboard/presentation/widgets/dashboard_header_card.dart';
import '../../dashboard/presentation/widgets/no_default_vehicle_banner.dart';
import '../../navigation/presentation/bottom_nav_controller.dart';
import '../../fillups/domain/fillup_stats.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _profileRepository = UserProfileRepository();
  final _vehiclesRepository = VehiclesRepository();
  final _fillUpsRepository = FillUpsRepository();

  late Future<_DashboardData> _futureData;

  late final NewsService _newsService;
  List<NewsItem> _news = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _newsService = FuelNewsService();

    // Notícias são sempre carregadas, guest ou não.
    _loadNews();

    // Dados do utilizador só se houver sessão (para evitar exceções).
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _futureData = _loadData();
    } else {
      // Em guest o _buildFullDashboard nunca é chamado,
      // por isso podemos só criar um Future "dummy" qualquer.
      _futureData = Future<_DashboardData>.value(
        _DashboardData(
          profile: UserProfile(
            id: 'guest',
            userId: 'guest',
            currency: 'EUR',
            defaultFillMode: 'per_value',
            defaultFillValue: 40,
            notificationsEnabled: false,
          ),
          vehicle: null,
          vehicles: const [],
          nextExpiringCoupon: null,
          lastFillUpAll: null,
          lastFillUpFavorite: null,
          monthlySummaryAll: FillUpsSummary.empty(),
          monthlySummaryFavorite: FillUpsSummary.empty(),
          last30DaysTotal: 0,
          activeCouponsCount: 0,
          globalStats: null,
          favoriteStats: null,
        ),
      );
    }
  }

  Future<void> _loadNews() async {
    try {
      final all = await _newsService.fetchNews();
      if (!mounted) return;
      setState(() {
        _news = all;
        _isLoadingNews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _news = [];
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('URL inválida: $url')));
      return;
    }

    try {
      final can = await canLaunchUrl(uri);
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Não foi possível abrir: $url')));
        return;
      }

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao abrir no browser: $url')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível abrir: $url')));
    }
  }

  Future<_DashboardData> _loadData() async {
    // 1) obter user atual
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('Sem utilizador autenticado.');
    }

    // 2) obter perfil
    final profile = await _profileRepository.getForCurrentUser();

    // Veículo favorito / default e lista completa
    final vehicle = await _vehiclesRepository.getDefaultVehicle();
    final vehicles = await _vehiclesRepository.getAllVehicles();

    // Cupões
    final activeCoupons = await CouponsRepository()
        .getActiveNonExpiredForCurrentUser();
    final nextExpiringCoupon = activeCoupons.isNotEmpty
        ? activeCoupons.first
        : null;
    final activeCouponsCount = activeCoupons.length;

    // Abastecimentos (todos os veículos)
    final fillUps = await _fillUpsRepository.getAllFillUps();
    fillUps.sort((a, b) => b.filledAt.compareTo(a.filledAt));
    final lastFillUpAll = fillUps.isNotEmpty ? fillUps.first : null;

    // Abastecimentos do veículo favorito
    List<FillUp> favoriteFillUps = [];
    FillUp? lastFillUpFavorite;
    FillUpStats? favoriteStats;

    if (vehicle != null) {
      favoriteFillUps = await _fillUpsRepository.getFillUpsForVehicle(
        vehicle.id,
      );
      favoriteFillUps.sort((a, b) => b.filledAt.compareTo(a.filledAt));
      lastFillUpFavorite = favoriteFillUps.isNotEmpty
          ? favoriteFillUps.first
          : null;

      if (favoriteFillUps.isNotEmpty) {
        final favCouponIds = favoriteFillUps
            .map((f) => f.userCouponId)
            .whereType<String>()
            .toSet();
        final favCouponsById = await _fillUpsRepository.getCouponsById(
          favCouponIds,
        );
        final favCoupons = favCouponsById.values.toList();

        favoriteStats = computeFillUpStats(
          fillups: favoriteFillUps,
          coupons: favCoupons,
        );
      }
    }

    // Resumos mensais
    final now = DateTime.now();
    final monthlySummaryAll = await _fillUpsRepository.getMonthlySummary(now);

    FillUpsSummary monthlySummaryFavorite = FillUpsSummary.empty();
    if (vehicle != null) {
      monthlySummaryFavorite = await _fillUpsRepository
          .getMonthlySummaryForVehicle(now, vehicle.id);
    }

    // Total últimos 30 dias (todos os veículos)
    final last30DaysTotal = await _fillUpsRepository.getLast30DaysTotal();

    // Stats globais (todos os veículos)
    FillUpStats? globalStats;
    if (fillUps.isNotEmpty) {
      final couponIds = fillUps
          .map((f) => f.userCouponId)
          .whereType<String>()
          .toSet();
      final couponsById = await _fillUpsRepository.getCouponsById(couponIds);
      final coupons = couponsById.values.toList();

      globalStats = computeFillUpStats(fillups: fillUps, coupons: coupons);
    }

    return _DashboardData(
      profile: profile,
      vehicle: vehicle,
      vehicles: vehicles,
      nextExpiringCoupon: nextExpiringCoupon,
      lastFillUpAll: lastFillUpAll,
      lastFillUpFavorite: lastFillUpFavorite,
      monthlySummaryAll: monthlySummaryAll,
      monthlySummaryFavorite: monthlySummaryFavorite,
      last30DaysTotal: last30DaysTotal,
      activeCouponsCount: activeCouponsCount,
      globalStats: globalStats,
      favoriteStats: favoriteStats,
    );
  }

  Future<void> _refresh() async {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      if (session != null) {
        _futureData = _loadData();
      }
      _isLoadingNews = true;
    });
    await _loadNews();
  }

  String _displayVehicleName(Vehicle vehicle) {
    final nickname = vehicle.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;

    final brand = vehicle.brand?.trim() ?? '';
    final model = vehicle.model?.trim() ?? '';
    final combined = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
    return combined.isNotEmpty ? combined : 'Veículo principal';
  }

  @override
  Widget build(BuildContext context) {
    final nav = BottomNavScope.of(context);
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Pit'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: isGuest
            ? _buildGuestDashboard(context, nav)
            : _buildFullDashboard(context, nav),
      ),
    );
  }

  Widget _buildFullDashboard(BuildContext context, BottomNavController nav) {
    return FutureBuilder<_DashboardData>(
      future: _futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Erro ao carregar dados:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final profile = data.profile;
        final vehicle = data.vehicle;
        final vehicles = data.vehicles;
        final hasMultipleVehicles = vehicles.length > 1;
        final nextCoupon = data.nextExpiringCoupon;
        final lastFillUpAll = data.lastFillUpAll;
        final lastFillUpFavorite = data.lastFillUpFavorite;
        final summaryAll = data.monthlySummaryAll;
        final summaryFavorite = data.monthlySummaryFavorite;
        final activeCouponsCount = data.activeCouponsCount;
        final globalStats = data.globalStats;
        final favoriteStats = data.favoriteStats;

        final userName = () {
          final u = profile.username?.trim();
          if (u != null && u.isNotEmpty) return u;

          final f = profile.fullName?.trim();
          if (f != null && f.isNotEmpty) return f;

          return 'Motorista Fuel Pit';
        }();
        final hasDefaultVehicle = vehicle != null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!hasDefaultVehicle) ...[
              NoDefaultVehicleBanner(
                onTap: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const VehiclesPage()),
                  );
                  if (!mounted) return;
                  await _refresh();
                },
              ),
              const SizedBox(height: 16),
            ],
            DashboardHeaderCard(
              userName: userName,
              vehicle: vehicle,
              vehicleName: vehicle != null
                  ? _displayVehicleName(vehicle)
                  : null,
            ),
            const SizedBox(height: 16),
            _buildShortcutsRow(nav, context),
            const SizedBox(height: 16),
            DashboardHighlightsCard(
              hasMultipleVehicles: hasMultipleVehicles,
              summaryAll: summaryAll,
              summaryFavorite: summaryFavorite,
              lastFillUpAll: lastFillUpAll,
              lastFillUpFavorite: lastFillUpFavorite,
              favoriteVehicleName: vehicle != null
                  ? _displayVehicleName(vehicle)
                  : null,
              nextCoupon: nextCoupon,
              activeCouponsCount: activeCouponsCount,
              onAddCoupon: () => nav.setIndex(3),
              globalStats: globalStats,
              favoriteStats: favoriteStats,
            ),
            const SizedBox(height: 24),
            NewsListSection(
              items: _news,
              isLoading: _isLoadingNews,
              onOpenUrl: _openUrl,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestDashboard(BuildContext context, BottomNavController nav) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo ao Fuel Pit', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Estás a usar a app sem conta.\n\n'
                  'Podes ver postos e preços. '
                  'Para guardar veículos, cupões e histórico de abastecimentos, cria uma conta ou inicia sessão.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    context.read<AuthNotifier>().logout();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Criar conta / Iniciar sessão'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildShortcutsRow(nav, context),
        const SizedBox(height: 16),
        NewsListSection(
          items: _news,
          isLoading: _isLoadingNews,
          onOpenUrl: _openUrl,
        ),
      ],
    );
  }

  Widget _buildShortcutsRow(BottomNavController nav, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            icon: Icons.local_gas_station,
            label: 'Postos perto de mim',
            color: colorScheme.primary,
            onTap: () => nav.setIndex(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShortcutCard(
            icon: Icons.confirmation_number,
            label: 'Os meus cupões',
            color: colorScheme.secondary,
            onTap: () => nav.setIndex(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShortcutCard(
            icon: Icons.insights,
            label: 'Histórico & estatísticas',
            color: colorScheme.tertiary,
            onTap: () => nav.setIndex(2),
          ),
        ),
      ],
    );
  }
}

class _DashboardData {
  final UserProfile profile;
  final Vehicle? vehicle; // favorito / default
  final List<Vehicle> vehicles;
  final Coupon? nextExpiringCoupon;
  final FillUp? lastFillUpAll;
  final FillUp? lastFillUpFavorite;
  final FillUpsSummary monthlySummaryAll;
  final FillUpsSummary monthlySummaryFavorite;
  final double last30DaysTotal;
  final int activeCouponsCount;
  final FillUpStats? globalStats;
  final FillUpStats? favoriteStats;

  _DashboardData({
    required this.profile,
    required this.vehicle,
    required this.vehicles,
    required this.nextExpiringCoupon,
    required this.lastFillUpAll,
    required this.lastFillUpFavorite,
    required this.monthlySummaryAll,
    required this.monthlySummaryFavorite,
    required this.last30DaysTotal,
    required this.activeCouponsCount,
    this.globalStats,
    this.favoriteStats,
  });
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
