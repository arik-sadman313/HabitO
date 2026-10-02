import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  UsersTable,
  CouplesTable,
  TrackersTable,
  TrackerLogsTable,
  HabitsTable,
  HabitLogsTable,
  ActivitiesTable,
  StudySubjectsTable,
  StudySessionsTable,
  MealsTable,
  MealItemsTable,
  SleepRecordsTable,
  ExerciseSessionsTable,
  MoodLogsTable,
  JournalEntriesTable,
  SharedGoalsTable,
  SharedHabitsTable,
  SharedActivitiesTable,
  MemoriesTable,
  ScreenTimeDailySnapshotsTable,
  PersonalGoalsTable,
  ReminderSchedulesTable,
  SyncQueueTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(studySubjectsTable);
            await m.createTable(studySessionsTable);
          }
          if (from < 3) {
            await m.createTable(mealsTable);
            await m.createTable(mealItemsTable);
            await m.createTable(sleepRecordsTable);
            await m.createTable(exerciseSessionsTable);
          }
          if (from < 4) {
            await m.createTable(moodLogsTable);
            await m.createTable(journalEntriesTable);
          }
          if (from < 5) {
            await m.createTable(sharedGoalsTable);
            await m.createTable(sharedHabitsTable);
            await m.createTable(sharedActivitiesTable);
            await m.createTable(memoriesTable);
          }
          if (from < 6) {
            await m.createTable(screenTimeDailySnapshotsTable);
          }
          if (from < 7) {
            await m.createTable(personalGoalsTable);
          }
          if (from < 8) {
            await m.createTable(reminderSchedulesTable);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'habito_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
