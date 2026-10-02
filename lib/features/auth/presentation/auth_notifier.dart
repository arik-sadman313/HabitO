import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/repositories/user_repository.dart';
import 'package:habito/features/auth/data/auth_repository.dart';
import 'package:habito/features/auth/data/secure_session_manager.dart';
import 'package:habito/features/auth/domain/api_contract.dart';
import 'package:habito/features/auth/domain/auth_state.dart';

import 'package:habito/core/config/app_config.dart';
import 'package:habito/features/auth/data/http_auth_repository_impl.dart';

// Provides the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockAuth) {
    final database = db.AppDatabase();
    final userRepo = UserRepositoryImpl(database);
    final sessionManager = SecureSessionManager();
    return MockAuthRepositoryImpl(sessionManager, userRepo);
  } else {
    return ref.read(httpAuthRepositoryProvider);
  }
});

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.restoreSession();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await repo.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.authenticationError, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.authenticationError, errorMessage: 'Unknown error');
    }
  }

  Future<void> register(String name, String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final user = await repo.register(name, email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.authenticationError, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateProfile({String? name, String? timezone}) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final updatedUser = await repo.updateProfile(name: name, timezone: timezone);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // Typically should expose a way to show error via Snackbar, maybe throw
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.changePassword(currentPassword, newPassword);
  }

  Future<void> deleteAccount() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
