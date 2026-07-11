// lib\features\onboarding\presentation\onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/presentation/bottom_nav_controller.dart';
import '../../navigation/presentation/bottom_nav_scope.dart';
import '../../navigation/presentation/home_shell.dart';
import '../../../core/supabase_client.dart';
import '../../auth/auth_notifier.dart';
import '../../auth/auth_state.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../coupons/data/coupons_repository.dart';
import '../../coupons/domain/coupon.dart';
import '../../vehicles/domain/vehicle.dart';

import 'widgets/intro_step.dart';
import 'widgets/vehicles_step.dart';
import 'widgets/loyalty_step.dart';
import 'widgets/coupons_step.dart';

enum OnboardingStep { intro, vehicles, loyalty, coupons }

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  OnboardingStep _step = OnboardingStep.intro;

  final _profileRepo = UserProfileRepository();
  final _vehiclesRepo = VehiclesRepository();
  final _couponsRepo = CouponsRepository();

  UserProfile? _profile;
  List<Vehicle> _vehicles = [];
  final List<Coupon> _sessionCoupons = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final profile = await _profileRepo.fetchProfileByUserId(user.id);
    final vehicles = await _vehiclesRepo.getAllVehicles();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _vehicles = vehicles;
    });
  }

  void _goToStep(OnboardingStep step) {
    setState(() => _step = step);
  }

  Future<void> _completeOnboarding() async {
    final user = supabase.auth.currentUser;
    if (user == null || _profile == null) return;

    final updatedProfile = _profile!.copyWith(hasCompletedOnboarding: true);
    await _profileRepo.updateProfile(updatedProfile);

    if (!mounted) return;

    final controller = BottomNavController();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            BottomNavScope(controller: controller, child: const HomeShell()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    if (authState.status == AuthStatus.guest) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

      return Scaffold(
        body: Center(
          child: Text(
            'Inicia sessão para começar.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
        ),
      );
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (_step) {
      case OnboardingStep.intro:
        return IntroStep(
          onSkip: _completeOnboarding,
          onNext: () => _goToStep(OnboardingStep.vehicles),
        );
      case OnboardingStep.vehicles:
        return VehiclesStep(
          vehiclesRepo: _vehiclesRepo,
          existingVehicles: _vehicles,
          onBack: () => _goToStep(OnboardingStep.intro),
          onNext: () => _goToStep(OnboardingStep.loyalty),
        );
      case OnboardingStep.loyalty:
        return LoyaltyStep(
          profile: _profile!,
          profileRepo: _profileRepo,
          onBack: () => _goToStep(OnboardingStep.vehicles),
          onNext: () async {
            // 1) Carregar cupões atuais do utilizador a partir da BD
            final user = supabase.auth.currentUser;
            if (user == null) {
              // opcional: mostrar erro ou simplesmente avançar
              _goToStep(OnboardingStep.coupons);
              return;
            }

            final coupons = await _couponsRepo
                .getAllCouponsForCurrentUser(); // lê user_coupons

            if (!mounted) return;

            // 2) Atualizar sessão com os cupões e ir para o passo de cupões
            setState(() {
              _sessionCoupons
                ..clear()
                ..addAll(coupons);
              _step = OnboardingStep.coupons;
            });
          },
        );
      case OnboardingStep.coupons:
        return CouponsStep(
          couponsRepo: _couponsRepo,
          sessionCoupons: _sessionCoupons,
          onBack: () => _goToStep(OnboardingStep.loyalty),
          onFinish: _completeOnboarding,
          // novo callback
          onCouponsChanged: () async {
            final coupons = await _couponsRepo.getAllCouponsForCurrentUser();
            if (!mounted) return;
            setState(() {
              _sessionCoupons
                ..clear()
                ..addAll(coupons);
            });
          },
        );
    }
  }
}
