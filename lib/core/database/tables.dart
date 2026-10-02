import 'package:drift/drift.dart';
import 'package:habito/core/database/enums.dart';

class UsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get timezone => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CouplesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userAId => text().references(UsersTable, #id)();
  TextColumn get userBId => text().references(UsersTable, #id)();
  IntColumn get status => intEnum<CoupleStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class TrackersTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable().references(UsersTable, #id)();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get type => intEnum<TrackerType>()();
  TextColumn get unit => text().nullable()();
  BoolColumn get isShared => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class TrackerLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get trackerId => text().references(TrackersTable, #id)();
  TextColumn get userId => text().references(UsersTable, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get valueNum => real().nullable()();
  TextColumn get valueText => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get trackerId => text().references(TrackersTable, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get frequency => intEnum<HabitFrequency>()();
  RealColumn get targetValue => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isShared => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(HabitsTable, #id)();
  TextColumn get userId => text().references(UsersTable, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isCompleted => boolean()();
  RealColumn get progressValue => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivitiesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get scheduledStart => dateTime()();
  DateTimeColumn get scheduledEnd => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  BoolColumn get isShared => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudySubjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class StudySessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get subjectId => text().references(StudySubjectsTable, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get duration => integer().withDefault(const Constant(0))(); // in seconds
  TextColumn get notes => text().nullable()();
  TextColumn get sessionType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get scopeType => text()(); // user, couple
  TextColumn get scopeId => text()();
  TextColumn get operation => text()(); // upsert, delete
  TextColumn get payload => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  Set<Column> get primaryKey => {id};
}

class MealsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get mealType => text()(); // Breakfast, Lunch, Dinner, Snack, Custom
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(MealsTable, #id)();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  RealColumn get calories => real().nullable()();
  RealColumn get protein => real().nullable()();
  RealColumn get carbs => real().nullable()();
  RealColumn get fat => real().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SleepRecordsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  DateTimeColumn get sleepStart => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  IntColumn get duration => integer()();
  IntColumn get quality => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseSessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get exerciseType => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get duration => integer()();
  RealColumn get distance => real().nullable()();
  IntColumn get calories => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class MoodLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  DateTimeColumn get date => dateTime()(); 
  IntColumn get moodRating => integer()();
  IntColumn get energyRating => integer()();
  IntColumn get stressRating => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class JournalEntriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  IntColumn get journalType => intEnum<JournalType>()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  TextColumn get moodId => text().nullable().references(MoodLogsTable, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get tags => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class SharedGoalsTable extends Table {
  TextColumn get id => text()();
  TextColumn get coupleId => text().references(CouplesTable, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get target => real()();
  RealColumn get currentProgress => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class SharedHabitsTable extends Table {
  TextColumn get id => text()();
  TextColumn get coupleId => text().references(CouplesTable, #id)();
  TextColumn get title => text()();
  IntColumn get frequency => intEnum<HabitFrequency>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class SharedActivitiesTable extends Table {
  TextColumn get id => text()();
  TextColumn get coupleId => text().references(CouplesTable, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class MemoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get coupleId => text().references(CouplesTable, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class ScreenTimeDailySnapshotsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalDurationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get appCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class PersonalGoalsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(UsersTable, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get goalType => text()();
  RealColumn get targetValue => real()();
  RealColumn get currentValue => real().nullable()();
  TextColumn get unit => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get status => intEnum<GoalStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}

class ReminderSchedulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get type => intEnum<ReminderType>()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get referenceId => text().nullable()();
  DateTimeColumn get scheduledTime => dateTime()();
  IntColumn get recurrenceType => intEnum<RecurrenceType>()();
  TextColumn get daysOfWeek => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncStatus => intEnum<SyncStatus>().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override Set<Column> get primaryKey => {id};
}
