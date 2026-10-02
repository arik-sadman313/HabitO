import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';

abstract class TrackerRepository {
  Future<List<Tracker>> getTrackers(String userId);
  Future<void> saveTracker(Tracker tracker);
  Stream<List<Tracker>> watchTrackers(String userId);
}

class TrackerRepositoryImpl implements TrackerRepository {
  final db.AppDatabase _db;

  TrackerRepositoryImpl(this._db);

  @override
  Future<List<Tracker>> getTrackers(String userId) async {
    final query = _db.select(_db.trackersTable)
      ..where((t) => t.userId.equals(userId) | t.userId.isNull());
    final results = await query.get();
    return results.map(_mapToDomain).toList();
  }

  @override
  Stream<List<Tracker>> watchTrackers(String userId) {
    final query = _db.select(_db.trackersTable)
      ..where((t) => t.userId.equals(userId) | t.userId.isNull());
    return query.watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<void> saveTracker(Tracker tracker) async {
    await _db.into(_db.trackersTable).insertOnConflictUpdate(_mapToDb(tracker));
  }

  Tracker _mapToDomain(db.TrackersTableData data) {
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

  db.TrackersTableCompanion _mapToDb(Tracker tracker) {
    return db.TrackersTableCompanion.insert(
      id: tracker.id,
      userId: driftValue(tracker.userId),
      name: tracker.name,
      icon: tracker.icon,
      color: tracker.color,
      type: tracker.type,
      unit: driftValue(tracker.unit),
      isShared: driftValue(tracker.isShared),
      createdAt: tracker.createdAt,
      updatedAt: tracker.updatedAt,
      syncStatus: tracker.syncStatus,
      isDeleted: driftValue(tracker.isDeleted),
    );
  }

  Value<T> driftValue<T>(T? val) => val == null ? const Value.absent() : Value(val);
}
