enum SyncStatus {
  synced(0),
  pendingInsert(1),
  pendingUpdate(2),
  pendingDelete(3);

  final int value;
  const SyncStatus(this.value);
}

enum CoupleStatus {
  pending(0),
  active(1),
  separated(2);

  final int value;
  const CoupleStatus(this.value);
}

enum TrackerType {
  boolean(0),
  integer(1),
  decimal(2),
  duration(3),
  text(4),
  rating(5),
  timestamp(6),
  selection(7);

  final int value;
  const TrackerType(this.value);
}

enum HabitFrequency {
  daily(0),
  weekly(1),
  monthly(2),
  custom(3);

  final int value;
  const HabitFrequency(this.value);
}

enum JournalType { personal, shared }

enum GoalStatus {
  active(0),
  completed(1),
  paused(2),
  abandoned(3);

  final int value;
  const GoalStatus(this.value);
}

enum ReminderType {
  habit('habit'),
  study('study'),
  water('water'),
  exercise('exercise'),
  sleep('sleep'),
  goal('goal'),
  activity('activity'),
  journal('journal'),
  general('general');

  final String value;
  const ReminderType(this.value);
}

enum RecurrenceType {
  once('once'),
  daily('daily'),
  weekly('weekly'),
  weekdays('weekdays'),
  weekends('weekends'),
  custom('custom');

  final String value;
  const RecurrenceType(this.value);
}
