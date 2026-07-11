import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    final card = Card(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: child,
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: borderRadius, child: card);
    }

    return card;
  }
}
