import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class MealRepository {
  Stream<List<Meal>> watchMealsForDate(String userId, DateTime date);
  Future<void> saveMeal(Meal meal);
  Future<void> saveMealItem(MealItem item);
  Future<void> deleteMeal(String id);
  Future<void> applyRemoteMealChange(Meal meal);
  Future<void> applyRemoteMealItemChange(MealItem item);
  Future<void> applyRemoteMealDelete(String id, DateTime updatedAt);
  Future<void> applyRemoteMealItemDelete(String id);
}

class MealRepositoryImpl implements MealRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  MealRepositoryImpl(this._db);

  Meal _mapMeal(db.MealsTableData data, List<MealItem> items) {
    return Meal(
      id: data.id,
      userId: data.userId,
      mealType: data.mealType,
      recordedAt: data.recordedAt,
      notes: data.notes,
      photoUrl: data.photoUrl,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
      items: items,
    );
  }

  MealItem _mapItem(db.MealItemsTableData data) {
    return MealItem(
      id: data.id,
      mealId: data.mealId,
      name: data.name,
      quantity: data.quantity,
      unit: data.unit,
      calories: data.calories,
      protein: data.protein,
      carbs: data.carbs,
      fat: data.fat,
      notes: data.notes,
    );
  }

  @override
  Stream<List<Meal>> watchMealsForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final mealQuery = _db.select(_db.mealsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.recordedAt.isBiggerOrEqualValue(startOfDay) &
      tbl.recordedAt.isSmallerThanValue(endOfDay)
    )..orderBy([(t) => OrderingTerm(expression: t.recordedAt)]);

    return mealQuery.watch().asyncMap((mealRows) async {
      final meals = <Meal>[];
      for (final row in mealRows) {
        final itemQuery = _db.select(_db.mealItemsTable)..where((tbl) => tbl.mealId.equals(row.id));
        final items = (await itemQuery.get()).map(_mapItem).toList();
        meals.add(_mapMeal(row, items));
      }
      return meals;
    });
  }

  @override
  Future<void> saveMeal(Meal meal) async {
    final mealWithPending = Meal(
      id: meal.id,
      userId: meal.userId,
      mealType: meal.mealType,
      recordedAt: meal.recordedAt,
      notes: meal.notes,
      photoUrl: meal.photoUrl,
      createdAt: meal.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: meal.isDeleted,
      items: meal.items,
    );

    await _db.transaction(() async {
      await _db.into(_db.mealsTable).insertOnConflictUpdate(
        db.MealsTableCompanion(
          id: Value(mealWithPending.id),
          userId: Value(mealWithPending.userId),
          mealType: Value(mealWithPending.mealType),
          recordedAt: Value(mealWithPending.recordedAt),
          notes: Value(mealWithPending.notes),
          photoUrl: Value(mealWithPending.photoUrl),
          createdAt: Value(mealWithPending.createdAt),
          updatedAt: Value(mealWithPending.updatedAt),
          syncStatus: Value(mealWithPending.syncStatus),
          isDeleted: Value(mealWithPending.isDeleted),
        ),
      );

      final dto = MealDto.fromDomain(mealWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'meal',
          entityId: mealWithPending.id,
          scopeType: 'user',
          scopeId: mealWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> saveMealItem(MealItem item) async {
    await _db.transaction(() async {
      await _db.into(_db.mealItemsTable).insertOnConflictUpdate(
        db.MealItemsTableCompanion(
          id: Value(item.id),
          mealId: Value(item.mealId),
          name: Value(item.name),
          quantity: Value(item.quantity),
          unit: Value(item.unit),
          calories: Value(item.calories),
          protein: Value(item.protein),
          carbs: Value(item.carbs),
          fat: Value(item.fat),
          notes: Value(item.notes),
        ),
      );

      // MealItem needs the parent meal's userId for scope
      final mealQuery = _db.select(_db.mealsTable)..where((tbl) => tbl.id.equals(item.mealId));
      final mealRow = await mealQuery.getSingleOrNull();
      if (mealRow != null) {
        final dto = MealItemDto.fromDomain(item);
        await _db.into(_db.syncQueueTable).insert(
          db.SyncQueueTableCompanion.insert(
            id: _uuid.v4(),
            entityType: 'meal_item',
            entityId: item.id,
            scopeType: 'user',
            scopeId: mealRow.userId,
            operation: 'upsert',
            payload: Value(jsonEncode(dto.toJson())),
            createdAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteMeal(String id) async {
    final query = _db.select(_db.mealsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.mealsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.MealsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'meal',
          entityId: id,
          scopeType: 'user',
          scopeId: row.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteMealChange(Meal meal) async {
    await _db.into(_db.mealsTable).insertOnConflictUpdate(
      db.MealsTableCompanion(
        id: Value(meal.id),
        userId: Value(meal.userId),
        mealType: Value(meal.mealType),
        recordedAt: Value(meal.recordedAt),
        notes: Value(meal.notes),
        photoUrl: Value(meal.photoUrl),
        createdAt: Value(meal.createdAt),
        updatedAt: Value(meal.updatedAt),
        syncStatus: Value(meal.syncStatus),
        isDeleted: Value(meal.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteMealItemChange(MealItem item) async {
    await _db.into(_db.mealItemsTable).insertOnConflictUpdate(
      db.MealItemsTableCompanion(
        id: Value(item.id),
        mealId: Value(item.mealId),
        name: Value(item.name),
        quantity: Value(item.quantity),
        unit: Value(item.unit),
        calories: Value(item.calories),
        protein: Value(item.protein),
        carbs: Value(item.carbs),
        fat: Value(item.fat),
        notes: Value(item.notes),
      ),
    );
  }

  @override
  Future<void> applyRemoteMealDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.mealsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.MealsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  @override
  Future<void> applyRemoteMealItemDelete(String id) async {
    await (_db.delete(_db.mealItemsTable)..where((tbl) => tbl.id.equals(id))).go();
  }
}

abstract class SleepRepository {
  Stream<List<SleepRecord>> watchSleepForDate(String userId, DateTime date);
  Stream<List<SleepRecord>> watchSleepForWeek(String userId, DateTime endOfWeek);
  Future<void> saveSleep(SleepRecord sleep);
  Future<void> deleteSleep(String id);
  Future<void> applyRemoteSleepChange(SleepRecord sleep);
  Future<void> applyRemoteSleepDelete(String id, DateTime updatedAt);
}

class SleepRepositoryImpl implements SleepRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  SleepRepositoryImpl(this._db);

  SleepRecord _mapSleep(db.SleepRecordsTableData data) {
    return SleepRecord(
      id: data.id,
      userId: data.userId,
      sleepStart: data.sleepStart,
      wakeTime: data.wakeTime,
      duration: data.duration,
      quality: data.quality,
      notes: data.notes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<List<SleepRecord>> watchSleepForDate(String userId, DateTime date) {
    // "Logical Day" assignment based on wakeTime
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.sleepRecordsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.wakeTime.isBiggerOrEqualValue(startOfDay) &
      tbl.wakeTime.isSmallerThanValue(endOfDay)
    )..orderBy([(t) => OrderingTerm(expression: t.wakeTime, mode: OrderingMode.desc)]);
    
    return query.watch().map((rows) => rows.map(_mapSleep).toList());
  }

  @override
  Stream<List<SleepRecord>> watchSleepForWeek(String userId, DateTime endOfWeek) {
    final startOfWeek = endOfWeek.subtract(const Duration(days: 7));
    final query = _db.select(_db.sleepRecordsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.wakeTime.isBiggerOrEqualValue(startOfWeek) &
      tbl.wakeTime.isSmallerThanValue(endOfWeek)
    );
    return query.watch().map((rows) => rows.map(_mapSleep).toList());
  }

  @override
  Future<void> saveSleep(SleepRecord sleep) async {
    final sleepWithPending = SleepRecord(
      id: sleep.id,
      userId: sleep.userId,
      sleepStart: sleep.sleepStart,
      wakeTime: sleep.wakeTime,
      duration: sleep.duration,
      quality: sleep.quality,
      notes: sleep.notes,
      createdAt: sleep.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: sleep.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.sleepRecordsTable).insertOnConflictUpdate(
        db.SleepRecordsTableCompanion(
          id: Value(sleepWithPending.id),
          userId: Value(sleepWithPending.userId),
          sleepStart: Value(sleepWithPending.sleepStart),
          wakeTime: Value(sleepWithPending.wakeTime),
          duration: Value(sleepWithPending.duration),
          quality: Value(sleepWithPending.quality),
          notes: Value(sleepWithPending.notes),
          createdAt: Value(sleepWithPending.createdAt),
          updatedAt: Value(sleepWithPending.updatedAt),
          syncStatus: Value(sleepWithPending.syncStatus),
          isDeleted: Value(sleepWithPending.isDeleted),
        ),
      );

      final dto = SleepRecordDto.fromDomain(sleepWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'sleep_record',
          entityId: sleepWithPending.id,
          scopeType: 'user',
          scopeId: sleepWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteSleep(String id) async {
    final query = _db.select(_db.sleepRecordsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.sleepRecordsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.SleepRecordsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'sleep_record',
          entityId: id,
          scopeType: 'user',
          scopeId: row.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteSleepChange(SleepRecord sleep) async {
    await _db.into(_db.sleepRecordsTable).insertOnConflictUpdate(
      db.SleepRecordsTableCompanion(
        id: Value(sleep.id),
        userId: Value(sleep.userId),
        sleepStart: Value(sleep.sleepStart),
        wakeTime: Value(sleep.wakeTime),
        duration: Value(sleep.duration),
        quality: Value(sleep.quality),
        notes: Value(sleep.notes),
        createdAt: Value(sleep.createdAt),
        updatedAt: Value(sleep.updatedAt),
        syncStatus: Value(sleep.syncStatus),
        isDeleted: Value(sleep.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteSleepDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.sleepRecordsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.SleepRecordsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}

abstract class ExerciseRepository {
  Stream<List<ExerciseSession>> watchExerciseForDate(String userId, DateTime date);
  Stream<List<ExerciseSession>> watchExerciseForWeek(String userId, DateTime endOfWeek);
  Future<void> saveExercise(ExerciseSession exercise);
  Future<void> deleteExercise(String id);
  Future<void> applyRemoteExerciseChange(ExerciseSession exercise);
  Future<void> applyRemoteExerciseDelete(String id, DateTime updatedAt);
}

class ExerciseRepositoryImpl implements ExerciseRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  ExerciseRepositoryImpl(this._db);

  ExerciseSession _mapExercise(db.ExerciseSessionsTableData data) {
    return ExerciseSession(
      id: data.id,
      userId: data.userId,
      exerciseType: data.exerciseType,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      duration: data.duration,
      distance: data.distance,
      calories: data.calories,
      notes: data.notes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<List<ExerciseSession>> watchExerciseForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.exerciseSessionsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.startedAt.isBiggerOrEqualValue(startOfDay) &
      tbl.startedAt.isSmallerThanValue(endOfDay)
    )..orderBy([(t) => OrderingTerm(expression: t.startedAt, mode: OrderingMode.desc)]);
    
    return query.watch().map((rows) => rows.map(_mapExercise).toList());
  }

  @override
  Stream<List<ExerciseSession>> watchExerciseForWeek(String userId, DateTime endOfWeek) {
    final startOfWeek = endOfWeek.subtract(const Duration(days: 7));
    final query = _db.select(_db.exerciseSessionsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.startedAt.isBiggerOrEqualValue(startOfWeek) &
      tbl.startedAt.isSmallerThanValue(endOfWeek)
    );
    return query.watch().map((rows) => rows.map(_mapExercise).toList());
  }

  @override
  Future<void> saveExercise(ExerciseSession exercise) async {
    final exerciseWithPending = ExerciseSession(
      id: exercise.id,
      userId: exercise.userId,
      exerciseType: exercise.exerciseType,
      startedAt: exercise.startedAt,
      endedAt: exercise.endedAt,
      duration: exercise.duration,
      distance: exercise.distance,
      calories: exercise.calories,
      notes: exercise.notes,
      createdAt: exercise.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: exercise.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.exerciseSessionsTable).insertOnConflictUpdate(
        db.ExerciseSessionsTableCompanion(
          id: Value(exerciseWithPending.id),
          userId: Value(exerciseWithPending.userId),
          exerciseType: Value(exerciseWithPending.exerciseType),
          startedAt: Value(exerciseWithPending.startedAt),
          endedAt: Value(exerciseWithPending.endedAt),
          duration: Value(exerciseWithPending.duration),
          distance: Value(exerciseWithPending.distance),
          calories: Value(exerciseWithPending.calories),
          notes: Value(exerciseWithPending.notes),
          createdAt: Value(exerciseWithPending.createdAt),
          updatedAt: Value(exerciseWithPending.updatedAt),
          syncStatus: Value(exerciseWithPending.syncStatus),
          isDeleted: Value(exerciseWithPending.isDeleted),
        ),
      );

      final dto = ExerciseSessionDto.fromDomain(exerciseWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'exercise_session',
          entityId: exerciseWithPending.id,
          scopeType: 'user',
          scopeId: exerciseWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteExercise(String id) async {
    final query = _db.select(_db.exerciseSessionsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.exerciseSessionsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.ExerciseSessionsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'exercise_session',
          entityId: id,
          scopeType: 'user',
          scopeId: row.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteExerciseChange(ExerciseSession exercise) async {
    await _db.into(_db.exerciseSessionsTable).insertOnConflictUpdate(
      db.ExerciseSessionsTableCompanion(
        id: Value(exercise.id),
        userId: Value(exercise.userId),
        exerciseType: Value(exercise.exerciseType),
        startedAt: Value(exercise.startedAt),
        endedAt: Value(exercise.endedAt),
        duration: Value(exercise.duration),
        distance: Value(exercise.distance),
        calories: Value(exercise.calories),
        notes: Value(exercise.notes),
        createdAt: Value(exercise.createdAt),
        updatedAt: Value(exercise.updatedAt),
        syncStatus: Value(exercise.syncStatus),
        isDeleted: Value(exercise.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteExerciseDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.exerciseSessionsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.ExerciseSessionsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
