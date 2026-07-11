// lib/features/stations/presentation/widgets/stations_filters.dart
import 'package:flutter/material.dart';

class StationsFilters extends StatelessWidget {
  const StationsFilters({
    super.key,
    required this.sortAscending,
    required this.onToggleSort,
  });

  final bool sortAscending;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(sortAscending ? Icons.arrow_downward : Icons.arrow_upward),
          onPressed: onToggleSort,
        ),
      ],
    );
  }
}
