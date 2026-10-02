import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class UsRepository {
  Future<Couple?> getCouple(String coupleId);
  Future<Couple?> getCurrentCouple(String userId);
  Future<User?> getPartner(String currentUserId, String coupleId);
  
  Stream<List<SharedGoal>> watchSharedGoals(String coupleId);
  Future<void> saveSharedGoal(SharedGoal goal);
  Future<void> deleteSharedGoal(String id);
  Future<void> applyRemoteSharedGoalChange(SharedGoal goal);
  Future<void> applyRemoteSharedGoalDelete(String id, DateTime updatedAt);

  Stream<List<SharedHabit>> watchSharedHabits(String coupleId);
  Future<void> saveSharedHabit(SharedHabit habit);
  Future<void> deleteSharedHabit(String id);
  Future<void> applyRemoteSharedHabitChange(SharedHabit habit);
  Future<void> applyRemoteSharedHabitDelete(String id, DateTime updatedAt);
  
  Stream<List<Memory>> watchMemories(String coupleId);
  Future<void> saveMemory(Memory memory);
  Future<void> deleteMemory(String id);
  Future<void> applyRemoteMemoryChange(Memory memory);
  Future<void> applyRemoteMemoryDelete(String id, DateTime updatedAt);
  
  Stream<List<SharedActivity>> watchSharedActivities(String coupleId, DateTime date);
  Future<void> saveSharedActivity(SharedActivity activity);
  Future<void> deleteSharedActivity(String id);
  Future<void> applyRemoteSharedActivityChange(SharedActivity activity);
  Future<void> applyRemoteSharedActivityDelete(String id, DateTime updatedAt);
}

