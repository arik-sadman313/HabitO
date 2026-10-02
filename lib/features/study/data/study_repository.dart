import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class StudyRepository {
  Stream<List<StudySubject>> watchSubjects(String userId);
  Future<StudySubject?> getSubject(String id);
  Future<void> saveSubject(StudySubject subject);
  Future<void> archiveSubject(String id);
  
  Stream<List<StudySession>> watchSessions(String userId);
  Stream<List<StudySession>> watchSessionsForSubject(String subjectId);
  Stream<List<StudySession>> watchSessionsForDate(String userId, DateTime date);
  Future<void> saveSession(StudySession session);
  Future<void> deleteSession(String id);
  Future<void> applyRemoteSubjectChange(StudySubject subject);
  Future<void> applyRemoteSubjectDelete(String id, DateTime updatedAt);
  Future<void> applyRemoteSessionChange(StudySession session);
  Future<void> applyRemoteSessionDelete(String id, DateTime updatedAt);
}

class StudyRepositoryImpl implements StudyRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  StudyRepositoryImpl(this._db);

  StudySubject _mapSubjectToDomain(db.StudySubjectsTableData data) {
    return StudySubject(
      id: data.id,
      userId: data.userId,
      name: data.name,
      description: data.description,
      icon: data.icon,
      color: data.color,
      isActive: data.isActive,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  StudySession _mapSessionToDomain(db.StudySessionsTableData data) {
    return StudySession(
      id: data.id,
      userId: data.userId,
      subjectId: data.subjectId,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
      duration: data.duration,
      notes: data.notes,
      sessionType: data.sessionType,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<List<StudySubject>> watchSubjects(String userId) {
    final query = _db.select(_db.studySubjectsTable)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]);
    return query.watch().map((rows) => rows.map(_mapSubjectToDomain).toList());
  }

  @override
  Future<StudySubject?> getSubject(String id) async {
    final query = _db.select(_db.studySubjectsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapSubjectToDomain(row) : null;
  }

  @override
  Future<void> saveSubject(StudySubject subject) async {
    final subjectWithPending = StudySubject(
      id: subject.id,
      userId: subject.userId,
      name: subject.name,
      description: subject.description,
      icon: subject.icon,
      color: subject.color,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: subject.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.studySubjectsTable).insertOnConflictUpdate(
        db.StudySubjectsTableCompanion(
          id: Value(subjectWithPending.id),
          userId: Value(subjectWithPending.userId),
          name: Value(subjectWithPending.name),
          description: Value(subjectWithPending.description),
          icon: Value(subjectWithPending.icon),
          color: Value(subjectWithPending.color),
          isActive: Value(subjectWithPending.isActive),
          createdAt: Value(subjectWithPending.createdAt),
          updatedAt: Value(subjectWithPending.updatedAt),
          syncStatus: Value(subjectWithPending.syncStatus),
          isDeleted: Value(subjectWithPending.isDeleted),
        ),
      );

      final dto = StudySubjectDto.fromDomain(subjectWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'study_subject',
          entityId: subjectWithPending.id,
          scopeType: 'user',
          scopeId: subjectWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> archiveSubject(String id) async {
    final subject = await getSubject(id);
    if (subject == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.studySubjectsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.StudySubjectsTableCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'study_subject',
          entityId: id,
          scopeType: 'user',
          scopeId: subject.userId,
          operation: 'delete', // Or upsert? Let's treat it as an upsert of the inactive subject to be safe, since it's just 'archived'. Wait, prompt: "Support: Create Update Soft delete". Soft delete is just an update of isDeleted=True, but archive is isActive=false. Let's do an upsert of the subject so the backend gets the new isActive=False state.
          payload: Value(jsonEncode(StudySubjectDto.fromDomain(
            StudySubject(
              id: subject.id,
              userId: subject.userId,
              name: subject.name,
              description: subject.description,
              icon: subject.icon,
              color: subject.color,
              isActive: false,
              createdAt: subject.createdAt,
              updatedAt: DateTime.now(),
              syncStatus: SyncStatus.pendingUpdate,
              isDeleted: subject.isDeleted,
            )
          ).toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Stream<List<StudySession>> watchSessions(String userId) {
    final query = _db.select(_db.studySessionsTable)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.startedAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapSessionToDomain).toList());
  }

  @override
  Stream<List<StudySession>> watchSessionsForSubject(String subjectId) {
    final query = _db.select(_db.studySessionsTable)
      ..where((tbl) => tbl.subjectId.equals(subjectId) & tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.startedAt, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapSessionToDomain).toList());
  }

  @override
  Stream<List<StudySession>> watchSessionsForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final query = _db.select(_db.studySessionsTable)..where((tbl) => 
      tbl.userId.equals(userId) & 
      tbl.isDeleted.equals(false) &
      tbl.startedAt.isBiggerOrEqualValue(startOfDay) &
      tbl.startedAt.isSmallerThanValue(endOfDay)
    );
    return query.watch().map((rows) => rows.map(_mapSessionToDomain).toList());
  }

  @override
  Future<void> saveSession(StudySession session) async {
    final sessionWithPending = StudySession(
      id: session.id,
      userId: session.userId,
      subjectId: session.subjectId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      duration: session.duration,
      notes: session.notes,
      sessionType: session.sessionType,
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: session.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.studySessionsTable).insertOnConflictUpdate(
        db.StudySessionsTableCompanion(
          id: Value(sessionWithPending.id),
          userId: Value(sessionWithPending.userId),
          subjectId: Value(sessionWithPending.subjectId),
          startedAt: Value(sessionWithPending.startedAt),
          endedAt: Value(sessionWithPending.endedAt),
          duration: Value(sessionWithPending.duration),
          notes: Value(sessionWithPending.notes),
          sessionType: Value(sessionWithPending.sessionType),
          createdAt: Value(sessionWithPending.createdAt),
          updatedAt: Value(sessionWithPending.updatedAt),
          syncStatus: Value(sessionWithPending.syncStatus),
          isDeleted: Value(sessionWithPending.isDeleted),
        ),
      );

      final dto = StudySessionDto.fromDomain(sessionWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'study_session',
          entityId: sessionWithPending.id,
          scopeType: 'user',
          scopeId: sessionWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteSession(String id) async {
    final query = _db.select(_db.studySessionsTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;
    
    await _db.transaction(() async {
      await (_db.update(_db.studySessionsTable)..where((tbl) => tbl.id.equals(id))).write(
        db.StudySessionsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'study_session',
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
  Future<void> applyRemoteSubjectChange(StudySubject subject) async {
    await _db.into(_db.studySubjectsTable).insertOnConflictUpdate(
      db.StudySubjectsTableCompanion(
        id: Value(subject.id),
        userId: Value(subject.userId),
        name: Value(subject.name),
        description: Value(subject.description),
        icon: Value(subject.icon),
        color: Value(subject.color),
        isActive: Value(subject.isActive),
        createdAt: Value(subject.createdAt),
        updatedAt: Value(subject.updatedAt),
        syncStatus: Value(subject.syncStatus),
        isDeleted: Value(subject.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteSessionChange(StudySession session) async {
    await _db.into(_db.studySessionsTable).insertOnConflictUpdate(
      db.StudySessionsTableCompanion(
        id: Value(session.id),
        userId: Value(session.userId),
        subjectId: Value(session.subjectId),
        startedAt: Value(session.startedAt),
        endedAt: Value(session.endedAt),
        duration: Value(session.duration),
        notes: Value(session.notes),
        sessionType: Value(session.sessionType),
        createdAt: Value(session.createdAt),
        updatedAt: Value(session.updatedAt),
        syncStatus: Value(session.syncStatus),
        isDeleted: Value(session.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteSubjectDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.studySubjectsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.StudySubjectsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  @override
  Future<void> applyRemoteSessionDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.studySessionsTable)..where((tbl) => tbl.id.equals(id))).write(
      db.StudySessionsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
