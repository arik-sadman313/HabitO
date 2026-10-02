import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  static const general = AndroidNotificationChannel(
    'general_reminders',
    'General Reminders',
    description: 'Notifications for general reminders.',
    importance: Importance.defaultImportance,
  );

  static const habits = AndroidNotificationChannel(
    'habit_reminders',
    'Habit Reminders',
    description: 'Reminders for your habits.',
    importance: Importance.high,
  );

  static const study = AndroidNotificationChannel(
    'study_reminders',
    'Study Reminders',
    description: 'Reminders for study sessions.',
    importance: Importance.high,
  );

  static const goals = AndroidNotificationChannel(
    'goal_reminders',
    'Goal Reminders',
    description: 'Reminders for your personal goals.',
    importance: Importance.defaultImportance,
  );
  
  static const lifestyle = AndroidNotificationChannel(
    'lifestyle_reminders',
    'Lifestyle Reminders',
    description: 'Reminders for food, water, sleep, and exercise.',
    importance: Importance.defaultImportance,
  );

  static final all = [general, habits, study, goals, lifestyle];
}
