import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';

void main() {
  group('Lifestyle Repositories', () {
    late AppDatabase db;
    late MealRepositoryImpl mealRepo;
    late SleepRepositoryImpl sleepRepo;
    late ExerciseRepositoryImpl exerciseRepo;

    setUp(() async {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      mealRepo = MealRepositoryImpl(db);
      sleepRepo = SleepRepositoryImpl(db);
      exerciseRepo = ExerciseRepositoryImpl(db);
      
      await db.into(db.usersTable).insert(
        UsersTableCompanion.insert(
          id: 'user1',
          name: 'Test',
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

    test('Meal CRUD with items', () async {
      final mealId = 'meal1';
      final meal = Meal(
        id: mealId,
        userId: 'user1',
        mealType: 'Lunch',
        recordedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await mealRepo.saveMeal(meal);
      
      final item = MealItem(
        id: 'item1',
        mealId: mealId,
        name: 'Apple',
        quantity: 1,
        unit: 'piece',
      );
      await mealRepo.saveMealItem(item);
      
      final stream = mealRepo.watchMealsForDate('user1', DateTime.now());
      final meals = await stream.first;
      
      expect(meals.length, 1);
      expect(meals.first.mealType, 'Lunch');
      expect(meals.first.items.length, 1);
      expect(meals.first.items.first.name, 'Apple');
    });

    test('Sleep logical day assignment', () async {
      final sleepStart = DateTime(2023, 10, 5, 23, 30); // Oct 5, 11:30 PM
      final wakeTime = DateTime(2023, 10, 6, 7, 0); // Oct 6, 7:00 AM
      final duration = wakeTime.difference(sleepStart).inSeconds;
      
      final sleep = SleepRecord(
        id: 'sleep1',
        userId: 'user1',
        sleepStart: sleepStart,
        wakeTime: wakeTime,
        duration: duration,
        quality: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await sleepRepo.saveSleep(sleep);
      
      // Querying for Oct 5 should return empty (because they woke up on the 6th)
      final stream5 = sleepRepo.watchSleepForDate('user1', DateTime(2023, 10, 5));
      final records5 = await stream5.first;
      expect(records5.isEmpty, true);
      
      // Querying for Oct 6 should return the record
      final stream6 = sleepRepo.watchSleepForDate('user1', DateTime(2023, 10, 6));
      final records6 = await stream6.first;
      expect(records6.length, 1);
      expect(records6.first.duration, duration);
    });

    test('Exercise CRUD', () async {
      final session = ExerciseSession(
        id: 'ex1',
        userId: 'user1',
        exerciseType: 'Running',
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        endedAt: DateTime.now(),
        duration: 1800,
        distance: 5.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await exerciseRepo.saveExercise(session);
      
      final stream = exerciseRepo.watchExerciseForDate('user1', DateTime.now());
      final sessions = await stream.first;
      
      expect(sessions.length, 1);
      expect(sessions.first.duration, 1800);
      expect(sessions.first.distance, 5.0);
    });
  });
}
