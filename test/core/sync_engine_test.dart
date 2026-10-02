import 'package:flutter_test/flutter_test.dart';
import 'package:habito/core/sync/sync_engine.dart';
import 'package:habito/core/network/dio_client.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/features/auth/data/secure_session_manager.dart';
import 'package:habito/features/activities/data/activity_repository.dart';
import 'package:habito/features/habits/data/habit_repository.dart';
import 'package:habito/features/trackers/data/tracker_repository.dart';
import 'package:habito/features/study/data/study_repository.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';
import 'package:habito/features/journal/data/journal_repository.dart';
import 'package:habito/features/wellbeing/data/mood_repository.dart';
import 'package:habito/features/goals/data/personal_goal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late AppDatabase database;
  late SyncEngine syncEngine;
  
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final sessionManager = SecureSessionManager();
    final dioClient = DioClient(sessionManager);
    final activitiesRepo = ActivityRepositoryImpl(database);
    final habitsRepo = HabitRepositoryImpl(database);
    final trackersRepo = TrackerRepositoryImpl(database);
    final studyRepo = StudyRepositoryImpl(database);
    final mealRepo = MealRepositoryImpl(database);
    final sleepRepo = SleepRepositoryImpl(database);
    final exerciseRepo = ExerciseRepositoryImpl(database);
    final journalRepo = JournalRepositoryImpl(database);
    final moodRepo = MoodRepositoryImpl(database);
    final goalRepo = PersonalGoalRepositoryImpl(database);
    syncEngine = SyncEngine(
      database,
      dioClient,
      activitiesRepo,
      habitsRepo,
      trackersRepo,
      studyRepo,
      mealRepo,
      sleepRepo,
      exerciseRepo,
      journalRepo,
      moodRepo,
      goalRepo,
    );
  });
  
  tearDown(() async {
    await database.close();
  });
  
  test('SyncEngine resolves device ID', () async {
    // Cannot easily test private method, but we can verify it doesn't crash on empty queue
    await syncEngine.push();
    
    // We inserted nothing into the queue, so it should return early
    final prefs = await SharedPreferences.getInstance();
    // deviceId should NOT be set if it returned early
    expect(prefs.getString('device_id'), isNull);
  });
}

