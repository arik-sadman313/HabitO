import 'package:drift/drift.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

abstract class ReminderRepository {
  Stream<List<ReminderSchedule>> watchReminders(String userId);
  Future<ReminderSchedule?> getReminder(String reminderId);
  Future<void> saveReminder(ReminderSchedule reminder);
  Future<void> deleteReminder(String reminderId);
}

class ReminderRepositoryImpl implements ReminderRepository {
  final db.AppDatabase _db;

  ReminderRepositoryImpl(this._db);

  ReminderSchedule _mapToDomain(db.ReminderSchedulesTableData entry) {
    return ReminderSchedule(
      id: entry.id,
      userId: entry.userId,
      type: entry.type,
      title: entry.title,
      body: entry.body,
      referenceId: entry.referenceId,
      scheduledTime: entry.scheduledTime,
      recurrenceType: entry.recurrenceType,
      daysOfWeek: entry.daysOfWeek != null ? (entry.daysOfWeek!.replaceAll('[', '').replaceAll(']', '').split(',').map((e) => int.parse(e.trim())).toList()) : null,
      enabled: entry.enabled,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
      isDeleted: entry.isDeleted,
    );
  }

  db.ReminderSchedulesTableCompanion _mapToCompanion(ReminderSchedule reminder) {
    return db.ReminderSchedulesTableCompanion(
      id: Value(reminder.id),
      userId: Value(reminder.userId),
      type: Value(reminder.type),
      title: Value(reminder.title),
      body: Value(reminder.body),
      referenceId: Value(reminder.referenceId),
      scheduledTime: Value(reminder.scheduledTime),
      recurrenceType: Value(reminder.recurrenceType),
      daysOfWeek: Value(reminder.daysOfWeek != null ? reminder.daysOfWeek.toString() : null),
      enabled: Value(reminder.enabled),
      createdAt: Value(reminder.createdAt),
      updatedAt: Value(reminder.updatedAt),
      syncStatus: Value(reminder.syncStatus),
      isDeleted: Value(reminder.isDeleted),
    );
  }

  @override
  Stream<List<ReminderSchedule>> watchReminders(String userId) {
    return (_db.select(_db.reminderSchedulesTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.not()))
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<ReminderSchedule?> getReminder(String reminderId) async {
    final query = _db.select(_db.reminderSchedulesTable)
      ..where((t) => t.id.equals(reminderId) & t.isDeleted.not());
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> saveReminder(ReminderSchedule reminder) async {
    await _db.into(_db.reminderSchedulesTable).insertOnConflictUpdate(_mapToCompanion(reminder));
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    final current = await getReminder(reminderId);
    if (current != null) {
      await saveReminder(ReminderSchedule(
        id: current.id,
        userId: current.userId,
        type: current.type,
        title: current.title,
        body: current.body,
        referenceId: current.referenceId,
        scheduledTime: current.scheduledTime,
        recurrenceType: current.recurrenceType,
        daysOfWeek: current.daysOfWeek,
        enabled: current.enabled,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
        isDeleted: true,
      ));
    }
  }
}
