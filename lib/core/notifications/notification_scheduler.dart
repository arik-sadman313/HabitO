import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/notifications/notification_channels.dart';
import 'package:habito/core/notifications/notification_service.dart';
import 'package:habito/features/reminders/data/reminder_repository.dart';
import 'package:habito/features/reminders/presentation/providers.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    ref.watch(notificationServiceProvider),
    ref.watch(reminderRepositoryProvider),
  );
});

class NotificationScheduler {
  final NotificationService _service;
  final ReminderRepository _repo;

  NotificationScheduler(this._service, this._repo);

  Future<void> reconcile(List<ReminderSchedule> activeReminders) async {
    // 1. Cancel all
    await _service.cancelAll();
    
    // 2. Reschedule active ones
    for (final reminder in activeReminders) {
      if (reminder.enabled) {
        await _schedule(reminder);
      }
    }
  }

  Future<void> scheduleReminder(ReminderSchedule reminder) async {
    if (reminder.enabled) {
      await _schedule(reminder);
    } else {
      await cancelReminder(reminder.id);
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    await _service.cancel(reminderId.hashCode);
  }

  Future<void> _schedule(ReminderSchedule reminder) async {
    AndroidNotificationChannel channel;
    switch (reminder.type) {
      case ReminderType.habit:
        channel = NotificationChannels.habits;
        break;
      case ReminderType.study:
        channel = NotificationChannels.study;
        break;
      case ReminderType.goal:
        channel = NotificationChannels.goals;
        break;
      case ReminderType.water:
      case ReminderType.exercise:
      case ReminderType.sleep:
        channel = NotificationChannels.lifestyle;
        break;
      default:
        channel = NotificationChannels.general;
    }

    final payload = '${reminder.type.value}:${reminder.referenceId ?? ''}';
    final id = reminder.id.hashCode;

    switch (reminder.recurrenceType) {
      case RecurrenceType.once:
        await _service.scheduleNotification(
          id: id,
          title: reminder.title,
          body: reminder.body,
          scheduledTime: reminder.scheduledTime,
          channel: channel,
          payload: payload,
        );
        break;
      case RecurrenceType.daily:
        await _service.scheduleDaily(
          id: id,
          title: reminder.title,
          body: reminder.body,
          timeOfDay: reminder.scheduledTime,
          channel: channel,
          payload: payload,
        );
        break;
      case RecurrenceType.weekly:
        await _service.scheduleWeekly(
          id: id,
          title: reminder.title,
          body: reminder.body,
          timeOfDay: reminder.scheduledTime,
          daysOfWeek: reminder.daysOfWeek ?? [reminder.scheduledTime.weekday],
          channel: channel,
          payload: payload,
        );
        break;
      case RecurrenceType.weekdays:
        await _service.scheduleWeekly(
          id: id,
          title: reminder.title,
          body: reminder.body,
          timeOfDay: reminder.scheduledTime,
          daysOfWeek: [1, 2, 3, 4, 5],
          channel: channel,
          payload: payload,
        );
        break;
      case RecurrenceType.weekends:
        await _service.scheduleWeekly(
          id: id,
          title: reminder.title,
          body: reminder.body,
          timeOfDay: reminder.scheduledTime,
          daysOfWeek: [6, 7],
          channel: channel,
          payload: payload,
        );
        break;
      case RecurrenceType.custom:
        if (reminder.daysOfWeek != null && reminder.daysOfWeek!.isNotEmpty) {
          await _service.scheduleWeekly(
            id: id,
            title: reminder.title,
            body: reminder.body,
            timeOfDay: reminder.scheduledTime,
            daysOfWeek: reminder.daysOfWeek!,
            channel: channel,
            payload: payload,
          );
        }
        break;
    }
  }
}
