import 'package:flutter/material.dart';

class AwaitingLocation extends StatelessWidget {
  const AwaitingLocation({
    super.key,
    required this.textTheme,
    required this.colorScheme,
    this.serviceEnabled = true,
    this.permissionDenied = false,
    this.permissionDeniedForever = false,
    this.onOpenAppSettings,
    this.onOpenLocationSettings,
    this.onRetry,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  final bool serviceEnabled;
  final bool permissionDenied;
  final bool permissionDeniedForever;

  final VoidCallback? onOpenAppSettings;
  final VoidCallback? onOpenLocationSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    String title = 'A obter localização...';
    String message =
        'Estamos a tentar obter a tua posição para mostrar postos perto de ti.';

    if (!serviceEnabled) {
      title = 'Localização desligada';
      message =
          'Ativa o GPS/localização no dispositivo para ver postos perto de ti.';
    } else if (permissionDeniedForever) {
      title = 'Permissão bloqueada';
      message =
          'A permissão de localização foi bloqueada. Vai às definições para a ativar.';
    } else if (permissionDenied) {
      title = 'Permissão necessária';
      message = 'Precisamos da tua permissão para mostrar postos perto de ti.';
    }

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                !serviceEnabled
                    ? Icons.location_off
                    : (permissionDeniedForever
                          ? Icons.lock
                          : Icons.my_location),
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(title, style: titleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: bodyStyle, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (!serviceEnabled && onOpenLocationSettings != null)
                FilledButton(
                  onPressed: onOpenLocationSettings,
                  child: const Text('Abrir definições de localização'),
                )
              else if (permissionDeniedForever && onOpenAppSettings != null)
                FilledButton(
                  onPressed: onOpenAppSettings,
                  child: const Text('Abrir definições da app'),
                )
              else if (permissionDenied && onRetry != null)
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
