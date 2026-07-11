// lib\features\fillups\presentation\stats_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../../shared/widgets/login_required_screen.dart';
import '../data/fillups_repository.dart';
import '../domain/fill_up.dart';
import '../domain/fillup_stats.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _fillUpsRepo = FillUpsRepository();
  late Future<_StatsData> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = _loadStats();
  }

  Future<_StatsData> _loadStats() async {
    final fillups = await _fillUpsRepo.getAllFillUps();
    final couponIds = fillups
        .map((f) => f.userCouponId)
        .whereType<String>()
        .toSet();
    final couponsById = await _fillUpsRepo.getCouponsById(couponIds);
    final coupons = couponsById.values.toList();

    final stats = computeFillUpStats(fillups: fillups, coupons: coupons);

    return _StatsData(fillups: fillups, stats: stats);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureStats = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'As estatísticas são calculadas com base nos teus abastecimentos guardados na conta.',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas de abastecimentos'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_StatsData>(
          future: _futureStats,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Erro ao carregar estatísticas:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final fillups = data.fillups;
            final stats = data.stats;

            if (fillups.isEmpty) {
              return Center(
                child: Text(
                  'Ainda não tens abastecimentos registados.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumo geral', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${stats.totalPaid.toStringAsFixed(2)} € gastos em '
                          '${stats.totalLiters.toStringAsFixed(1)} L',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Poupança direta: '
                          '${stats.totalDirectDiscount.toStringAsFixed(2)} €',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                        ),
                        Text(
                          'Saldo acumulado em cartão: '
                          '${stats.totalCardBalance.toStringAsFixed(2)} €',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Poupança total: '
                          '${stats.totalSavings.toStringAsFixed(2)} €',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Aqui podes adicionar gráficos, breakdown por brand, por combustível, etc.
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsData {
  final List<FillUp> fillups;
  final FillUpStats stats;

  _StatsData({required this.fillups, required this.stats});
}
