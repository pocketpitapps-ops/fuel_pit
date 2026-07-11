import 'package:flutter/material.dart';
import '../../features/navigation/presentation/bottom_nav_scope.dart';
import '../../features/auth/auth_page.dart';

class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({
    super.key,
    this.title = 'Inicia sessão',
    this.message =
        'Esta funcionalidade precisa de uma conta para guardar os teus dados.',
    this.primaryActionLabel = 'Iniciar sessão',
    this.secondaryActionLabel = 'Criar conta',
    required this.onPrimaryAction,
    this.onSecondaryAction,
  });

  /// Versão padrão para toda a app:
  /// - Título fixo: "Inicia sessão"
  /// - Mensagem personalizada
  /// - Primário: Iniciar sessão → AuthPage
  /// - Secundário: Voltar ao início (Dashboard tab 0)
  factory LoginRequiredScreen.standard({
    Key? key,
    required BuildContext context,
    required String message,
  }) {
    final nav = BottomNavScope.maybeOf(context);

    return LoginRequiredScreen(
      key: key,
      title: 'Inicia sessão',
      message: message,
      primaryActionLabel: 'Iniciar sessão',
      secondaryActionLabel: 'Voltar ao início',
      onPrimaryAction: () {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
      },
      onSecondaryAction: () {
        if (nav != null) {
          nav.setIndex(0); // volta ao Dashboard
        } else {
          Navigator.of(context).pop(); // fallback se não houver HomeShell
        }
      },
    );
  }

  final String title;
  final String message;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPrimaryAction,
                      child: Text(primaryActionLabel),
                    ),
                  ),
                  if (onSecondaryAction != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryAction,
                        child: Text(secondaryActionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
