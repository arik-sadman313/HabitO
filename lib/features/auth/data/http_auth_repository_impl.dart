import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'secure_session_manager.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/domain_models.dart';
import '../../../core/database/enums.dart';

final httpAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepositoryImpl(
    ref.read(dioClientProvider).dio,
    SecureSessionManager(),
  );
});

class HttpAuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SecureSessionManager _sessionManager;

  HttpAuthRepositoryImpl(this._dio, this._sessionManager);

  @override
  Future<User> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    final accessToken = response.data['access_token'];
    final refreshToken = response.data['refresh_token'];
    await _sessionManager.saveTokens(access: accessToken, refresh: refreshToken);
    
    final userResponse = await _dio.get('/auth/me');
    return User(
      id: userResponse.data['id'],
      name: userResponse.data['display_name'],
      email: userResponse.data['email'],
      timezone: userResponse.data['timezone'] ?? 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Future<User> register(String name, String email, String password) async {
    await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': name,
    });
    
    return login(email, password);
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _sessionManager.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      }
    } catch (e) {
      // Ignore errors on logout (e.g. offline)
    } finally {
      await _sessionManager.clearSession();
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _sessionManager.getAccessToken();
    if (token == null) return null;
    
    try {
      final userResponse = await _dio.get('/auth/me');
      return User(
        id: userResponse.data['id'],
        name: userResponse.data['display_name'],
        email: userResponse.data['email'],
        timezone: userResponse.data['timezone'] ?? 'UTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Couple> createInvitation() async {
    // Unimplemented for Phase 13 Foundation
    throw UnimplementedError();
  }

  @override
  Future<Couple> joinInvitation(String code) async {
    // Unimplemented for Phase 13 Foundation
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  @override
  Future<User> updateProfile({String? name, String? timezone}) async {
    final response = await _dio.patch('/auth/me', data: {
      if (name != null) 'display_name': name,
      if (timezone != null) 'timezone': timezone,
    });
    
    return User(
      id: response.data['id'],
      name: response.data['display_name'],
      email: response.data['email'],
      timezone: response.data['timezone'] ?? 'UTC',
      createdAt: DateTime.now(), // Simplified
      updatedAt: DateTime.now(), // Simplified
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _dio.delete('/auth/me');
    await logout();
  }
}
