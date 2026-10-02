import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:uuid/uuid.dart';

abstract class PersonalGoalRepository {
  Stream<List<PersonalGoal>> watchActiveGoals(String userId);
  Stream<List<PersonalGoal>> watchCompletedGoals(String userId);
  Stream<PersonalGoal?> watchGoal(String goalId);
  Future<PersonalGoal?> getGoal(String goalId);
  Future<void> createGoal(PersonalGoal goal);
  Future<void> updateGoal(PersonalGoal goal);
  Future<void> deleteGoal(String goalId);
}

class PersonalGoalRepositoryImpl implements PersonalGoalRepository {
  final db.AppDatabase _db;

  PersonalGoalRepositoryImpl(this._db);

  PersonalGoal _mapToDomain(db.PersonalGoalsTableData entry) {
    return PersonalGoal(
      id: entry.id,
      userId: entry.userId,
      title: entry.title,
      description: entry.description,
      goalType: GoalType.values.firstWhere((e) => e.name == entry.goalType),
      targetValue: entry.targetValue,
      currentValue: entry.currentValue,
      unit: entry.unit,
      startDate: entry.startDate,
      targetDate: entry.targetDate,
      status: entry.status,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
      isDeleted: entry.isDeleted,
    );
  }

  db.PersonalGoalsTableCompanion _mapToCompanion(PersonalGoal goal) {
    return db.PersonalGoalsTableCompanion(
      id: Value(goal.id),
      userId: Value(goal.userId),
      title: Value(goal.title),
      description: Value(goal.description),
      goalType: Value(goal.goalType.name),
      targetValue: Value(goal.targetValue),
      currentValue: Value(goal.currentValue),
      unit: Value(goal.unit),
      startDate: Value(goal.startDate),
      targetDate: Value(goal.targetDate),
      status: Value(goal.status),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
      syncStatus: Value(goal.syncStatus),
      isDeleted: Value(goal.isDeleted),
    );
  }

  @override
  Stream<List<PersonalGoal>> watchActiveGoals(String userId) {
    return (_db.select(_db.personalGoalsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.not() & t.status.equals(GoalStatus.active.index)))
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Stream<List<PersonalGoal>> watchCompletedGoals(String userId) {
    return (_db.select(_db.personalGoalsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.not() & t.status.equals(GoalStatus.completed.index)))
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Stream<PersonalGoal?> watchGoal(String goalId) {
    return (_db.select(_db.personalGoalsTable)..where((t) => t.id.equals(goalId))).watchSingleOrNull().map((row) {
      if (row == null) return null;
      return _mapToDomain(row);
    });
  }

  @override
  Future<PersonalGoal?> getGoal(String goalId) async {
    final row = await (_db.select(_db.personalGoalsTable)..where((t) => t.id.equals(goalId))).getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<void> createGoal(PersonalGoal goal) async {
    await _db.into(_db.personalGoalsTable).insert(_mapToCompanion(goal));
  }

  @override
  Future<void> updateGoal(PersonalGoal goal) async {
    await _db.update(_db.personalGoalsTable).replace(_mapToCompanion(goal));
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    // Soft delete
    final current = await getGoal(goalId);
    if (current != null) {
      await updateGoal(PersonalGoal(
        id: current.id,
        userId: current.userId,
        title: current.title,
        description: current.description,
        goalType: current.goalType,
        targetValue: current.targetValue,
        currentValue: current.currentValue,
        unit: current.unit,
        startDate: current.startDate,
        targetDate: current.targetDate,
        status: current.status,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
        isDeleted: true,
      ));
    }
  }
}
