// lib\features\coupons\presentation\coupons_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../fillups/presentation/fillups_for_coupon_page.dart';
import '../domain/coupon.dart';
import '../domain/coupon_ui_extensions.dart';
import '../data/coupons_repository.dart';
import '../../../core/supabase_client.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../../shared/widgets/login_required_screen.dart';
import 'widgets/new_coupon_sheet.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final _couponsRepository = CouponsRepository();
  late Future<List<Coupon>> _futureCoupons;

  @override
  void initState() {
    super.initState();

    final session = supabase.auth.currentSession;
    if (session != null) {
      _futureCoupons = _loadCoupons();
    } else {
      _futureCoupons = Future.value(const <Coupon>[]);
    }
  }

  Future<List<Coupon>> _loadCoupons() {
    return _couponsRepository.getAllCouponsForCurrentUser();
  }

  Future<void> _refresh() async {
    final future = _loadCoupons();
    setState(() {
      _futureCoupons = future;
    });
    await future;
  }

  Future<void> _openNewCouponSheet() async {
    final ctx = context;

    final result = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) {
        return const NewCouponSheet();
      },
    );

    if (!mounted) return;

    if (result == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      return LoginRequiredScreen.standard(
        context: context,
        message:
            'Os cupões são guardados na tua conta para poderes usá-los nos abastecimentos.',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cupões'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Coupon>>(
          future: _futureCoupons,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar cupões:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final originalData = snapshot.data ?? [];

            if (originalData.isEmpty) {
              return const Center(
                child: Text('Ainda não tens cupões guardados.'),
              );
            }

            final data = List<Coupon>.from(originalData);

            // Ordenar: ativos, usados, expirados; dentro de cada grupo por validade.
            data.sort((a, b) {
              int statusOrder(Coupon c) {
                switch (c.status) {
                  case CouponStatus.active:
                    return 0;
                  case CouponStatus.used:
                    return 1;
                  case CouponStatus.expired:
                    return 2;
                }
              }

              final ao = statusOrder(a);
              final bo = statusOrder(b);
              if (ao != bo) return ao.compareTo(bo);

              final aValid = a.validUntil;
              final bValid = b.validUntil;

              if (aValid != null && bValid != null) {
                return aValid.compareTo(bValid);
              } else if (aValid != null && bValid == null) {
                return -1;
              } else if (aValid == null && bValid != null) {
                return 1;
              }
              return 0;
            });

            final activeCount = data
                .where((c) => c.status == CouponStatus.active)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CouponsSummaryCard(activeCount: activeCount),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final coupon = data[index];
                      return _CouponListTile(
                        coupon: coupon,
                        onChanged: _refresh,
                        couponsRepository: _couponsRepository,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewCouponSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CouponsSummaryCard extends StatelessWidget {
  final int activeCount;

  const _CouponsSummaryCard({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$activeCount cupões ativos',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponListTile extends StatelessWidget {
  final Coupon coupon;
  final Future<void> Function() onChanged;
  final CouponsRepository couponsRepository;

  const _CouponListTile({
    required this.coupon,
    required this.onChanged,
    required this.couponsRepository,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final status = coupon.status;
    final name = coupon.displayName;
    final validLabel = coupon.validityLabel;
    final valueLabel = coupon.valueLabel;
    final statusLabel = coupon.statusLabel;
    final statusColor = coupon.statusColor(colorScheme);

    final isExpired = status == CouponStatus.expired;
    final isReallyActive = status == CouponStatus.active;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final ctx = context; // captura aqui

        if (!isReallyActive) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Só podes editar cupões ativos.')),
          );
          return;
        }

        final result = await showModalBottomSheet<bool>(
          context: ctx,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          builder: (sheetContext) {
            return NewCouponSheet(initialCoupon: coupon);
          },
        );

        if (!ctx.mounted) return; // mounted-check depois do await
        if (result == true) {
          await onChanged();
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(name, style: textTheme.titleMedium)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? colorScheme.errorContainer
                          : (isReallyActive
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isExpired ? 'Expirado' : valueLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: isExpired
                            ? colorScheme.onErrorContainer
                            : (isReallyActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Válido até: $validLabel',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (status != CouponStatus.expired)
                    Text(
                      statusLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: colorScheme.error,
                    tooltip: 'Apagar cupão',
                    onPressed: () async {
                      final ctx = context; // captura aqui também

                      if (status == CouponStatus.used) {
                        final goToFillUps = await showDialog<bool>(
                          context: ctx,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: const Text('Cupão já utilizado'),
                              content: Text(
                                'Este cupão foi utilizado em abastecimentos.\n'
                                'Para o apagar ou alterar, primeiro remove ou altera o cupão nesses abastecimentos.',
                                style: textTheme.bodyMedium,
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
                                  child: const Text('Ver abastecimentos'),
                                ),
                              ],
                            );
                          },
                        );

                        if (!ctx.mounted) return;
                        if (goToFillUps == true) {
                          final changed = await Navigator.of(ctx).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => FillUpsForCouponPage(
                                couponId: coupon.id,
                                coupon: coupon,
                              ),
                            ),
                          );

                          if (!ctx.mounted) return;
                          if (changed == true) {
                            await onChanged();
                          }
                        }

                        return;
                      }

                      final confirmed = await showDialog<bool>(
                        context: ctx,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('Apagar cupão?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tens a certeza que queres apagar este cupão?',
                                  style: textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nome: ${coupon.displayName}',
                                  style: textTheme.bodySmall,
                                ),
                                Text(
                                  'Valor: $valueLabel',
                                  style: textTheme.bodySmall,
                                ),
                                Text(
                                  'Estado: $statusLabel',
                                  style: textTheme.bodySmall,
                                ),
                                if (coupon.validUntil != null)
                                  Text(
                                    'Validade: $validLabel',
                                    style: textTheme.bodySmall,
                                  ),
                              ],
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
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                ),
                                child: const Text('Apagar'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed != true) return;

                      try {
                        await couponsRepository.deleteCoupon(coupon.id);

                        if (!ctx.mounted) return;

                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Cupão apagado.')),
                        );

                        await onChanged();
                      } catch (e) {
                        if (!ctx.mounted) return;

                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Erro ao apagar cupão: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
