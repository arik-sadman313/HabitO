import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/goals/data/personal_goal_repository.dart';
import 'package:habito/features/goals/domain/goal_progress_service.dart';
import 'package:habito/features/study/data/study_repository.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';
import 'package:habito/features/screen_time/data/screen_time_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockStudyRepository extends Mock implements StudyRepository {}
class MockExerciseRepository extends Mock implements ExerciseRepository {}
class MockSleepRepository extends Mock implements SleepRepository {}
class MockScreenTimeRepository extends Mock implements ScreenTimeRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PersonalGoalRepository repository;
  late MockStudyRepository studyRepo;
  late MockExerciseRepository exerciseRepo;
  late MockSleepRepository sleepRepo;
  late MockScreenTimeRepository screenTimeRepo;
  late GoalProgressService progressService;

  setUp(() async {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = PersonalGoalRepositoryImpl(database);

    studyRepo = MockStudyRepository();
    exerciseRepo = MockExerciseRepository();
    sleepRepo = MockSleepRepository();
    screenTimeRepo = MockScreenTimeRepository();

    progressService = GoalProgressService(
      studyRepo,
      exerciseRepo,
      sleepRepo,
      screenTimeRepo,
    );

    // Insert dummy user into local DB to satisfy FK
    await database.into(database.usersTable).insert(
      UsersTableCompanion.insert(
        id: 'user-1',
        name: 'User One',
        email: 'user1@example.com',
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

  group('Personal Goal Sync & Repository Tests', () {
    test('createGoal inserts local record and enqueues SyncQueue mutation', () async {
      final goal = PersonalGoal(
        id: 'goal-101',
        userId: 'user-1',
        title: 'Study Goal',
        description: 'Read Flutter docs',
        goalType: GoalType.studyDuration,
        targetValue: 10.0,
        currentValue: 0.0,
        unit: 'hours',
        startDate: DateTime.now(),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingInsert,
      );

      await repository.createGoal(goal);

      // Check DB
      final saved = await repository.getGoal('goal-101');
      expect(saved, isNotNull);
      expect(saved!.title, 'Study Goal');

      // Check SyncQueue
      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps.length, 1);
      expect(queueOps.first.entityType, 'personal_goal');
      expect(queueOps.first.entityId, 'goal-101');
      expect(queueOps.first.operation, 'upsert');
      
      final payload = jsonDecode(queueOps.first.payload!);
      expect(payload['title'], 'Study Goal');
      expect(payload['target_value'], 10.0);
    });

    test('updateGoal updates local record and enqueues SyncQueue mutation', () async {
      final goal = PersonalGoal(
        id: 'goal-102',
        userId: 'user-1',
        title: 'Initial Goal',
        goalType: GoalType.custom,
        targetValue: 5.0,
        startDate: DateTime.now(),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingInsert,
      );
      await repository.createGoal(goal);
      await database.delete(database.syncQueueTable).go(); // Clear queue

      final updated = PersonalGoal(
        id: 'goal-102',
        userId: 'user-1',
        title: 'Updated Goal Title',
        goalType: GoalType.custom,
        targetValue: 8.0,
        startDate: goal.startDate,
        status: GoalStatus.active,
        createdAt: goal.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );

      await repository.updateGoal(updated);

      final fetched = await repository.getGoal('goal-102');
      expect(fetched!.title, 'Updated Goal Title');
      expect(fetched.targetValue, 8.0);

      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps.length, 1);
      expect(queueOps.first.operation, 'upsert');
    });

    test('deleteGoal soft deletes record and enqueues SyncQueue delete operation', () async {
      final goal = PersonalGoal(
        id: 'goal-103',
        userId: 'user-1',
        title: 'Goal to delete',
        goalType: GoalType.custom,
        targetValue: 3.0,
        startDate: DateTime.now(),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );
      await repository.createGoal(goal);
      await database.delete(database.syncQueueTable).go(); // Clear queue

      await repository.deleteGoal('goal-103');

      final activeList = await repository.watchActiveGoals('user-1').first;
      expect(activeList.any((g) => g.id == 'goal-103'), isFalse);

      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps.length, 1);
      expect(queueOps.first.entityId, 'goal-103');
      expect(queueOps.first.operation, 'delete');
    });

    test('applyRemotePersonalGoalChange applies change without enqueuing SyncQueue', () async {
      final remoteGoal = PersonalGoal(
        id: 'goal-remote-1',
        userId: 'user-1',
        title: 'Remote Goal',
        goalType: GoalType.studyDuration,
        targetValue: 20.0,
        startDate: DateTime.now(),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      await repository.applyRemotePersonalGoalChange(remoteGoal);

      final localGoal = await repository.getGoal('goal-remote-1');
      expect(localGoal, isNotNull);
      expect(localGoal!.title, 'Remote Goal');

      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps, isEmpty); // Loop prevention verified!
    });

    test('applyRemotePersonalGoalDelete soft deletes locally without enqueuing SyncQueue', () async {
      final remoteGoal = PersonalGoal(
        id: 'goal-remote-2',
        userId: 'user-1',
        title: 'Remote Goal 2',
        goalType: GoalType.custom,
        targetValue: 15.0,
        startDate: DateTime.now(),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );
      await repository.applyRemotePersonalGoalChange(remoteGoal);

      await repository.applyRemotePersonalGoalDelete('goal-remote-2', DateTime.now());

      final activeList = await repository.watchActiveGoals('user-1').first;
      expect(activeList.any((g) => g.id == 'goal-remote-2'), isFalse);

      final queueOps = await database.select(database.syncQueueTable).get();
      expect(queueOps, isEmpty); // Loop prevention verified!
    });

    test('GoalProgressService calculates progress on synchronized remote goal from local source data', () async {
      final remoteGoal = PersonalGoal(
        id: 'goal-remote-study',
        userId: 'user-1',
        title: 'Synced Study Goal',
        goalType: GoalType.studyDuration,
        targetValue: 2.0, // 2 hours
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        targetDate: DateTime.now().add(const Duration(days: 7)),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      await repository.applyRemotePersonalGoalChange(remoteGoal);

      when(() => studyRepo.watchSessions('user-1')).thenAnswer((_) => Stream.value([
        StudySession(
          id: 's1',
          userId: 'user-1',
          subjectId: 'subj1',
          startedAt: DateTime.now().subtract(const Duration(days: 1)),
          duration: 3600, // 1 hour
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ),
      ]));

      final progress = await progressService.calculateProgress(remoteGoal);
      expect(progress.actual, 1.0);
      expect(progress.percentage, 50);
      expect(progress.dataAvailability, DataAvailability.available);
    });
  });
}
