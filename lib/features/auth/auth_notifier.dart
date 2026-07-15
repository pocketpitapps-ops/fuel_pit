// lib/features/auth/auth_notifier.dart
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:flutter/material.dart' show BuildContext, Navigator;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show OAuthProvider, User, GoTrueClientSignInProvider;

import '../../core/supabase_client.dart';
import 'auth_state.dart';
import '../profile/data/user_profile_repository.dart';

class AuthNotifier extends ChangeNotifier {
  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  AuthNotifier() {
    _init();
  }

  Future<void> _init() async {
    final session = supabase.auth.currentSession;

    if (session?.user != null) {
      _state = AuthState(
        status: AuthStatus.authenticated,
        supabaseUser: session!.user,
      );
      // Ao arrancar a app com sessão válida, garante perfil
      await _ensureUserProfile(session.user);
    } else {
      _state = const AuthState(status: AuthStatus.unauthenticated);
    }
    notifyListeners();

    supabase.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      final user = session?.user;

      if (user != null) {
        _state = AuthState(
          status: AuthStatus.authenticated,
          supabaseUser: user,
        );
        // Sempre que o utilizador entra (email/pwd ou social),
        // garante que o perfil existe/é atualizado
        await _ensureUserProfile(user);
      } else {
        _state = const AuthState(status: AuthStatus.unauthenticated);
      }

      notifyListeners();
    });
  }

  Future<void> _ensureUserProfile(User user) async {
    try {
      final repo = UserProfileRepository();

      // 1) Garantir que o perfil existe (pela trigger)
      final existing = await repo.fetchProfileByUserId(user.id);
      if (existing == null) {
        return;
      }

      // 2) Opcional: sync leve com metadata (ex.: full_name vindo do Google)
      final metadata = user.userMetadata ?? {};
      final fullNameMeta = (metadata['full_name'] as String?)?.trim();
      final nameMeta = (metadata['name'] as String?)?.trim();
      final fullNameFromGoogle =
          (fullNameMeta != null && fullNameMeta.isNotEmpty)
          ? fullNameMeta
          : (nameMeta != null && nameMeta.isNotEmpty ? nameMeta : null);
      final shouldUpdateFullName =
          existing.fullName == null && fullNameFromGoogle != null;

      if (shouldUpdateFullName) {
        await repo.updatePartial(userId: user.id, fullName: fullNameFromGoogle);
      }

      // Não tocar em country/currency/notifications aqui, a não ser que queiras mesmo.
    } catch (_) {
      // Falha ao garantir perfil — tratado na UI
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null || res.user == null) {
        throw Exception('Não foi possível iniciar sessão.');
      }

      // sessão válida → garante perfil
      await _ensureUserProfile(res.user!);
    } catch (e) {
      final message = e.toString();
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      throw Exception(_mapAuthErrorMessage(message));
    }

    _state = _state.copyWith(isLoading: false);
    notifyListeners();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? fullName,
    String? country,
    String currency = 'EUR',
    String? mobileNumber,
    bool notificationsEnabled = true,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Garante que não há espaços e que os campos obrigatórios vêm limpos
      final trimmedEmail = email.trim();
      final trimmedUsername = username.trim();
      final trimmedFullName = fullName?.trim();
      final trimmedCountry = country?.trim();
      final trimmedMobile = mobileNumber?.trim();

      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/auth-callback'
          : 'fuelpit://auth-callback';

      final metadata = <String, dynamic>{
        'username': trimmedUsername,
        if (trimmedFullName != null && trimmedFullName.isNotEmpty)
          'full_name': trimmedFullName,
        if (trimmedCountry != null && trimmedCountry.isNotEmpty)
          'country': trimmedCountry,
        'currency': currency,
        if (trimmedMobile != null && trimmedMobile.isNotEmpty)
          'mobile_number': trimmedMobile,
        'notifications_enabled': notificationsEnabled,
      };

      final res = await supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        emailRedirectTo: redirectUrl,
        data: metadata,
      ); // [web:178][web:153]

      if (res.user == null) {
        throw Exception('Não foi possível criar a conta.');
      }

      _state = _state.copyWith(isLoading: false);
      notifyListeners();

      // Aqui podes navegar para um ecrã tipo "verifica o teu email"
    } catch (e) {
      final message = e.toString();
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      throw Exception(_mapAuthErrorMessage(message));
    }
  }

  Future<void> signInWithGoogle() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      if (kIsWeb) {
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        const iosClientId =
            '386848816031-m3g6e1t5li9a6fi48kftki48ml1lfjk2.apps.googleusercontent.com';
        const webClientId =
            '386848816031-ejn7o26g26fs80qs58mpnei0fv7134sc.apps.googleusercontent.com';

        await GoogleSignIn.instance.initialize(
          clientId: iosClientId,
          serverClientId: webClientId,
        );

        final googleSignIn = GoogleSignIn.instance;

        final googleUser = await googleSignIn.authenticate();

        // Pedir scopes (email, profile) para garantir accessToken adequado
        final clientAuth = await googleUser.authorizationClient.authorizeScopes(
          ['email', 'profile'],
        );

        // authentication é Future → precisa de await
        final googleAuth = googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = clientAuth.accessToken;

        if (idToken == null) {
          throw Exception('Não foi possível obter o token do Google.');
        }

        final res = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        final user = res.user;
        if (user == null) {
          throw Exception('Falha ao autenticar com Google.');
        }

        await _ensureUserProfile(user);
      }
    } catch (e) {
      final message = e.toString();
      throw Exception(_mapAuthErrorMessage(message));
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> handleAuthCallback(BuildContext context) async {
    final session = supabase.auth.currentSession;

    if (session != null) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  String _mapAuthErrorMessage(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email ou password incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirma o teu email antes de entrar.';
    }
    if (msg.contains('user already registered')) {
      return 'Já existe uma conta com este email.';
    }
    return 'Erro de autenticação. Tenta novamente.';
  }

  void continueAsGuest() {
    _state = const AuthState(status: AuthStatus.guest);
    notifyListeners();
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  Future<void> fullLogout() async {
    try {
      // 1) Sair do Supabase
      await supabase.auth.signOut();
      // 2) Sair / desconectar Google (se tiveres usado login com Google)
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      try {
        // disconnect revoga a autorização e força novo consentimento
        await googleSignIn.disconnect();
      } catch (_) {
        // alguns devices lançam erro se já estiver desconectado, ignora
      }
    } finally {
      // 3) Atualizar estado local
      _state = const AuthState(status: AuthStatus.unauthenticated);
      notifyListeners();
    }
  }
}