class UsRepositoryImpl implements UsRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  UsRepositoryImpl(this._db);

  @override
  Future<Couple?> getCurrentCouple(String userId) async {
    final record = await (_db.select(_db.couplesTable)..where((tbl) => tbl.userAId.equals(userId) | tbl.userBId.equals(userId))).getSingleOrNull();
    if (record == null) return null;
    return Couple(
      id: record.id,
      userAId: record.userAId,
      userBId: record.userBId,
      status: record.status,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      syncStatus: record.syncStatus,
    );
  }

  @override
  Future<Couple?> getCouple(String coupleId) async {
    final record = await (_db.select(_db.couplesTable)..where((tbl) => tbl.id.equals(coupleId))).getSingleOrNull();
    if (record == null) return null;
    return Couple(
      id: record.id,
      userAId: record.userAId,
      userBId: record.userBId,
      status: record.status,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      syncStatus: record.syncStatus,
    );
  }

  @override
  Future<User?> getPartner(String currentUserId, String coupleId) async {
    final couple = await getCouple(coupleId);
    if (couple == null) return null;
    
    final partnerId = couple.userAId == currentUserId ? couple.userBId : couple.userAId;
    final record = await (_db.select(_db.usersTable)..where((tbl) => tbl.id.equals(partnerId))).getSingleOrNull();
    if (record == null) return null;
    
    return User(
      id: record.id,
      email: record.email,
      name: record.name,
      timezone: record.timezone,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      syncStatus: record.syncStatus,
    );
  }

  SharedGoal _mapSharedGoal(db.SharedGoalsTableData data) {
    return SharedGoal(
      id: data.id,
      coupleId: data.coupleId,
      title: data.title,
      description: data.description,
      target: data.target,
      currentProgress: data.currentProgress,
      unit: data.unit,
      deadline: data.deadline,
      isCompleted: data.isCompleted,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  SharedHabit _mapSharedHabit(db.SharedHabitsTableData data) {
    return SharedHabit(
      id: data.id,
      coupleId: data.coupleId,
      title: data.title,
      frequency: data.frequency,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  Memory _mapMemory(db.MemoriesTableData data) {
    return Memory(
      id: data.id,
      coupleId: data.coupleId,
      title: data.title,
      description: data.description,
      date: data.date,
      mediaUrl: data.mediaUrl,
      tags: data.tags,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }
  
  SharedActivity _mapSharedActivity(db.SharedActivitiesTableData data) {
    return SharedActivity(
      id: data.id,
      coupleId: data.coupleId,
      title: data.title,
      notes: data.notes,
      startTime: data.startTime,
      endTime: data.endTime,
      isCompleted: data.isCompleted,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<List<SharedGoal>> watchSharedGoals(String coupleId) {
    final query = _db.select(_db.sharedGoalsTable)..where((tbl) => tbl.coupleId.equals(coupleId) & tbl.isDeleted.equals(false));
    return query.watch().map((rows) => rows.map(_mapSharedGoal).toList());
  }

  @override
  Future<void> saveSharedGoal(SharedGoal goal) async {
    final goalWithPending = SharedGoal(
      id: goal.id,
      coupleId: goal.coupleId,
      title: goal.title,
      description: goal.description,
      target: goal.target,
      currentProgress: goal.currentProgress,
      unit: goal.unit,
      deadline: goal.deadline,
      isCompleted: goal.isCompleted,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: goal.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.sharedGoalsTable).insertOnConflictUpdate(db.SharedGoalsTableCompanion(
        id: Value(goalWithPending.id),
        coupleId: Value(goalWithPending.coupleId),
        title: Value(goalWithPending.title),
        description: Value(goalWithPending.description),
        target: Value(goalWithPending.target),
        currentProgress: Value(goalWithPending.currentProgress),
        unit: Value(goalWithPending.unit),
        deadline: Value(goalWithPending.deadline),
        isCompleted: Value(goalWithPending.isCompleted),
        createdAt: Value(goalWithPending.createdAt),
        updatedAt: Value(goalWithPending.updatedAt),
        syncStatus: Value(goalWithPending.syncStatus),
        isDeleted: Value(goalWithPending.isDeleted),
      ));

      final dto = SharedGoalDto.fromDomain(goalWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_goal',
          entityId: goalWithPending.id,
          scopeType: 'couple',
          scopeId: goalWithPending.coupleId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteSharedGoal(String id) async {
    final query = _db.select(_db.sharedGoalsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.sharedGoalsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.SharedGoalsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_goal',
          entityId: id,
          scopeType: 'couple',
          scopeId: row.coupleId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteSharedGoalChange(SharedGoal goal) async {
    await _db.into(_db.sharedGoalsTable).insertOnConflictUpdate(db.SharedGoalsTableCompanion(
      id: Value(goal.id),
      coupleId: Value(goal.coupleId),
      title: Value(goal.title),
      description: Value(goal.description),
      target: Value(goal.target),
      currentProgress: Value(goal.currentProgress),
      unit: Value(goal.unit),
      deadline: Value(goal.deadline),
      isCompleted: Value(goal.isCompleted),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
      syncStatus: const Value(SyncStatus.synced),
      isDeleted: Value(goal.isDeleted),
    ));
  }

  @override
  Future<void> applyRemoteSharedGoalDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.sharedGoalsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.SharedGoalsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  @override
  Stream<List<SharedHabit>> watchSharedHabits(String coupleId) {
    final query = _db.select(_db.sharedHabitsTable)..where((tbl) => tbl.coupleId.equals(coupleId) & tbl.isDeleted.equals(false));
    return query.watch().map((rows) => rows.map(_mapSharedHabit).toList());
  }

  @override
  Future<void> saveSharedHabit(SharedHabit habit) async {
    final habitWithPending = SharedHabit(
      id: habit.id,
      coupleId: habit.coupleId,
      title: habit.title,
      frequency: habit.frequency,
      createdAt: habit.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: habit.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.sharedHabitsTable).insertOnConflictUpdate(db.SharedHabitsTableCompanion(
        id: Value(habitWithPending.id),
        coupleId: Value(habitWithPending.coupleId),
        title: Value(habitWithPending.title),
        frequency: Value(habitWithPending.frequency),
        createdAt: Value(habitWithPending.createdAt),
        updatedAt: Value(habitWithPending.updatedAt),
        syncStatus: Value(habitWithPending.syncStatus),
        isDeleted: Value(habitWithPending.isDeleted),
      ));

      final dto = SharedHabitDto.fromDomain(habitWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_habit',
          entityId: habitWithPending.id,
          scopeType: 'couple',
          scopeId: habitWithPending.coupleId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteSharedHabit(String id) async {
    final query = _db.select(_db.sharedHabitsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.sharedHabitsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.SharedHabitsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_habit',
          entityId: id,
          scopeType: 'couple',
          scopeId: row.coupleId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteSharedHabitChange(SharedHabit habit) async {
    await _db.into(_db.sharedHabitsTable).insertOnConflictUpdate(db.SharedHabitsTableCompanion(
      id: Value(habit.id),
      coupleId: Value(habit.coupleId),
      title: Value(habit.title),
      frequency: Value(habit.frequency),
      createdAt: Value(habit.createdAt),
      updatedAt: Value(habit.updatedAt),
      syncStatus: const Value(SyncStatus.synced),
      isDeleted: Value(habit.isDeleted),
    ));
  }

  @override
  Future<void> applyRemoteSharedHabitDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.sharedHabitsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.SharedHabitsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  @override
  Stream<List<Memory>> watchMemories(String coupleId) {
    final query = _db.select(_db.memoriesTable)..where((tbl) => tbl.coupleId.equals(coupleId) & tbl.isDeleted.equals(false))..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapMemory).toList());
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final memoryWithPending = Memory(
      id: memory.id,
      coupleId: memory.coupleId,
      title: memory.title,
      description: memory.description,
      date: memory.date,
      mediaUrl: memory.mediaUrl,
      tags: memory.tags,
      createdAt: memory.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: memory.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.memoriesTable).insertOnConflictUpdate(db.MemoriesTableCompanion(
        id: Value(memoryWithPending.id),
        coupleId: Value(memoryWithPending.coupleId),
        title: Value(memoryWithPending.title),
        description: Value(memoryWithPending.description),
        date: Value(memoryWithPending.date),
        mediaUrl: Value(memoryWithPending.mediaUrl),
        tags: Value(memoryWithPending.tags),
        createdAt: Value(memoryWithPending.createdAt),
        updatedAt: Value(memoryWithPending.updatedAt),
        syncStatus: Value(memoryWithPending.syncStatus),
        isDeleted: Value(memoryWithPending.isDeleted),
      ));

      final dto = MemoryDto.fromDomain(memoryWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'memory',
          entityId: memoryWithPending.id,
          scopeType: 'couple',
          scopeId: memoryWithPending.coupleId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteMemory(String id) async {
    final query = _db.select(_db.memoriesTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.memoriesTable)..where((tbl) => tbl.id.equals(id))).write(
        db.MemoriesTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'memory',
          entityId: id,
          scopeType: 'couple',
          scopeId: row.coupleId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteMemoryChange(Memory memory) async {
    await _db.into(_db.memoriesTable).insertOnConflictUpdate(db.MemoriesTableCompanion(
      id: Value(memory.id),
      coupleId: Value(memory.coupleId),
      title: Value(memory.title),
      description: Value(memory.description),
      date: Value(memory.date),
      mediaUrl: Value(memory.mediaUrl),
      tags: Value(memory.tags),
      createdAt: Value(memory.createdAt),
      updatedAt: Value(memory.updatedAt),
      syncStatus: const Value(SyncStatus.synced),
      isDeleted: Value(memory.isDeleted),
    ));
  }

  @override
  Future<void> applyRemoteMemoryDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.memoriesTable)..where((tbl) => tbl.id.equals(id))).write(
      db.MemoriesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  @override
  Stream<List<SharedActivity>> watchSharedActivities(String coupleId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final query = _db.select(_db.sharedActivitiesTable)..where((tbl) => 
      tbl.coupleId.equals(coupleId) & 
      tbl.isDeleted.equals(false) &
      tbl.startTime.isBiggerOrEqualValue(startOfDay) &
      tbl.startTime.isSmallerThanValue(endOfDay)
    );
    return query.watch().map((rows) => rows.map(_mapSharedActivity).toList());
  }

  @override
  Future<void> saveSharedActivity(SharedActivity activity) async {
    final activityWithPending = SharedActivity(
      id: activity.id,
      coupleId: activity.coupleId,
      title: activity.title,
      notes: activity.notes,
      startTime: activity.startTime,
      endTime: activity.endTime,
      isCompleted: activity.isCompleted,
      createdAt: activity.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: activity.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.sharedActivitiesTable).insertOnConflictUpdate(db.SharedActivitiesTableCompanion(
        id: Value(activityWithPending.id),
        coupleId: Value(activityWithPending.coupleId),
        title: Value(activityWithPending.title),
        notes: Value(activityWithPending.notes),
        startTime: Value(activityWithPending.startTime),
        endTime: Value(activityWithPending.endTime),
        isCompleted: Value(activityWithPending.isCompleted),
        createdAt: Value(activityWithPending.createdAt),
        updatedAt: Value(activityWithPending.updatedAt),
        syncStatus: Value(activityWithPending.syncStatus),
        isDeleted: Value(activityWithPending.isDeleted),
      ));

      final dto = SharedActivityDto.fromDomain(activityWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_activity',
          entityId: activityWithPending.id,
          scopeType: 'couple',
          scopeId: activityWithPending.coupleId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteSharedActivity(String id) async {
    final query = _db.select(_db.sharedActivitiesTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.sharedActivitiesTable)..where((tbl) => tbl.id.equals(id))).write(
        db.SharedActivitiesTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'shared_activity',
          entityId: id,
          scopeType: 'couple',
          scopeId: row.coupleId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteSharedActivityChange(SharedActivity activity) async {
    await _db.into(_db.sharedActivitiesTable).insertOnConflictUpdate(db.SharedActivitiesTableCompanion(
      id: Value(activity.id),
      coupleId: Value(activity.coupleId),
      title: Value(activity.title),
      notes: Value(activity.notes),
      startTime: Value(activity.startTime),
      endTime: Value(activity.endTime),
      isCompleted: Value(activity.isCompleted),
      createdAt: Value(activity.createdAt),
      updatedAt: Value(activity.updatedAt),
      syncStatus: const Value(SyncStatus.synced),
      isDeleted: Value(activity.isDeleted),
    ));
  }

  @override
  Future<void> applyRemoteSharedActivityDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.sharedActivitiesTable)..where((tbl) => tbl.id.equals(id))).write(
      db.SharedActivitiesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}

