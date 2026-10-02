import 'package:flutter_test/flutter_test.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
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
  late MockStudyRepository studyRepo;
  late MockExerciseRepository exerciseRepo;
  late MockSleepRepository sleepRepo;
  late MockScreenTimeRepository screenTimeRepo;
  late GoalProgressService service;

  setUp(() {
    studyRepo = MockStudyRepository();
    exerciseRepo = MockExerciseRepository();
    sleepRepo = MockSleepRepository();
    screenTimeRepo = MockScreenTimeRepository();

    service = GoalProgressService(
      studyRepo,
      exerciseRepo,
      sleepRepo,
      screenTimeRepo,
    );
  });

  group('GoalProgressService tests', () {
    test('Calculates study duration properly', () async {
      when(() => studyRepo.watchSessions('user-1')).thenAnswer((_) => Stream.value([
        StudySession(id: '1', userId: 'user-1', subjectId: 'subj', startedAt: DateTime.now().subtract(const Duration(days: 1)), duration: 3600, createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.synced, isDeleted: false), // 1 hr
        StudySession(id: '2', userId: 'user-1', subjectId: 'subj', startedAt: DateTime.now().subtract(const Duration(days: 1)), duration: 1800, createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.synced, isDeleted: false), // 0.5 hr
      ]));

      final goal = PersonalGoal(
        id: 'goal-1',
        userId: 'user-1',
        title: 'Study Goal',
        goalType: GoalType.studyDuration,
        targetValue: 2.0, // 2 hours
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        targetDate: DateTime.now().add(const Duration(days: 7)),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      final progress = await service.calculateProgress(goal);

      expect(progress.actual, 1.5);
      expect(progress.progressRatio, 0.75); // 1.5 / 2.0
      expect(progress.percentage, 75);
      expect(progress.dataAvailability, DataAvailability.available);
    });
    
    test('Handles missing data gracefully', () async {
      when(() => studyRepo.watchSessions('user-1')).thenAnswer((_) => Stream.value([]));
      
      final goal = PersonalGoal(
        id: 'goal-1',
        userId: 'user-1',
        title: 'Study Goal',
        goalType: GoalType.studyDuration,
        targetValue: 2.0, // 2 hours
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        targetDate: DateTime.now().add(const Duration(days: 7)),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      final progress = await service.calculateProgress(goal);

      expect(progress.actual, 0.0);
      expect(progress.progressRatio, 0.0);
      expect(progress.dataAvailability, DataAvailability.unavailable);
    });

    test('Screen time reduction goal is clamped correctly', () async {
      when(() => screenTimeRepo.getWeeklyHistory('user-1')).thenAnswer((_) async => [
        ScreenTimeDay(date: DateTime.now().subtract(const Duration(days: 1)), totalDuration: const Duration(hours: 4)),
      ]);
      
      final goal = PersonalGoal(
        id: 'goal-2',
        userId: 'user-1',
        title: 'Reduce screen time',
        goalType: GoalType.screenTimeReduction,
        targetValue: 3.0, // Target is 3 hours
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        targetDate: DateTime.now().add(const Duration(days: 7)),
        status: GoalStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      final progress = await service.calculateProgress(goal);

      expect(progress.actual, 4.0); // 4 hours used
      expect(progress.progressRatio, 0.75); // 3/4
      expect(progress.dataAvailability, DataAvailability.available);
    });
  });
}
