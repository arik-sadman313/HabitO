import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/repositories/user_repository.dart';

void main() {
  late db.AppDatabase database;
  late UserRepository userRepository;

  setUp(() {
    database = db.AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    userRepository = UserRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('User can be inserted and retrieved', () async {
    final user = User(
      id: 'user_123',
      name: 'Arik',
      email: 'arik@example.com',
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingInsert,
    );

    await userRepository.saveUser(user);

    final fetchedUser = await userRepository.getUser('user_123');

    expect(fetchedUser, isNotNull);
    expect(fetchedUser!.name, 'Arik');
    expect(fetchedUser.email, 'arik@example.com');
  });
}
