// lib/features/legal/privacy_policy_page.dart
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Política de Privacidade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Política de Privacidade — Fuel Pit',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última atualização: 15 de julho de 2026',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            textTheme,
            '1. Responsável pelo tratamento de dados',
            'Fuel Pit (com.fuelpit.app)\n'
                'Email de contacto: hello@pocketpitapps.com',
          ),
          _section(
            textTheme,
            '2. Dados que recolhemos',
            '• Email e nome de utilizador (registo)\n'
                '• Localização do dispositivo (para encontrar postos de combustível)\n'
                '• Dados de veículos que adicionas (marca, modelo, tipo de combustível)\n'
                '• Preferências de moeda e país',
          ),
          _section(
            textTheme,
            '3. Finalidade dos dados',
            '• Email e nome: autenticação e perfil do utilizador\n'
                '• Localização: mostrar postos de combustível próximos\n'
                '• Dados de veículos: calcular consumo e comparar preços\n'
                '• Preferências: personalizar a experiência na app',
          ),
          _section(
            textTheme,
            '4. Base legal (GDPR)',
            '• Consentimento do utilizador (registo na app)\n'
                '• Execução de contrato (fornecer o serviço solicitado)\n'
                '• Legítimo interesse (melhorar a app)',
          ),
          _section(
            textTheme,
            '5. Partilha de dados',
            'Não partilhamos os teus dados com terceiros para fins de marketing. '
                'Podemos partilhar dados anonimizados e agregados para fins estatísticos.',
          ),
          _section(
            textTheme,
            '6. Armazenamento e segurança',
            'Os dados são armazenados em servidores seguros (Supabase) com '
                'encriptação em trânsito (TLS) e em repouso. Utilizamos medidas '
                'técnicas e organizacionais adequadas para proteger os teus dados.',
          ),
          _section(
            textTheme,
            '7. Retenção de dados',
            '• Dados de conta: mantidos enquanto a conta estiver ativa\n'
                '• Dados de veículos: eliminados quando removes a conta\n'
                '• Localização: não é armazenada permanentemente',
          ),
          _section(
            textTheme,
            '8. Os teus direitos (GDPR)',
            'Tens direito a:\n'
                '• Aceder aos teus dados pessoais\n'
                '• Retificar dados incorretos\n'
                '• Apagar os teus dados ("direito ao esquecimento")\n'
                '• Portabilidade dos dados\n'
                '• Opor-se ao tratamento\n'
                '• Retirar o consentimento a qualquer momento',
          ),
          _section(
            textTheme,
            '9. Eliminar a tua conta',
            'Podes eliminar a tua conta a qualquer momento através de '
                'Perfil > Conta, privacidade e segurança > Eliminar conta. '
                'Esta ação é irreversível.',
          ),
          _section(
            textTheme,
            '10. Contacto',
            'Para questões sobre privacidade, contacta-nos em:\n'
                'hello@pocketpitapps.com',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(TextTheme textTheme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
