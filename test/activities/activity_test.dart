import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/activities/data/activity_repository.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late ActivityRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repo = ActivityRepositoryImpl(db);
    
    // Insert a dummy user to satisfy foreign key constraints
    await db.into(db.usersTable).insert(
      UsersTableCompanion.insert(
        id: 'user1',
        name: 'Test User',
        email: 'test@example.com',
        timezone: 'UTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Save and retrieve activity', () async {
    final activity = Activity(
      id: 'test-id',
      userId: 'user1',
      title: 'Test Activity',
      scheduledStart: DateTime(2026, 1, 1, 10, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await repo.saveActivity(activity);

    final result = await repo.getActivity('test-id');
    expect(result, isNotNull);
    expect(result!.title, 'Test Activity');
  });

  test('Toggle activity completion', () async {
    final activity = Activity(
      id: 'test-id-2',
      userId: 'user1',
      title: 'Incomplete',
      scheduledStart: DateTime(2026, 1, 1, 10, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
      isCompleted: false,
    );

    await repo.saveActivity(activity);
    
    await repo.toggleActivityCompletion('test-id-2', true);

    final result = await repo.getActivity('test-id-2');
    expect(result!.isCompleted, true);
  });
}
