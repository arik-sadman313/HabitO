import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class HabitRepository {
  Stream<List<Habit>> watchHabits(String userId);
  Future<Habit?> getHabit(String id);
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
  
  Stream<List<HabitLog>> watchHabitLogs(String habitId);
  Stream<List<HabitLog>> watchHabitLogsForDate(String userId, DateTime date);
  Future<void> saveHabitLog(HabitLog log);

  Future<void> applyRemoteHabitChange(HabitDto dto, String operation);
  Future<void> applyRemoteHabitLogChange(HabitLogDto dto, String operation);
}

class HabitRepositoryImpl implements HabitRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  HabitRepositoryImpl(this._db);

  Habit _mapHabitToDomain(db.HabitsTableData data) {
    return Habit(
      id: data.id,
      userId: data.userId,
      trackerId: data.trackerId,
      title: data.title,
      description: data.description,
      frequency: data.frequency,
      targetValue: data.targetValue,
      startDate: data.startDate,
      endDate: data.endDate,
      isShared: data.isShared,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  HabitLog _mapLogToDomain(db.HabitLogsTableData data) {
    return HabitLog(
      id: data.id,
      habitId: data.habitId,
      userId: data.userId,
      date: data.date,
      isCompleted: data.isCompleted,
      progressValue: data.progressValue,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
    );
  }

  db.HabitsTableCompanion _mapHabitToCompanion(Habit habit) {
    return db.HabitsTableCompanion(
      id: Value(habit.id),
      userId: Value(habit.userId),
      trackerId: Value(habit.trackerId),
      title: Value(habit.title),
      description: Value(habit.description),
      frequency: Value(habit.frequency),
      targetValue: Value(habit.targetValue),
      startDate: Value(habit.startDate),
      endDate: Value(habit.endDate),
      isShared: Value(habit.isShared),
      createdAt: Value(habit.createdAt),
      updatedAt: Value(habit.updatedAt),
      syncStatus: Value(habit.syncStatus),
      isDeleted: Value(habit.isDeleted),
    );
  }

  db.HabitLogsTableCompanion _mapLogToCompanion(HabitLog log) {
    return db.HabitLogsTableCompanion(
      id: Value(log.id),
      habitId: Value(log.habitId),
      userId: Value(log.userId),
      date: Value(log.date),
      isCompleted: Value(log.isCompleted),
      progressValue: Value(log.progressValue),
      createdAt: Value(log.createdAt),
      updatedAt: Value(log.updatedAt),
      syncStatus: Value(log.syncStatus),
    );
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    final query = _db.select(_db.habitsTable)..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false));
    return query.watch().map((rows) => rows.map(_mapHabitToDomain).toList());
  }

  @override
  Future<Habit?> getHabit(String id) async {
    final query = _db.select(_db.habitsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapHabitToDomain(row) : null;
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final habitWithPending = Habit(
      id: habit.id,
      userId: habit.userId,
      trackerId: habit.trackerId,
      title: habit.title,
      description: habit.description,
      frequency: habit.frequency,
      targetValue: habit.targetValue,
      startDate: habit.startDate,
      endDate: habit.endDate,
      isShared: habit.isShared,
      createdAt: habit.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: habit.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.habitsTable).insertOnConflictUpdate(_mapHabitToCompanion(habitWithPending));

      final dto = HabitDto.fromDomain(habitWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'habit',
          entityId: habit.id,
          scopeType: 'user',
          scopeId: habit.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteHabit(String id) async {
    final habit = await getHabit(id);
    if (habit == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.habitsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.HabitsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'habit',
          entityId: id,
          scopeType: 'user',
          scopeId: habit.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Stream<List<HabitLog>> watchHabitLogs(String habitId) {
    final query = _db.select(_db.habitLogsTable)
      ..where((tbl) => tbl.habitId.equals(habitId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.date, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapLogToDomain).toList());
  }

  @override
  Stream<List<HabitLog>> watchHabitLogsForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = _db.select(_db.habitLogsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.date.isBiggerOrEqualValue(startOfDay) &
      tbl.date.isSmallerThanValue(endOfDay)
    );
    return query.watch().map((rows) => rows.map(_mapLogToDomain).toList());
  }

  @override
  Future<void> saveHabitLog(HabitLog log) async {
    final logWithPending = HabitLog(
      id: log.id,
      habitId: log.habitId,
      userId: log.userId,
      date: log.date,
      isCompleted: log.isCompleted,
      progressValue: log.progressValue,
      createdAt: log.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );

    await _db.transaction(() async {
      await _db.into(_db.habitLogsTable).insertOnConflictUpdate(_mapLogToCompanion(logWithPending));

      final dto = HabitLogDto.fromDomain(logWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'habit_log',
          entityId: log.id,
          scopeType: 'user',
          scopeId: log.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteHabitChange(HabitDto dto, String operation) async {
    if (operation == 'delete') {
      await (_db.update(_db.habitsTable)..where((tbl) => tbl.id.equals(dto.id))).write(
        db.HabitsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(dto.updatedAt),
          syncStatus: const Value(SyncStatus.synced),
        ),
      );
    } else {
      await _db.into(_db.habitsTable).insertOnConflictUpdate(
        _mapHabitToCompanion(dto.toDomain(SyncStatus.synced)),
      );
    }
  }

  @override
  Future<void> applyRemoteHabitLogChange(HabitLogDto dto, String operation) async {
    if (operation == 'delete') {
      // In flutter, HabitLog doesn't have isDeleted yet.
      // But we can delete the row or update it to be uncompleted if we want,
      // but if the server sends delete, we delete the local row.
      await (_db.delete(_db.habitLogsTable)..where((tbl) => tbl.id.equals(dto.id))).go();
    } else {
      await _db.into(_db.habitLogsTable).insertOnConflictUpdate(
        _mapLogToCompanion(dto.toDomain(SyncStatus.synced)),
      );
    }
  }
}

