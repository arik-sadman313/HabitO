import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class TrackerRepository {
  Stream<List<Tracker>> watchTrackers(String userId);
  Future<Tracker?> getTracker(String id);
  Future<void> saveTracker(Tracker tracker);
  Future<void> deleteTracker(String id);
  
  Stream<List<TrackerLog>> watchLogsForTracker(String trackerId);
  Stream<List<TrackerLog>> watchLogsForDate(String userId, DateTime date);
  Future<TrackerLog?> getTrackerLog(String id);
  Future<void> saveTrackerLog(TrackerLog log);
  Future<void> deleteTrackerLog(String id);

  Future<void> applyRemoteTrackerChange(TrackerDto dto, String operation);
  Future<void> applyRemoteTrackerLogChange(TrackerLogDto dto, String operation);
}

class TrackerRepositoryImpl implements TrackerRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  TrackerRepositoryImpl(this._db);

  Tracker _mapTrackerToDomain(db.TrackersTableData data) {
    return Tracker(
      id: data.id,
      userId: data.userId,
      name: data.name,
      icon: data.icon,
      color: data.color,
      type: data.type,
      unit: data.unit,
      isShared: data.isShared,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  TrackerLog _mapLogToDomain(db.TrackerLogsTableData data) {
    return TrackerLog(
      id: data.id,
      trackerId: data.trackerId,
      userId: data.userId,
      timestamp: data.timestamp,
      valueNum: data.valueNum,
      valueText: data.valueText,
      notes: data.notes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  db.TrackersTableCompanion _mapTrackerToCompanion(Tracker tracker) {
    return db.TrackersTableCompanion(
      id: Value(tracker.id),
      userId: Value(tracker.userId),
      name: Value(tracker.name),
      icon: Value(tracker.icon),
      color: Value(tracker.color),
      type: Value(tracker.type),
      unit: Value(tracker.unit),
      isShared: Value(tracker.isShared),
      createdAt: Value(tracker.createdAt),
      updatedAt: Value(tracker.updatedAt),
      syncStatus: Value(tracker.syncStatus),
      isDeleted: Value(tracker.isDeleted),
    );
  }

  db.TrackerLogsTableCompanion _mapLogToCompanion(TrackerLog log) {
    return db.TrackerLogsTableCompanion(
      id: Value(log.id),
      trackerId: Value(log.trackerId),
      userId: Value(log.userId),
      timestamp: Value(log.timestamp),
      valueNum: Value(log.valueNum),
      valueText: Value(log.valueText),
      notes: Value(log.notes),
      createdAt: Value(log.createdAt),
      updatedAt: Value(log.updatedAt),
      syncStatus: Value(log.syncStatus),
      isDeleted: Value(log.isDeleted),
    );
  }

  @override
  Stream<List<Tracker>> watchTrackers(String userId) {
    final query = _db.select(_db.trackersTable)..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false));
    return query.watch().map((rows) => rows.map(_mapTrackerToDomain).toList());
  }

  @override
  Future<Tracker?> getTracker(String id) async {
    final query = _db.select(_db.trackersTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapTrackerToDomain(row) : null;
  }

  @override
  Future<TrackerLog?> getTrackerLog(String id) async {
    final query = _db.select(_db.trackerLogsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapLogToDomain(row) : null;
  }

  @override
  Future<void> saveTracker(Tracker tracker) async {
    final trackerWithPending = Tracker(
      id: tracker.id,
      userId: tracker.userId,
      name: tracker.name,
      icon: tracker.icon,
      color: tracker.color,
      type: tracker.type,
      unit: tracker.unit,
      isShared: tracker.isShared,
      createdAt: tracker.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: tracker.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.trackersTable).insertOnConflictUpdate(_mapTrackerToCompanion(trackerWithPending));

      final dto = TrackerDto.fromDomain(trackerWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'tracker',
          entityId: tracker.id,
          scopeType: 'user',
          scopeId: tracker.userId ?? 'unknown',
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteTracker(String id) async {
    final tracker = await getTracker(id);
    if (tracker == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.trackersTable)..where((tbl) => tbl.id.equals(id))).write(
        db.TrackersTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'tracker',
          entityId: id,
          scopeType: 'user',
          scopeId: tracker.userId ?? 'unknown',
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Stream<List<TrackerLog>> watchLogsForTracker(String trackerId) {
    final query = _db.select(_db.trackerLogsTable)
      ..where((tbl) => tbl.trackerId.equals(trackerId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapLogToDomain).toList());
  }

  @override
  Stream<List<TrackerLog>> watchLogsForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = _db.select(_db.trackerLogsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.timestamp.isBiggerOrEqualValue(startOfDay) &
      tbl.timestamp.isSmallerThanValue(endOfDay)
    );
    return query.watch().map((rows) => rows.map(_mapLogToDomain).toList());
  }

  @override
  Future<void> saveTrackerLog(TrackerLog log) async {
    final logWithPending = TrackerLog(
      id: log.id,
      trackerId: log.trackerId,
      userId: log.userId,
      timestamp: log.timestamp,
      valueNum: log.valueNum,
      valueText: log.valueText,
      notes: log.notes,
      createdAt: log.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: log.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.trackerLogsTable).insertOnConflictUpdate(_mapLogToCompanion(logWithPending));

      final dto = TrackerLogDto.fromDomain(logWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'tracker_log',
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
  Future<void> deleteTrackerLog(String id) async {
    final log = await getTrackerLog(id);
    if (log == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.trackerLogsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.TrackerLogsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'tracker_log',
          entityId: id,
          scopeType: 'user',
          scopeId: log.userId,
          operation: 'delete',
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> applyRemoteTrackerChange(TrackerDto dto, String operation) async {
    if (operation == 'delete') {
      await (_db.update(_db.trackersTable)..where((tbl) => tbl.id.equals(dto.id))).write(
        db.TrackersTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(dto.updatedAt),
          syncStatus: const Value(SyncStatus.synced),
        ),
      );
    } else {
      await _db.into(_db.trackersTable).insertOnConflictUpdate(
        _mapTrackerToCompanion(dto.toDomain(SyncStatus.synced)),
      );
    }
  }

  @override
  Future<void> applyRemoteTrackerLogChange(TrackerLogDto dto, String operation) async {
    if (operation == 'delete') {
      await (_db.update(_db.trackerLogsTable)..where((tbl) => tbl.id.equals(dto.id))).write(
        db.TrackerLogsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(dto.updatedAt),
          syncStatus: const Value(SyncStatus.synced),
        ),
      );
    } else {
      await _db.into(_db.trackerLogsTable).insertOnConflictUpdate(
        _mapLogToCompanion(dto.toDomain(SyncStatus.synced)),
      );
    }
  }
}

