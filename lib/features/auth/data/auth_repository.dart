import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/repositories/user_repository.dart';
import 'package:habito/features/auth/data/secure_session_manager.dart';
import 'package:habito/features/auth/domain/api_contract.dart';
import 'package:uuid/uuid.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> logout();
  Future<User?> restoreSession();
  Future<Couple> createInvitation();
  Future<Couple> joinInvitation(String code);
}

class MockAuthRepositoryImpl implements AuthRepository {
  final SecureSessionManager _sessionManager;
  final UserRepository _userRepository;
  
  // In-memory mock states
  User? _currentUser;
  static final Map<String, Couple> _mockInvitations = {}; // code -> Couple

  MockAuthRepositoryImpl(this._sessionManager, this._userRepository);

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (password != 'password123') {
      throw AuthException('Invalid credentials');
    }
    
    // Simulate finding user in local db
    // Since it's a mock, we'll just create one if it doesn't exist for simplicity,
    // or assume restoring finds it.
    final user = User(
      id: const Uuid().v4(),
      name: 'Mock User',
      email: email,
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    
    await _sessionManager.saveTokens(access: 'mock_access', refresh: 'mock_refresh');
    await _userRepository.saveUser(user);
    _currentUser = user;
    return user;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = User(
      id: const Uuid().v4(),
      name: name,
      email: email,
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    
    await _sessionManager.saveTokens(access: 'mock_access', refresh: 'mock_refresh');
    await _userRepository.saveUser(user);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await _sessionManager.clearSession();
    _currentUser = null;
  }

  @override
  Future<User?> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final token = await _sessionManager.getAccessToken();
    if (token == null) return null;
    
    if (_currentUser != null) return _currentUser;
    
    // For mock, just return a dummy if we had a token
    return User(
      id: 'mock_restored_id',
      name: 'Restored User',
      email: 'restored@example.com',
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Future<Couple> createInvitation() async {
    await Future.delayed(const Duration(seconds: 1));
    if (_currentUser == null) throw AuthException('Not authenticated');
    
    final code = '123456';
    final couple = Couple(
      id: const Uuid().v4(),
      userAId: _currentUser!.id,
      userBId: '', // Pending
      status: CoupleStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    _mockInvitations[code] = couple;
    return couple;
  }

  @override
  Future<Couple> joinInvitation(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_currentUser == null) throw AuthException('Not authenticated');
    
    final couple = _mockInvitations[code];
    if (couple == null) throw AuthException('Invalid invitation code');
    if (couple.userAId == _currentUser!.id) throw AuthException('Cannot join your own invitation');
    
    final pairedCouple = Couple(
      id: couple.id,
      userAId: couple.userAId,
      userBId: _currentUser!.id,
      status: CoupleStatus.active,
      createdAt: couple.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    _mockInvitations.remove(code);
    return pairedCouple;
  }
}
