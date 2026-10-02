import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/journal/data/journal_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late JournalRepositoryImpl repo;

  const testUserId = 'user-journal-test-001';

  setUp(() async {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repo = JournalRepositoryImpl(database);
    // Insert test user to satisfy FK constraint on journalEntriesTable.userId
    await database.into(database.usersTable).insert(
      UsersTableCompanion.insert(
        id: testUserId,
        name: 'Journal Test User',
        email: 'journal-test@example.com',
        timezone: 'UTC',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  JournalEntry makeEntry({
    String id = 'entry-001',
    JournalType type = JournalType.personal,
    String body = 'Test body content',
  }) {
    final now = DateTime.now();
    return JournalEntry(
      id: id,
      userId: testUserId,
      journalType: type,
      title: 'Test Title',
      body: body,
      moodId: null,
      date: now,
      tags: 'tag1,tag2',
      photoUrl: null,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingUpdate,
      isDeleted: false,
    );
  }

  group('JournalRepository sync integration', () {
    test('saveEntry persists entry and enqueues sync operation', () async {
      final entry = makeEntry();
      await repo.saveEntry(entry);

      // Verify entry saved
      final entries = await database.select(database.journalEntriesTable).get();
      expect(entries.length, 1);
      expect(entries.first.id, entry.id);
      expect(entries.first.body, entry.body);
      expect(entries.first.syncStatus, SyncStatus.pendingUpdate);

      // Verify sync queue entry created
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, 'journal_entry');
      expect(queue.first.entityId, entry.id);
      expect(queue.first.operation, 'upsert');
      expect(queue.first.scopeId, testUserId);
    });

    test('deleteEntry soft-deletes and enqueues delete operation', () async {
      final entry = makeEntry();
      await repo.saveEntry(entry);

      // Clear queue from save
      await database.delete(database.syncQueueTable).go();

      await repo.deleteEntry(entry.id);

      // Verify soft-delete
      final entries = await database.select(database.journalEntriesTable).get();
      expect(entries.first.isDeleted, true);
      expect(entries.first.syncStatus, SyncStatus.pendingUpdate);

      // Verify delete queued
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.length, 1);
      expect(queue.first.entityType, 'journal_entry');
      expect(queue.first.operation, 'delete');
    });

    test('applyRemoteJournalChange does not create a sync queue entry (loop prevention)', () async {
      final entry = makeEntry();
      await repo.applyRemoteJournalChange(entry.copyWithSynced());

      // Verify entry applied
      final entries = await database.select(database.journalEntriesTable).get();
      expect(entries.length, 1);
      expect(entries.first.syncStatus, SyncStatus.synced);

      // Critically: no queue entry created
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.isEmpty, true);
    });

    test('applyRemoteJournalDelete soft-deletes without re-queuing', () async {
      final entry = makeEntry();
      // First apply the record as if synced from remote
      await repo.applyRemoteJournalChange(entry.copyWithSynced());

      await repo.applyRemoteJournalDelete(entry.id, DateTime.now());

      // Verify deleted
      final entries = await database.select(database.journalEntriesTable).get();
      expect(entries.first.isDeleted, true);
      expect(entries.first.syncStatus, SyncStatus.synced);

      // No sync queue entry
      final queue = await database.select(database.syncQueueTable).get();
      expect(queue.isEmpty, true);
    });

    test('search finds journal entries by body content', () async {
      final entry = makeEntry(body: 'unique-phrase-xyzzy-12345');
      await repo.saveEntry(entry);

      final results = await repo.searchJournalEntries(testUserId, 'xyzzy').first;
      expect(results.length, 1);
      expect(results.first.id, entry.id);
    });

    test('search returns empty when no match', () async {
      final entry = makeEntry(body: 'hello world');
      await repo.saveEntry(entry);

      final results = await repo.searchJournalEntries(testUserId, 'nomatch-xyz').first;
      expect(results.isEmpty, true);
    });

    test('saveEntry transaction: entry and queue are atomic', () async {
      // Saving should produce exactly one entry and one queue item
      final entry = makeEntry(id: 'atomic-001');
      await repo.saveEntry(entry);

      final entries = await database.select(database.journalEntriesTable).get();
      final queue = await database.select(database.syncQueueTable).get();
      expect(entries.length, 1);
      expect(queue.length, 1);
    });
  });
}

extension on JournalEntry {
  JournalEntry copyWithSynced() {
    return JournalEntry(
      id: id,
      userId: userId,
      journalType: journalType,
      title: title,
      body: body,
      moodId: moodId,
      date: date,
      tags: tags,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }
}
