// lib\features\navigation\presentation\bottom_nav_scope.dart
import 'package:flutter/material.dart';
import 'bottom_nav_controller.dart';

class BottomNavScope extends InheritedNotifier<BottomNavController> {
  const BottomNavScope({
    super.key,
    required BottomNavController controller,
    required super.child,
  }) : super(notifier: controller);

  // Versão segura: pode devolver null
  static BottomNavController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BottomNavScope>();
    return scope?.notifier;
  }

  // Versão estrita: mantém se ainda quiseres usar noutros pontos
  static BottomNavController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BottomNavScope>();
    assert(scope != null, 'BottomNavScope not found in context');
    return scope!.notifier!;
  }
}
