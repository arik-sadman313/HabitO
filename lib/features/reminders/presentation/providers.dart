import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/notifications/notification_service.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/reminders/data/reminder_repository.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(AppDatabase());
});

final remindersProvider = StreamProvider<List<ReminderSchedule>>((ref) {
  final user = ref.watch(authNotifierProvider).user;
  if (user == null) return Stream.value([]);
  
  return ref.watch(reminderRepositoryProvider).watchReminders(user.id);
});

final enabledRemindersProvider = Provider<List<ReminderSchedule>>((ref) {
  final remindersAsync = ref.watch(remindersProvider);
  return remindersAsync.when(
    data: (reminders) => reminders.where((r) => r.enabled).toList(),
    loading: () => [],
    error: (e, s) => [],
  );
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.requestPermissions();
});

final notificationPayloadProvider = StreamProvider<String?>((ref) {
  return ref.watch(notificationServiceProvider).onPayloadReceived;
});
