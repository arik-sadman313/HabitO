import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';
import 'package:uuid/uuid.dart';

abstract class PersonalGoalRepository {
  Stream<List<PersonalGoal>> watchActiveGoals(String userId);
  Stream<List<PersonalGoal>> watchCompletedGoals(String userId);
  Stream<PersonalGoal?> watchGoal(String goalId);
  Future<PersonalGoal?> getGoal(String goalId);
  Future<void> createGoal(PersonalGoal goal);
  Future<void> updateGoal(PersonalGoal goal);
  Future<void> deleteGoal(String goalId);
  Future<void> applyRemotePersonalGoalChange(PersonalGoal goal);
  Future<void> applyRemotePersonalGoalDelete(String goalId, DateTime updatedAt);
}

class PersonalGoalRepositoryImpl implements PersonalGoalRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  PersonalGoalRepositoryImpl(this._db);

  PersonalGoal _mapToDomain(db.PersonalGoalsTableData entry) {
    return PersonalGoal(
      id: entry.id,
      userId: entry.userId,
      title: entry.title,
      description: entry.description,
      goalType: GoalType.values.firstWhere((e) => e.name == entry.goalType, orElse: () => GoalType.custom),
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
    final goalWithPending = PersonalGoal(
      id: goal.id,
      userId: goal.userId,
      title: goal.title,
      description: goal.description,
      goalType: goal.goalType,
      targetValue: goal.targetValue,
      currentValue: goal.currentValue,
      unit: goal.unit,
      startDate: goal.startDate,
      targetDate: goal.targetDate,
      status: goal.status,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingInsert,
      isDeleted: goal.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.personalGoalsTable).insert(_mapToCompanion(goalWithPending));

      final dto = PersonalGoalDto.fromDomain(goalWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'personal_goal',
          entityId: goalWithPending.id,
          scopeType: 'user',
          scopeId: goalWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> updateGoal(PersonalGoal goal) async {
    final goalWithPending = PersonalGoal(
      id: goal.id,
      userId: goal.userId,
      title: goal.title,
      description: goal.description,
      goalType: goal.goalType,
      targetValue: goal.targetValue,
      currentValue: goal.currentValue,
      unit: goal.unit,
      startDate: goal.startDate,
      targetDate: goal.targetDate,
      status: goal.status,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: goal.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.personalGoalsTable).insertOnConflictUpdate(_mapToCompanion(goalWithPending));

      final dto = PersonalGoalDto.fromDomain(goalWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'personal_goal',
          entityId: goalWithPending.id,
          scopeType: 'user',
          scopeId: goalWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final current = await getGoal(goalId);
    if (current == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.personalGoalsTable)..where((t) => t.id.equals(goalId))).write(
        db.PersonalGoalsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'personal_goal',
          entityId: goalId,
          scopeType: 'user',
          scopeId: current.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemotePersonalGoalChange(PersonalGoal goal) async {
    await _db.into(_db.personalGoalsTable).insertOnConflictUpdate(_mapToCompanion(goal));
  }

  @override
  Future<void> applyRemotePersonalGoalDelete(String goalId, DateTime updatedAt) async {
    await (_db.update(_db.personalGoalsTable)..where((t) => t.id.equals(goalId))).write(
      db.PersonalGoalsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
