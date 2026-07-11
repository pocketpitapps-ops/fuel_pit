// lib\features\onboarding\presentation\widgets\vehicles_step.dart
import 'package:flutter/material.dart';

import '../../../vehicles/data/vehicles_repository.dart';
import '../../../vehicles/domain/vehicle.dart';
import '../../../vehicles/presentation/vehicles_page.dart';

class VehiclesStep extends StatelessWidget {
  final VehiclesRepository vehiclesRepo;
  final List<Vehicle> existingVehicles;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const VehiclesStep({
    super.key,
    required this.vehiclesRepo,
    required this.existingVehicles,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Configurar veículos',
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
            // Lista dos veículos já existentes (se houver)
            if (existingVehicles.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: existingVehicles.length,
                  itemBuilder: (_, index) {
                    final v = existingVehicles[index];
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(v.nickname ?? 'Veículo ${index + 1}'),
                      subtitle: Text('${v.brand} • ${v.plate}'),
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Ainda não tens veículos na garagem.\n'
                    'Adiciona e começa a dominar os abastecimentos!\n\n'
                    'também podes adicionar veículos mais tarde no Perfil.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 18, // aumenta letra
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Botão para abrir fluxo de veículos, sem obrigatoriedade
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const VehiclesPage()));
                // ao voltar, o OnboardingPage pode recarregar veículos
                // (por exemplo chamando _loadInitialData novamente)
              },
              icon: const Icon(Icons.directions_car),
              label: const Text('Adicionar veículos'),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onBack, child: const Text('Voltar')),
                const Spacer(),
                ElevatedButton(onPressed: onNext, child: const Text('Avançar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
