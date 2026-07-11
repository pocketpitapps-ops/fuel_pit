// lib/features/onboarding/presentation/widgets/coupons_step.dart
import 'package:flutter/material.dart';

import '../../../coupons/data/coupons_repository.dart';
import '../../../coupons/domain/coupon.dart';
import '../../../coupons/presentation/widgets/new_coupon_sheet.dart';

class CouponsStep extends StatelessWidget {
  final CouponsRepository couponsRepo;
  final List<Coupon> sessionCoupons;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final Future<void> Function()? onCouponsChanged;

  const CouponsStep({
    super.key,
    required this.couponsRepo,
    required this.sessionCoupons,
    required this.onBack,
    required this.onFinish,
    this.onCouponsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Configurar cupões',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Lista de cupões já registados na sessão (se houver)
            if (sessionCoupons.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: sessionCoupons.length,
                  itemBuilder: (_, index) {
                    final c = sessionCoupons[index];

                    final isLoyalty =
                        c.codeOverride?.startsWith('LOYALTY_') == true;
                    final discountStr = _formatDiscount(c);
                    final typeStr = _formatBenefitKind(c);
                    final validityStr = _formatValidity(c);

                    return ListTile(
                      leading: Icon(
                        isLoyalty ? Icons.loyalty : Icons.local_offer,
                      ),
                      title: Text(c.displayName),
                      subtitle: Text(
                        '$discountStr • $typeStr • $validityStr',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        // fidelização não é editável aqui; volta ao passo de fidelizações
                        if (isLoyalty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cupões de fidelização editam-se no passo de Fidelizações.',
                              ),
                            ),
                          );
                          return;
                        }

                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) {
                            return NewCouponSheet(initialCoupon: c);
                          },
                        );

                        if (result == true && onCouponsChanged != null) {
                          await onCouponsChanged!();
                        }
                      },
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: isLoyalty ? Colors.grey : null,
                        ),
                        tooltip: isLoyalty
                            ? 'Cupão de fidelização elimina-se nas fidelizações'
                            : 'Apagar cupão',
                        onPressed: isLoyalty
                            ? null
                            : () => _confirmDeleteCoupon(
                                context,
                                c,
                                couponsRepo,
                                onCouponsChanged,
                              ),
                      ),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Ainda não tens cupões guardados.\n'
                    'Regista talões e códigos de desconto para não perder nenhum euro!\n\n'
                    'Também podes adicionar cupões mais tarde no separador Cupões.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Botão para abrir fluxo de criação de cupão, sem obrigatoriedade
            FilledButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    return const NewCouponSheet();
                  },
                );

                if (result == true && onCouponsChanged != null) {
                  await onCouponsChanged!();
                }
              },
              icon: const Icon(Icons.local_offer),
              label: const Text('Adicionar cupões'),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onBack, child: const Text('Voltar')),
                const Spacer(),
                ElevatedButton(
                  onPressed: onFinish,
                  child: const Text('Terminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helpers de formatação compacta

String _formatDiscount(Coupon c) {
  final v = c.discountValue;
  if (v == 0) return 'Sem desconto';

  switch (c.discountType) {
    case 'per_liter':
      return '${v.toStringAsFixed(2)} €/L';
    case 'percent':
      return '${v.toStringAsFixed(0)} %';
    default:
      return '${v.toStringAsFixed(2)} €';
  }
}

String _formatBenefitKind(Coupon c) {
  switch (c.benefitKind) {
    case CouponBenefitKind.cardBalance:
      return 'Saldo em cartão';
    case CouponBenefitKind.directDiscount:
      return 'Desconto direto';
  }
}

String _formatValidity(Coupon c) {
  final v = c.validUntil;
  if (v == null) return 'Sem validade';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(v.year, v.month, v.day);

  if (expiry.isBefore(today)) {
    return 'Expirado a ${_fmtDate(expiry)}';
  }
  return 'Até ${_fmtDate(expiry)}';
}

String _fmtDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month';
}

// Apagar com confirmação

Future<void> _confirmDeleteCoupon(
  BuildContext context,
  Coupon coupon,
  CouponsRepository couponsRepo,
  Future<void> Function()? onCouponsChanged,
) async {
  // guardar messenger antes do await para evitar use_build_context_synchronously
  final messenger = ScaffoldMessenger.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Apagar cupão'),
        content: Text(
          'Queres mesmo apagar o cupão "${coupon.displayName}"?\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      );
    },
  );

  if (result == true) {
    try {
      await couponsRepo.deleteCoupon(coupon.id);
      if (onCouponsChanged != null) {
        await onCouponsChanged();
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Cupão apagado com sucesso.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao apagar cupão: $e')),
      );
    }
  }
}
