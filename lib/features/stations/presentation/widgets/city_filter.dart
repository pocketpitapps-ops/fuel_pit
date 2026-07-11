import 'package:flutter/material.dart';

class CityFilter extends StatelessWidget {
  const CityFilter({
    super.key,
    required this.districtsMap,
    required this.selectedMunicipality,
    required this.onMunicipalityChanged,
  });

  final Map<String, List<String>> districtsMap;
  final String? selectedMunicipality;
  final ValueChanged<String?> onMunicipalityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final districts = districtsMap.keys.toList()..sort();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Município',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String?>(
              initialValue: selectedMunicipality,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos'),
                ),
                ...districts.expand((district) {
                  final municipalities = [...(districtsMap[district] ?? [])]
                    ..sort();
                  return municipalities.map(
                    (m) => DropdownMenuItem<String?>(value: m, child: Text(m)),
                  );
                }),
              ],
              onChanged: onMunicipalityChanged,
            ),
          ],
        ),
      ),
    );
  }
}
