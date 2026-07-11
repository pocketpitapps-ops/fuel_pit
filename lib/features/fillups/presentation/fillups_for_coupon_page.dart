// lib/features/fillups/presentation/fillups_for_coupon_page.dart
import 'package:flutter/material.dart';

import '../../../shared/models/fuel_type.dart';
import '../data/fillups_repository.dart';
import '../domain/fill_up.dart';
import '../../coupons/domain/coupon.dart';
import '../../coupons/domain/discount_engine.dart';
import 'new_fillup_page.dart';

class FillUpsForCouponPage extends StatefulWidget {
  final String couponId;
  final Coupon? coupon;

  const FillUpsForCouponPage({super.key, required this.couponId, this.coupon});

  @override
  State<FillUpsForCouponPage> createState() => _FillUpsForCouponPageState();
}

class _FillUpsForCouponPageState extends State<FillUpsForCouponPage> {
  final _repo = FillUpsRepository();
  late Future<List<FillUp>> _futureFillUps;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _futureFillUps = _repo.getFillUpsByCouponId(widget.couponId);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureFillUps = _repo.getFillUpsByCouponId(widget.couponId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Abastecimentos com este cupão'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_hasChanges);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<FillUp>>(
            future: _futureFillUps,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final textTheme = Theme.of(context).textTheme;
                final colorScheme = Theme.of(context).colorScheme;

                return Center(
                  child: Text(
                    'Erro ao carregar abastecimentos:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                );
              }

              final fillUps = snapshot.data ?? [];

              if (fillUps.isEmpty) {
                final textTheme = Theme.of(context).textTheme;
                final colorScheme = Theme.of(context).colorScheme;

                return Center(
                  child: Text(
                    'Nenhum abastecimento encontrado com este cupão.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: fillUps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final fill = fillUps[index];

                    final discountResult = coupon != null
                        ? calculateDiscounts(
                            liters: fill.liters,
                            pricePerLiter: fill.pricePerLiter,
                            coupons: [coupon],
                          )
                        : null;

                    final savings = discountResult?.savings ?? 0.0;

                    return ListTile(
                      title: Text(
                        '${fill.totalPaid.toStringAsFixed(2)} € · '
                        '${fill.liters.toStringAsFixed(1)} L',
                      ),
                      subtitle: Text(
                        '${fill.stationName ?? 'Posto desconhecido'} · '
                        '${fill.filledAt.day.toString().padLeft(2, '0')}/'
                        '${fill.filledAt.month.toString().padLeft(2, '0')}/'
                        '${fill.filledAt.year}'
                        '${savings > 0 ? ' · Poupaste ${savings.toStringAsFixed(2)} €' : ''}',
                      ),
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

                        if (updated == true && mounted) {
                          _hasChanges = true;
                          await _refresh();
                        }
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Apagar abastecimento?'),
                                content: const Text(
                                  'Ao apagar este abastecimento, o uso do cupão será revertido (se aplicável).',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text('Apagar'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            await _repo.deleteFillUp(fill.id);
                            if (mounted) {
                              await _refresh();
                              _hasChanges = true;
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
