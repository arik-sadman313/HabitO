import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';

abstract class UsRepository {
  Future<Couple?> getCouple(String coupleId);
  Future<Couple?> getCurrentCouple(String userId);
  Future<User?> getPartner(String currentUserId, String coupleId);
  
  Stream<List<SharedGoal>> watchSharedGoals(String coupleId);
  Future<void> saveSharedGoal(SharedGoal goal);
  
  Stream<List<Memory>> watchMemories(String coupleId);
  Future<void> saveMemory(Memory memory);
  
  Stream<List<SharedActivity>> watchSharedActivities(String coupleId, DateTime date);
  Future<void> saveSharedActivity(SharedActivity activity);
}

class UsRepositoryImpl implements UsRepository {
  final db.AppDatabase _db;

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
      syncStatus: Value(goal.syncStatus),
      isDeleted: Value(goal.isDeleted),
    ));
  }

  @override
  Stream<List<Memory>> watchMemories(String coupleId) {
    final query = _db.select(_db.memoriesTable)..where((tbl) => tbl.coupleId.equals(coupleId) & tbl.isDeleted.equals(false))..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapMemory).toList());
  }

  @override
  Future<void> saveMemory(Memory memory) async {
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
      syncStatus: Value(memory.syncStatus),
      isDeleted: Value(memory.isDeleted),
    ));
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
      syncStatus: Value(activity.syncStatus),
      isDeleted: Value(activity.isDeleted),
    ));
  }
}
