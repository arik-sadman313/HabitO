import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';
import 'package:habito/features/screen_time/data/screen_time_repository.dart';
import 'package:habito/features/goals/domain/goal_progress_service.dart';
import 'package:habito/features/study/data/study_repository.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';
import 'package:mocktail/mocktail.dart';

class MockStudyRepository extends Mock implements StudyRepository {}
class MockExerciseRepository extends Mock implements ExerciseRepository {}
class MockSleepRepository extends Mock implements SleepRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ScreenTimeRepository repository;
  late MockStudyRepository studyRepo;
  late MockExerciseRepository exerciseRepo;
  late MockSleepRepository sleepRepo;
  late GoalProgressService progressService;

  setUp(() async {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = ScreenTimeRepositoryImpl(database);

    studyRepo = MockStudyRepository();
    exerciseRepo = MockExerciseRepository();
    sleepRepo = MockSleepRepository();

    progressService = GoalProgressService(
      studyRepo,
      exerciseRepo,
      sleepRepo,
      repository,
    );

    // Insert dummy user to satisfy FK
    await database.into(database.usersTable).insert(
      UsersTableCompanion.insert(
        id: 'user-st-1',
        name: 'ST User One',
        email: 'stuser1@example.com',
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

  group('Screen Time Daily Snapshot Sync & Repository Tests', () {
    test('syncTodaySnapshot creates local snapshot and enqueues SyncQueue mutation atomically', () async {
      final now = DateTime.now();
      final summary = ScreenTimeSummary(
        date: DateTime(now.year, now.month, now.day),
        totalDuration: const Duration(hours: 3, minutes: 30),
        appCount: 8,
        lastUpdated: now,
        topApps: const [],
      );

      await repository.syncTodaySnapshot('user-st-1', summary);

      // Verify DB record created
      final records = await database.select(database.screenTimeDailySnapshotsTable).get();
      expect(records.length, 1);
      expect(records.first.userId, 'user-st-1');
      expect(records.first.totalDurationSeconds, 12600); // 3h 30m = 12600s
      expect(records.first.appCount, 8);

      // Verify SyncQueue operation
      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps.length, 1);
      expect(queueOps.first.entityType, 'screen_time_daily_snapshot');
      expect(queueOps.first.scopeId, 'user-st-1');
      expect(queueOps.first.operation, 'upsert');

      final payload = jsonDecode(queueOps.first.payload!);
      expect(payload['total_duration_seconds'], 12600);
      expect(payload['app_count'], 8);
    });

    test('Repeated same-day refresh updates existing snapshot without creating duplicate records', () async {
      final now = DateTime.now();
      final summary1 = ScreenTimeSummary(
        date: DateTime(now.year, now.month, now.day),
        totalDuration: const Duration(hours: 2),
        appCount: 4,
        lastUpdated: now,
        topApps: const [],
      );

      await repository.syncTodaySnapshot('user-st-1', summary1);

      // Second refresh later in the day
      final summary2 = ScreenTimeSummary(
        date: DateTime(now.year, now.month, now.day),
        totalDuration: const Duration(hours: 5),
        appCount: 10,
        lastUpdated: now,
        topApps: const [],
      );

      await repository.syncTodaySnapshot('user-st-1', summary2);

      // Verify ONLY ONE snapshot exists for that user and day
      final records = await database.select(database.screenTimeDailySnapshotsTable).get();
      expect(records.length, 1);
      expect(records.first.totalDurationSeconds, 18000); // 5 hours
      expect(records.first.appCount, 10);
    });

    test('applyRemoteScreenTimeSnapshotChange applies remote change without enqueuing SyncQueue', () async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final dto = ScreenTimeDailySnapshotDto(
        id: 'remote-st-snapshot-1',
        userId: 'user-st-1',
        date: startOfDay,
        totalDurationSeconds: 7200,
        appCount: 6,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.applyRemoteScreenTimeSnapshotChange(dto);

      final records = await database.select(database.screenTimeDailySnapshotsTable).get();
      expect(records.length, 1);
      expect(records.first.id, 'remote-st-snapshot-1');
      expect(records.first.totalDurationSeconds, 7200);

      // Verify NO SyncQueue entry was created (loop prevention)
      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps, isEmpty);
    });

    test('applyRemoteScreenTimeSnapshotDelete soft deletes locally without enqueuing SyncQueue', () async {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final dto = ScreenTimeDailySnapshotDto(
        id: 'remote-st-snapshot-2',
        userId: 'user-st-1',
        date: startOfDay,
        totalDurationSeconds: 3600,
        appCount: 3,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await repository.applyRemoteScreenTimeSnapshotChange(dto);

      await repository.applyRemoteScreenTimeSnapshotDelete('remote-st-snapshot-2', now);

      final history = await repository.getWeeklyHistory('user-st-1');
      expect(history.any((d) => d.totalDuration.inSeconds == 3600), isFalse);

      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps, isEmpty);
    });

    test('getWeeklyHistory reads synchronized snapshots correctly', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      await repository.applyRemoteScreenTimeSnapshotChange(
        ScreenTimeDailySnapshotDto(
          id: 'st-yesterday',
          userId: 'user-st-1',
          date: yesterday,
          totalDurationSeconds: 14400,
          appCount: 15,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      );

      await repository.applyRemoteScreenTimeSnapshotChange(
        ScreenTimeDailySnapshotDto(
          id: 'st-today',
          userId: 'user-st-1',
          date: today,
          totalDurationSeconds: 10800,
          appCount: 9,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      );

      final history = await repository.getWeeklyHistory('user-st-1');
      expect(history.length, 2);
      expect(history.first.totalDuration.inHours, 4);
      expect(history.last.totalDuration.inHours, 3);
    });

    test('GoalProgressService calculates Screen Time reduction goals correctly using synchronized snapshots', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repository.applyRemoteScreenTimeSnapshotChange(
        ScreenTimeDailySnapshotDto(
          id: 'st-goal-snap',
          userId: 'user-st-1',
          date: today.subtract(const Duration(days: 1)),
          totalDurationSeconds: 14400, // 4 hours used
          appCount: 10,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      );

      final goal = PersonalGoal(
        id: 'st-reduction-goal',
        userId: 'user-st-1',
        title: 'Limit Screen Time to 5 hours',
        goalType: GoalType.screenTimeReduction,
        targetValue: 5.0, // Target is max 5 hours
        startDate: today.subtract(const Duration(days: 7)),
        targetDate: today.add(const Duration(days: 7)),
        status: GoalStatus.active,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

      final progress = await progressService.calculateProgress(goal);
      expect(progress.actual, 4.0); // 4 hours used
      expect(progress.progressRatio, 1.0); // 4 <= 5 -> ratio is 1.0
      expect(progress.dataAvailability, DataAvailability.available);
    });
  });
}
