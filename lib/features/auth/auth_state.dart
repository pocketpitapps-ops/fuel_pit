// lib\features\auth\auth_state.dart
import 'package:supabase_flutter/supabase_flutter.dart' show User;

enum AuthStatus { unknown, unauthenticated, guest, authenticated }

class AuthState {
  final AuthStatus status;
  final User? supabaseUser;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.supabaseUser,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    Object? supabaseUser = _unset,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      supabaseUser: identical(supabaseUser, _unset)
          ? this.supabaseUser
          : supabaseUser as User?,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const _unset = Object();

  static AuthState initial() => const AuthState(status: AuthStatus.unknown);
}
