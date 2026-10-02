import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/wellbeing/data/mood_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late MoodRepositoryImpl repo;

  const testUserId = 'user-mood-test-001';

  setUp(() async {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repo = MoodRepositoryImpl(database);
    // Insert test user to satisfy FK constraint on moodLogsTable.userId
    await database.into(database.usersTable).insert(
      UsersTableCompanion.insert(
        id: testUserId,
        name: 'Mood Test User',
        email: 'mood-test@example.com',
        timezone: 'UTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  MoodLog _makeLog({String id = 'mood-001'}) {
    final now = DateTime.now();
    return MoodLog(
      id: id,
      userId: testUserId,
      date: now,
      moodRating: 4,
      energyRating: 3,
      stressRating: 2,
      note: 'Feeling good',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: false,
    );
  }

  group('MoodRepository sync integration', () {
    test('saveCheckIn persists log and enqueues sync operation', () async {
      final log = _makeLog();
      await repo.saveCheckIn(log);

      // Verify saved
      final logs = await database.select(database.moodLogsTable).get();
      expect(logs.length, 1);
      expect(logs.first.id, log.id);
      expect(logs.first.moodRating, 4);
      expect(logs.first.syncStatus, SyncStatus.pendingUpdate);

      // Verify queue
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, 'mood_log');
      expect(queue.first.entityId, log.id);
      expect(queue.first.operation, 'upsert');
      expect(queue.first.scopeId, testUserId);
    });

    test('deleteMoodLog soft-deletes and enqueues delete operation', () async {
      final log = _makeLog();
      await repo.saveCheckIn(log);

      // Clear queue from save
      await database.delete(database.syncQueueTable).go();

      await repo.deleteMoodLog(log.id);

      // Verify soft-delete
      final logs = await database.select(database.moodLogsTable).get();
      expect(logs.first.isDeleted, true);
      expect(logs.first.syncStatus, SyncStatus.pendingUpdate);

      // Verify delete queued
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, 'mood_log');
      expect(queue.first.operation, 'delete');
    });

    test('applyRemoteMoodChange does not create a sync queue entry (loop prevention)', () async {
      final log = _makeLog();
      await repo.applyRemoteMoodChange(log.copyWithSynced());

      // Verify applied
      final logs = await database.select(database.moodLogsTable).get();
      expect(logs.length, 1);
      expect(logs.first.syncStatus, SyncStatus.synced);

      // Critically: no queue entry
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.isEmpty, true);
    });

    test('applyRemoteMoodDelete soft-deletes without re-queuing', () async {
      final log = _makeLog();
      await repo.applyRemoteMoodChange(log.copyWithSynced());

      await repo.applyRemoteMoodDelete(log.id, DateTime.now());

      // Verify deleted
      final logs = await database.select(database.moodLogsTable).get();
      expect(logs.first.isDeleted, true);
      expect(logs.first.syncStatus, SyncStatus.synced);

      // No new queue entry
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.isEmpty, true);
    });

    test('watchCheckInForDate returns log for correct logical day', () async {
      final today = DateTime.now();
      final log = _makeLog();
      await repo.saveCheckIn(log);

      final result = await repo.watchCheckInForDate(testUserId, today).first;
      expect(result, isNotNull);
      expect(result!.id, log.id);
    });

    test('watchMoodHistory returns recent logs', () async {
      final log = _makeLog();
      await repo.saveCheckIn(log);

      final history = await repo.watchMoodHistory(testUserId, 30).first;
      expect(history.length, 1);
      expect(history.first.moodRating, 4);
    });

    test('saveCheckIn transaction: log and queue are atomic', () async {
      final log = _makeLog(id: 'atomic-mood-001');
      await repo.saveCheckIn(log);

      final logs = await database.select(database.moodLogsTable).get();
      final queue = await database.select(database.syncQueueTable).get();
      expect(logs.length, 1);
      expect(queue.length, 1);
    });
  });
}

extension on MoodLog {
  MoodLog copyWithSynced() {
    return MoodLog(
      id: id,
      userId: userId,
      date: date,
      moodRating: moodRating,
      energyRating: energyRating,
      stressRating: stressRating,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }
}
