import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/us/data/us_repository.dart';


import 'package:habito/features/us/data/couple_api.dart';

class FakeCoupleApi implements CoupleApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late UsRepositoryImpl usRepo;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    usRepo = UsRepositoryImpl(db, FakeCoupleApi());

    await db.into(db.usersTable).insert(UsersTableCompanion.insert(
      id: 'user-a',
      name: 'User A',
      email: 'a@example.com',
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.usersTable).insert(UsersTableCompanion.insert(
      id: 'user-b',
      name: 'User B',
      email: 'b@example.com',
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    ));
    await db.into(db.couplesTable).insert(CouplesTableCompanion.insert(
      id: 'couple-1',
      userAId: 'user-a',
      userBId: 'user-b',
      status: CoupleStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('saveSharedGoal enqueues atomic SyncQueue entry with couple scope', () async {
    final goal = SharedGoal(
      id: 'sg-1',
      coupleId: 'couple-1',
      title: 'Buy House',
      description: 'Dream home',
      target: 100000.0,
      currentProgress: 25000.0,
      unit: 'USD',
      deadline: DateTime(2027, 12, 31),
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await usRepo.saveSharedGoal(goal);

    final localGoals = await db.select(db.sharedGoalsTable).get();
    expect(localGoals.length, 1);
    expect(localGoals.first.title, 'Buy House');

    final queueEntries = await db.select(db.syncQueueTable).get();
    expect(queueEntries.length, 1);
    expect(queueEntries.first.entityType, 'shared_goal');
    expect(queueEntries.first.entityId, 'sg-1');
    expect(queueEntries.first.scopeType, 'couple');
    expect(queueEntries.first.scopeId, 'couple-1');
    expect(queueEntries.first.operation, 'upsert');
  });

  test('deleteSharedGoal marks soft deleted and enqueues sync delete', () async {
    final goal = SharedGoal(
      id: 'sg-2',
      coupleId: 'couple-1',
      title: 'Trip to Japan',
      target: 5000.0,
      currentProgress: 0.0,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await usRepo.saveSharedGoal(goal);
    await db.delete(db.syncQueueTable).go(); // Clear queue from save

    await usRepo.deleteSharedGoal('sg-2');

    final localGoals = await db.select(db.sharedGoalsTable).get();
    expect(localGoals.first.isDeleted, isTrue);

    final queueEntries = await db.select(db.syncQueueTable).get();
    expect(queueEntries.length, 1);
    expect(queueEntries.first.entityType, 'shared_goal');
    expect(queueEntries.first.entityId, 'sg-2');
    expect(queueEntries.first.scopeType, 'couple');
    expect(queueEntries.first.scopeId, 'couple-1');
    expect(queueEntries.first.operation, 'delete');
  });

  test('saveSharedHabit enqueues couple scope sync entry', () async {
    final habit = SharedHabit(
      id: 'sh-1',
      coupleId: 'couple-1',
      title: 'Daily Walk Together',
      frequency: HabitFrequency.daily,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await usRepo.saveSharedHabit(habit);

    final queueEntries = await db.select(db.syncQueueTable).get();
    expect(queueEntries.length, 1);
    expect(queueEntries.first.entityType, 'shared_habit');
    expect(queueEntries.first.scopeType, 'couple');
    expect(queueEntries.first.scopeId, 'couple-1');
  });

  test('saveMemory enqueues couple scope sync entry', () async {
    final memory = Memory(
      id: 'mem-1',
      coupleId: 'couple-1',
      title: 'Anniversary Dinner',
      description: 'Candlelight dinner',
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await usRepo.saveMemory(memory);

    final queueEntries = await db.select(db.syncQueueTable).get();
    expect(queueEntries.length, 1);
    expect(queueEntries.first.entityType, 'memory');
    expect(queueEntries.first.scopeType, 'couple');
  });

  test('applyRemoteSharedGoalChange writes directly to Drift without re-queueing (Loop Prevention)', () async {
    final remoteGoal = SharedGoal(
      id: 'sg-remote-1',
      coupleId: 'couple-1',
      title: 'Remote Goal',
      target: 200.0,
      currentProgress: 50.0,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    await usRepo.applyRemoteSharedGoalChange(remoteGoal);

    final localGoals = await db.select(db.sharedGoalsTable).get();
    expect(localGoals.length, 1);
    expect(localGoals.first.title, 'Remote Goal');

    final queueEntries = await db.select(db.syncQueueTable).get();
    expect(queueEntries, isEmpty); // NO re-queueing!
  });
}
