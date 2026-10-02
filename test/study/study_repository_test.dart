import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/study/data/study_repository.dart';

void main() {
  group('StudyRepository', () {
    late AppDatabase db;
    late StudyRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      repo = StudyRepositoryImpl(db);
      
      await db.into(db.usersTable).insert(
        UsersTableCompanion.insert(
          id: 'user1',
          name: 'Test',
          email: 'test@example.com',
          timezone: 'UTC',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Save and retrieve study subject', () async {
      final subject = StudySubject(
        id: 'sub1',
        userId: 'user1',
        name: 'Math',
        icon: 'math',
        color: 'red',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await repo.saveSubject(subject);
      
      final retrieved = await repo.getSubject('sub1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Math');
    });

    test('Save and retrieve study session', () async {
      final subject = StudySubject(
        id: 'sub1',
        userId: 'user1',
        name: 'Math',
        icon: 'math',
        color: 'red',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await repo.saveSubject(subject);
      
      final session = StudySession(
        id: 'sess1',
        userId: 'user1',
        subjectId: 'sub1',
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        endedAt: DateTime.now(),
        duration: 3600,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      );
      
      await repo.saveSession(session);
      
      final stream = repo.watchSessions('user1');
      final sessions = await stream.first;
      
      expect(sessions.length, 1);
      expect(sessions.first.duration, 3600);
    });
  });
}
