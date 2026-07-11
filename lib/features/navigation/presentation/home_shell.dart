// lib/ui/home_shell.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bottom_nav_scope.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../stations/presentation/stations_page.dart';
import '../../fillups/presentation/history_tabs_page.dart';
import '../../coupons/presentation/coupons_page.dart';
import '../../profile/presentation/profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pages = const [
    DashboardPage(),
    StationsPage(),
    HistoryTabsPage(),
    CouponsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final navController = BottomNavScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final session = Supabase.instance.client.auth.currentSession;
    final isGuest = session == null;

    return AnimatedBuilder(
      animation: navController,
      builder: (context, _) {
        final currentIndex = navController.currentIndex;

        final safeIndex = isGuest && currentIndex == 4 ? 0 : currentIndex;

        return Scaffold(
          body: _pages[safeIndex],
          // Em guest, não mostramos a NavigationBar, mas o controller continua a existir.
          bottomNavigationBar: session == null
              ? null
              : NavigationBar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: navController.setIndex,
                  indicatorColor: colorScheme.secondaryContainer,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Início',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.local_gas_station_outlined),
                      selectedIcon: Icon(Icons.local_gas_station),
                      label: 'Postos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history),
                      selectedIcon: Icon(Icons.history),
                      label: 'Histórico',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.confirmation_number_outlined),
                      selectedIcon: Icon(Icons.confirmation_number),
                      label: 'Cupões',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Perfil',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
