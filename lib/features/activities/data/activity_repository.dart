import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class ActivityRepository {
  Stream<List<Activity>> watchActivitiesForDate(String userId, DateTime date);
  Future<Activity?> getActivity(String id);
  Future<void> saveActivity(Activity activity);
  Future<void> deleteActivity(String id);
  Future<void> toggleActivityCompletion(String id, bool isCompleted);
  Future<void> applyRemoteChange(ActivityDto dto, String operation);
}

class ActivityRepositoryImpl implements ActivityRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  ActivityRepositoryImpl(this._db);

  Activity _mapToDomain(db.ActivitiesTableData data) {
    return Activity(
      id: data.id,
      userId: data.userId,
      title: data.title,
      notes: data.notes,
      scheduledStart: data.scheduledStart,
      scheduledEnd: data.scheduledEnd,
      isCompleted: data.isCompleted,
      category: data.category,
      isShared: data.isShared,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  db.ActivitiesTableCompanion _mapToCompanion(Activity activity) {
    return db.ActivitiesTableCompanion(
      id: Value(activity.id),
      userId: Value(activity.userId),
      title: Value(activity.title),
      notes: Value(activity.notes),
      scheduledStart: Value(activity.scheduledStart),
      scheduledEnd: Value(activity.scheduledEnd),
      isCompleted: Value(activity.isCompleted),
      category: Value(activity.category),
      isShared: Value(activity.isShared),
      createdAt: Value(activity.createdAt),
      updatedAt: Value(activity.updatedAt),
      syncStatus: Value(activity.syncStatus),
      isDeleted: Value(activity.isDeleted),
    );
  }

  @override
  Stream<List<Activity>> watchActivitiesForDate(String userId, DateTime date) {
    // start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    // end of day (exclusive)
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.activitiesTable)..where((tbl) {
      return tbl.userId.equals(userId) &
          tbl.isDeleted.equals(false) &
          tbl.scheduledStart.isBiggerOrEqualValue(startOfDay) &
          tbl.scheduledStart.isSmallerThanValue(endOfDay);
    })..orderBy([(tbl) => OrderingTerm(expression: tbl.scheduledStart, mode: OrderingMode.asc)]);

    return query.watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<Activity?> getActivity(String id) async {
    final query = _db.select(_db.activitiesTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    final activityWithPending = Activity(
      id: activity.id,
      userId: activity.userId,
      title: activity.title,
      notes: activity.notes,
      scheduledStart: activity.scheduledStart,
      scheduledEnd: activity.scheduledEnd,
      isCompleted: activity.isCompleted,
      category: activity.category,
      isShared: activity.isShared,
      createdAt: activity.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: activity.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.activitiesTable).insertOnConflictUpdate(_mapToCompanion(activityWithPending));

      final dto = ActivityDto.fromDomain(activityWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'activity',
          entityId: activity.id,
          scopeType: 'user',
          scopeId: activity.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteActivity(String id) async {
    final activity = await getActivity(id);
    if (activity == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.activitiesTable)..where((tbl) => tbl.id.equals(id))).write(
        db.ActivitiesTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'activity',
          entityId: id,
          scopeType: 'user',
          scopeId: activity.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> toggleActivityCompletion(String id, bool isCompleted) async {
    final activity = await getActivity(id);
    if (activity == null) return;

    final updated = Activity(
      id: activity.id,
      userId: activity.userId,
      title: activity.title,
      notes: activity.notes,
      scheduledStart: activity.scheduledStart,
      scheduledEnd: activity.scheduledEnd,
      isCompleted: isCompleted,
      category: activity.category,
      isShared: activity.isShared,
      createdAt: activity.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: activity.isDeleted,
    );

    await saveActivity(updated);
  }

  @override
  Future<void> applyRemoteChange(ActivityDto dto, String operation) async {
    if (operation == 'delete') {
      await (_db.update(_db.activitiesTable)..where((tbl) => tbl.id.equals(dto.id))).write(
        db.ActivitiesTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(dto.updatedAt),
          syncStatus: const Value(SyncStatus.synced),
        ),
      );
    } else {
      await _db.into(_db.activitiesTable).insertOnConflictUpdate(
        _mapToCompanion(dto.toDomain(SyncStatus.synced)),
      );
    }
  }
}
