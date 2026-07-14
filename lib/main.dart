// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/intro/splash_intro_page.dart';

import 'features/auth/auth_callback_page.dart';
import 'features/auth/auth_notifier.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/auth_state.dart';
import 'features/navigation/presentation/bottom_nav_controller.dart';
import 'features/navigation/presentation/bottom_nav_scope.dart';
import 'features/navigation/presentation/home_shell.dart';
import 'features/profile/data/user_profile_repository.dart';
import 'features/profile/domain/user_profile.dart';
import 'features/onboarding/presentation/onboarding_page.dart';

import 'theme/fuel_pit_theme.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://enharpxjvmwssnvfodma.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVuaGFycHhqdm13c3NudmZvZG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NzUxNzIsImV4cCI6MjA5NTM1MTE3Mn0.yzJvj4CmF-eau8tlqk32dKGqR-IdBTuXqqJcVyIR6w0',
  );

  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('theme_mode');
  themeModeNotifier.value = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;

  runApp(const FuelPitApp());
}

class FuelPitApp extends StatelessWidget {
  const FuelPitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthNotifier(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'Fuel Pit',
            debugShowCheckedModeBanner: false,
            theme: fuelPitLightTheme,
            darkTheme: fuelPitDarkTheme,
            themeMode: mode,
            // usa a intro animada como primeira página Flutter
            home: const SplashIntroPage(),
            routes: {'/auth-callback': (_) => const AuthCallbackPage()},
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '/');

              if (uri.path == '/' && uri.queryParameters.containsKey('code')) {
                return MaterialPageRoute(
                  builder: (_) => const AuthCallbackPage(),
                  settings: settings,
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}

// Mantém o resto (AuthOrHomeRoot, HomeGate, etc.) igual ao que já tens:
class AuthOrHomeRoot extends StatefulWidget {
  const AuthOrHomeRoot({super.key});

  @override
  State<AuthOrHomeRoot> createState() => AuthOrHomeRootState();
}

class AuthOrHomeRootState extends State<AuthOrHomeRoot> {
  late final BottomNavController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _bottomNavController = BottomNavController();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;

    if (authState.status == AuthStatus.unknown || authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.status == AuthStatus.authenticated) {
      return BottomNavScope(
        controller: _bottomNavController,
        child: const HomeGate(),
      );
    }

    if (authState.status == AuthStatus.guest) {
      return BottomNavScope(
        controller: _bottomNavController,
        child: const HomeShell(),
      );
    }

    return const AuthPage();
  }
}

class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final user = authState.supabaseUser;

    if (user == null) {
      return const AuthPage();
    }

    return FutureBuilder<UserProfile?>(
      future: UserProfileRepository().fetchProfileByUserId(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data;

        if (profile == null) {
          return const OnboardingPage();
        }

        if (!profile.hasCompletedOnboarding) {
          return const OnboardingPage();
        }

        return const HomeShell();
      },
    );
  }
}
