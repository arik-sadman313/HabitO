import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class MoodRepository {
  Stream<MoodLog?> watchCheckInForDate(String userId, DateTime date);
  Stream<List<MoodLog>> watchMoodHistory(String userId, int days);
  Future<void> saveCheckIn(MoodLog log);
  Future<void> deleteMoodLog(String id);
  Future<void> applyRemoteMoodChange(MoodLog log);
  Future<void> applyRemoteMoodDelete(String id, DateTime updatedAt);
}

class MoodRepositoryImpl implements MoodRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  MoodRepositoryImpl(this._db);

  MoodLog _mapLog(db.MoodLogsTableData data) {
    return MoodLog(
      id: data.id,
      userId: data.userId,
      date: data.date,
      moodRating: data.moodRating,
      energyRating: data.energyRating,
      stressRating: data.stressRating,
      note: data.note,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<MoodLog?> watchCheckInForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.moodLogsTable)..where((tbl) =>
      tbl.userId.equals(userId) &
      tbl.isDeleted.equals(false) &
      tbl.date.isBiggerOrEqualValue(startOfDay) &
      tbl.date.isSmallerThanValue(endOfDay)
    )..limit(1);

    return query.watchSingleOrNull().map((row) => row != null ? _mapLog(row) : null);
  }

  @override
  Stream<List<MoodLog>> watchMoodHistory(String userId, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final query = _db.select(_db.moodLogsTable)..where((tbl) =>
      tbl.userId.equals(userId) &
      tbl.isDeleted.equals(false) &
      tbl.date.isBiggerOrEqualValue(cutoff)
    )..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map(_mapLog).toList());
  }

  @override
  Future<void> saveCheckIn(MoodLog log) async {
    final logWithPending = MoodLog(
      id: log.id,
      userId: log.userId,
      date: log.date,
      moodRating: log.moodRating,
      energyRating: log.energyRating,
      stressRating: log.stressRating,
      note: log.note,
      createdAt: log.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: log.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.moodLogsTable).insertOnConflictUpdate(
        db.MoodLogsTableCompanion(
          id: Value(logWithPending.id),
          userId: Value(logWithPending.userId),
          date: Value(logWithPending.date),
          moodRating: Value(logWithPending.moodRating),
          energyRating: Value(logWithPending.energyRating),
          stressRating: Value(logWithPending.stressRating),
          note: Value(logWithPending.note),
          createdAt: Value(logWithPending.createdAt),
          updatedAt: Value(logWithPending.updatedAt),
          syncStatus: Value(logWithPending.syncStatus),
          isDeleted: Value(logWithPending.isDeleted),
        ),
      );

      final dto = MoodLogDto.fromDomain(logWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'mood_log',
          entityId: logWithPending.id,
          scopeType: 'user',
          scopeId: logWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteMoodLog(String id) async {
    final query = _db.select(_db.moodLogsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.moodLogsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.MoodLogsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'mood_log',
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
  Future<void> applyRemoteMoodChange(MoodLog log) async {
    await _db.into(_db.moodLogsTable).insertOnConflictUpdate(
      db.MoodLogsTableCompanion(
        id: Value(log.id),
        userId: Value(log.userId),
        date: Value(log.date),
        moodRating: Value(log.moodRating),
        energyRating: Value(log.energyRating),
        stressRating: Value(log.stressRating),
        note: Value(log.note),
        createdAt: Value(log.createdAt),
        updatedAt: Value(log.updatedAt),
        syncStatus: Value(log.syncStatus),
        isDeleted: Value(log.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteMoodDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.moodLogsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.MoodLogsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
