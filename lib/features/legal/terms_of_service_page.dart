// lib/features/legal/terms_of_service_page.dart
import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Utilização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Termos de Utilização — Fuel Pit',
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
            '1. Aceitação dos termos',
            'Ao descarregar, instalar ou utilizar a aplicação Fuel Pit, '
            'concordas com estes Termos de Utilização. Se não concordares, '
            'não deves utilizar a aplicação.',
          ),
          _section(
            textTheme,
            '2. Descrição do serviço',
            'A Fuel Pit é uma aplicação de comparação de preços de combustível '
            'que permite:\n'
            '• Encontrar postos de combustível próximos\n'
            '• Comparar preços em tempo real\n'
            '• Registar abastecimentos e acompanhar consumo\n'
            '• Aceder a notícias do setor energético',
          ),
          _section(
            textTheme,
            '3. Precisão dos dados',
            'Os preços e informações apresentados são baseados em dados '
            'fornecidos por terceiros e podem não estar completamente '
            'atualizados. A Fuel Pit não se responsabiliza por diferenças '
            'de preço entre os valores apresentados e os valores reais nos '
            'postos de combustível.',
          ),
          _section(
            textTheme,
            '4. Conta do utilizador',
            '• És responsável pela segurança da tua conta e password\n'
            '• Deves notificar-nos de qualquer uso não autorizado\n'
            '• Não partilhas a tua conta com terceiros',
          ),
          _section(
            textTheme,
            '5. Utilização aceitável',
            'Concordas em não:\n'
            '• Utilizar a app para fins ilegais\n'
            '• Tentar aceder indevidamente aos nossos sistemas\n'
            '• Manipular dados ou preços apresentados\n'
            '• Utilizar bots ou scripts para automatizar a recolha de dados',
          ),
          _section(
            textTheme,
            '6. Propriedade intelectual',
            'Todo o conteúdo da aplicação (design, código, logótipos, textos) '
            'é propriedade da Fuel Pit e está protegido por direitos de autor.',
          ),
          _section(
            textTheme,
            '7. Limitação de responsabilidade',
            'A Fuel Pit é fornecida "tal como está" sem garantias de '
            'disponibilidade, precisão ou idoneidade para um fim particular. '
            'Não somos responsáveis por danos diretos ou indiretos resultantes '
            'da utilização da aplicação.',
          ),
          _section(
            textTheme,
            '8. Alterações aos termos',
            'Reservamo-nos o direito de alterar estes termos a qualquer '
            'momento. As alterações serão comunicadas através da aplicação '
            'ou por email. A utilização continuada da app após as alterações '
            'constitui aceitação dos novos termos.',
          ),
          _section(
            textTheme,
            '9. Resolução de litígios',
            'Estes termos são regidos pela legislação portuguesa. '
            'Quaisquer litígios serão submetidos aos tribunais competentes '
            'de Portugal.',
          ),
          _section(
            textTheme,
            '10. Contacto',
            'Para questões sobre estes termos, contacta-nos em:\n'
            '[INSERIR EMAIL DE CONTACTO]',
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
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
