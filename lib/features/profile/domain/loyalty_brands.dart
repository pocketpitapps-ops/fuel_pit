// lib/features/profile/domain/loyalty_brands.dart

// Lista de marcas com sistema de fidelização suportado
const List<Map<String, String>> knownLoyaltyBrands = [
  {
    'key': 'galp',
    'name': 'Galp',
    'description':
        'Descontos com Mundo Galp, Continente, Universo e outras parcerias.',
  },
  {
    'key': 'repsol',
    'name': 'Repsol',
    'description':
        'Descontos com app Repsol, Santander, Lidl, FNAC, Benfica, etc.',
  },
  {
    'key': 'bp',
    'name': 'BP',
    'description':
        'Descontos com Poupa Mais, Pingo Doce, Via Verde, ACP e campanhas BP.',
  },
  {
    'key': 'prio',
    'name': 'PRIO',
    'description': 'Programa de pontos e campanhas de desconto PRIO.',
  },
  {
    'key': 'auchan',
    'name': 'Auchan',
    'description': 'Saldo e descontos em cartão Auchan nos abastecimentos.',
  },
  {
    'key': 'cepsa',
    'name': 'CEPSA',
    'description': 'Programa de pontos e descontos CEPSA.',
  },
  {
    'key': 'other',
    'name': 'Outros postos',
    'description':
        'Fidelizações de outras marcas ou parcerias específicas (cartões de bancos, clubes, etc.).',
  },
];
