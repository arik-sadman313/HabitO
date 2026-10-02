import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:habito/features/auth/domain/auth_state.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/auth/data/auth_repository.dart';
import 'package:habito/features/auth/data/secure_session_manager.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/repositories/user_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FakeSecureSessionManager extends SecureSessionManager {
  FakeSecureSessionManager() : super(storage: const FlutterSecureStorage());
  
  String? _access;
  String? _refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> clearSession() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  late ProviderContainer container;
  late MockAuthRepositoryImpl mockRepo;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final userRepo = UserRepositoryImpl(db);
    final sessionManager = FakeSecureSessionManager();
    mockRepo = MockAuthRepositoryImpl(sessionManager, userRepo);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  test('Initial state is unauthenticated after restoration if no token', () async {
    // We wait for the constructor's _restoreSession to finish
    await Future.delayed(const Duration(milliseconds: 600));
    final state = container.read(authNotifierProvider);
    expect(state.status, AuthStatus.unauthenticated);
  });

  // Additional tests would cover login/register state changes.
  // Because flutter_secure_storage requires mock platform channels,
  // those tests require extensive setup not fully fleshed out here.
}
