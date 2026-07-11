// lib\features\stations\domain\station_brand.dart
import 'package:flutter/material.dart';

/// Enum para representar marcas de postos de combustível de forma normalizada.
enum StationBrand {
  galp,
  bp,
  repsol,
  prio,
  cepsa,
  shell,
  oz,
  alvesBandeira,
  auchan,
  intermarche,
  pingoDoce,
  leclerc,
  recheio,
  petroprix,
  q8,
  generic,
  other,
}

/// Normaliza uma string de brand (por exemplo, vinda da BD ou da view station_brands_view)
/// para o enum StationBrand.
StationBrand normalizeBrand(String? rawBrand) {
  if (rawBrand == null) return StationBrand.other;

  final b = rawBrand.trim().toLowerCase();

  if (b == 'galp') return StationBrand.galp;
  if (b == 'bp') return StationBrand.bp;
  if (b == 'repsol') return StationBrand.repsol;
  if (b == 'prio') return StationBrand.prio;

  if (b == 'cepsa' || b == 'moeve') return StationBrand.cepsa;
  if (b == 'shell') return StationBrand.shell;
  if (b.contains('oz')) return StationBrand.oz; // "OZ Energia"

  if (b == 'alves bandeira') return StationBrand.alvesBandeira;
  if (b == 'auchan') return StationBrand.auchan;
  if (b == 'intermarché' || b == 'intermarche') return StationBrand.intermarche;

  if (b == 'pingo doce') return StationBrand.pingoDoce;
  if (b == 'leclerc') return StationBrand.leclerc;
  if (b == 'recheio') return StationBrand.recheio;

  if (b == 'petroprix') return StationBrand.petroprix;
  if (b == 'q8') return StationBrand.q8;

  if (b == 'genérico' || b == 'generico') return StationBrand.generic;

  // Todas as outras brands ficam em `other`.
  return StationBrand.other;
}

/// Label amigável para mostrar na UI.
String stationBrandLabel(StationBrand brand) {
  switch (brand) {
    case StationBrand.galp:
      return 'Galp';
    case StationBrand.bp:
      return 'BP';
    case StationBrand.repsol:
      return 'Repsol';
    case StationBrand.prio:
      return 'Prio';
    case StationBrand.cepsa:
      return 'Cepsa';
    case StationBrand.shell:
      return 'Shell';
    case StationBrand.oz:
      return 'OZ Energia';
    case StationBrand.alvesBandeira:
      return 'Alves Bandeira';
    case StationBrand.auchan:
      return 'Auchan';
    case StationBrand.intermarche:
      return 'Intermarché';
    case StationBrand.pingoDoce:
      return 'Pingo Doce';
    case StationBrand.leclerc:
      return 'Leclerc';
    case StationBrand.recheio:
      return 'Recheio';
    case StationBrand.petroprix:
      return 'Petroprix';
    case StationBrand.q8:
      return 'Q8';
    case StationBrand.generic:
      return 'Genérico';
    case StationBrand.other:
      return 'Outro posto';
  }
}

/// Ícone para representar a marca na UI.
/// Podes personalizar isto mais tarde com ícones específicos de marca.
IconData stationBrandIcon(StationBrand brand) {
  switch (brand) {
    case StationBrand.galp:
    case StationBrand.bp:
    case StationBrand.repsol:
    case StationBrand.prio:
    case StationBrand.cepsa:
    case StationBrand.shell:
    case StationBrand.oz:
    case StationBrand.alvesBandeira:
    case StationBrand.auchan:
    case StationBrand.intermarche:
    case StationBrand.pingoDoce:
    case StationBrand.leclerc:
    case StationBrand.recheio:
    case StationBrand.petroprix:
    case StationBrand.q8:
    case StationBrand.generic:
    case StationBrand.other:
      return Icons.local_gas_station;
  }
}

/// Cor associada à marca (tema de UI).
/// Podes ajustar as cores para ficar mais próximo da identidade visual de cada marca.
Color stationBrandColor(StationBrand brand, ColorScheme scheme) {
  switch (brand) {
    case StationBrand.galp:
      return scheme.primary;
    case StationBrand.bp:
      return scheme.secondary;
    case StationBrand.repsol:
      return scheme.tertiary;
    case StationBrand.prio:
      return scheme.secondary;
    case StationBrand.cepsa:
      return scheme.error;
    case StationBrand.shell:
      return scheme.primary;
    case StationBrand.oz:
      return scheme.secondary;
    case StationBrand.alvesBandeira:
      return scheme.primary;
    case StationBrand.auchan:
      return scheme.secondary;
    case StationBrand.intermarche:
      return scheme.secondary;
    case StationBrand.pingoDoce:
      return scheme.secondary;
    case StationBrand.leclerc:
      return scheme.primary;
    case StationBrand.recheio:
      return scheme.secondary;
    case StationBrand.petroprix:
      return scheme.primary;
    case StationBrand.q8:
      return scheme.secondary;
    case StationBrand.generic:
      return scheme.outline;
    case StationBrand.other:
      return scheme.outline;
  }
}
