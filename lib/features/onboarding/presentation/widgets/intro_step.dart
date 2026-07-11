// lib\features\onboarding\presentation\widgets\intro_step.dart
import 'package:flutter/material.dart';

class IntroStep extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const IntroStep({super.key, required this.onSkip, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // centro vertical
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bem-vindo ao FuelPit',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vamos pôr o FuelPit a trabalhar por ti: adiciona veículos, fidelizações e ativa cupões para acompanhar abastecimentos.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Se preferires, podes saltar estes passos e tratar de tudo mais tarde no Perfil.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    child: const Text('Ignorar guia'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onNext,
                    child: const Text('Começar'),
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
