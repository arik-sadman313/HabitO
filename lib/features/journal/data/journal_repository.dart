import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/sync/dtos.dart';

abstract class JournalRepository {
  Stream<List<JournalEntry>> watchJournalEntries(String userId, {JournalType? filterType});
  Stream<List<JournalEntry>> searchJournalEntries(String userId, String query);
  Future<void> saveEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
  Future<void> applyRemoteJournalChange(JournalEntry entry);
  Future<void> applyRemoteJournalDelete(String id, DateTime updatedAt);
}

class JournalRepositoryImpl implements JournalRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  JournalRepositoryImpl(this._db);

  JournalEntry _mapEntry(db.JournalEntriesTableData data) {
    return JournalEntry(
      id: data.id,
      userId: data.userId,
      journalType: data.journalType,
      title: data.title,
      body: data.body,
      moodId: data.moodId,
      date: data.date,
      tags: data.tags,
      photoUrl: data.photoUrl,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      syncStatus: data.syncStatus,
      isDeleted: data.isDeleted,
    );
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntries(String userId, {JournalType? filterType}) {
    final query = _db.select(_db.journalEntriesTable)..where((tbl) =>
      tbl.userId.equals(userId) & tbl.isDeleted.equals(false)
    );

    if (filterType != null) {
      query.where((tbl) => tbl.journalType.equals(filterType.index));
    }

    query.orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);
    return query.watch().map((rows) => rows.map(_mapEntry).toList());
  }

  @override
  Stream<List<JournalEntry>> searchJournalEntries(String userId, String searchQuery) {
    final search = '%${searchQuery.toLowerCase()}%';

    final query = _db.select(_db.journalEntriesTable)..where((tbl) =>
      tbl.userId.equals(userId) &
      tbl.isDeleted.equals(false) &
      (
        tbl.title.lower().like(search) |
        tbl.body.lower().like(search) |
        tbl.tags.lower().like(search)
      )
    )..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map(_mapEntry).toList());
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    final entryWithPending = JournalEntry(
      id: entry.id,
      userId: entry.userId,
      journalType: entry.journalType,
      title: entry.title,
      body: entry.body,
      moodId: entry.moodId,
      date: entry.date,
      tags: entry.tags,
      photoUrl: entry.photoUrl,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: entry.isDeleted,
    );

    await _db.transaction(() async {
      await _db.into(_db.journalEntriesTable).insertOnConflictUpdate(
        db.JournalEntriesTableCompanion(
          id: Value(entryWithPending.id),
          userId: Value(entryWithPending.userId),
          journalType: Value(entryWithPending.journalType),
          title: Value(entryWithPending.title),
          body: Value(entryWithPending.body),
          moodId: Value(entryWithPending.moodId),
          date: Value(entryWithPending.date),
          tags: Value(entryWithPending.tags),
          photoUrl: Value(entryWithPending.photoUrl),
          createdAt: Value(entryWithPending.createdAt),
          updatedAt: Value(entryWithPending.updatedAt),
          syncStatus: Value(entryWithPending.syncStatus),
          isDeleted: Value(entryWithPending.isDeleted),
        ),
      );

      final dto = JournalEntryDto.fromDomain(entryWithPending);
      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'journal_entry',
          entityId: entryWithPending.id,
          scopeType: 'user',
          scopeId: entryWithPending.userId,
          operation: 'upsert',
          payload: Value(jsonEncode(dto.toJson())),
          createdAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteEntry(String id) async {
    final query = _db.select(_db.journalEntriesTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return;

    await _db.transaction(() async {
      await (_db.update(_db.journalEntriesTable)..where((tbl) => tbl.id.equals(id))).write(
        db.JournalEntriesTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );

      await _db.into(_db.syncQueueTable).insert(
        db.SyncQueueTableCompanion.insert(
          id: _uuid.v4(),
          entityType: 'journal_entry',
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
  Future<void> applyRemoteJournalChange(JournalEntry entry) async {
    await _db.into(_db.journalEntriesTable).insertOnConflictUpdate(
      db.JournalEntriesTableCompanion(
        id: Value(entry.id),
        userId: Value(entry.userId),
        journalType: Value(entry.journalType),
        title: Value(entry.title),
        body: Value(entry.body),
        moodId: Value(entry.moodId),
        date: Value(entry.date),
        tags: Value(entry.tags),
        photoUrl: Value(entry.photoUrl),
        createdAt: Value(entry.createdAt),
        updatedAt: Value(entry.updatedAt),
        syncStatus: Value(entry.syncStatus),
        isDeleted: Value(entry.isDeleted),
      ),
    );
  }

  @override
  Future<void> applyRemoteJournalDelete(String id, DateTime updatedAt) async {
    await (_db.update(_db.journalEntriesTable)..where((tbl) => tbl.id.equals(id))).write(
      db.JournalEntriesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
