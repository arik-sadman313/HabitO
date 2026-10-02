import 'package:habito/core/database/enums.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class Couple {
  final String id;
  final String userAId;
  final String userBId;
  final CoupleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const Couple({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
}

class Tracker {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final TrackerType type;
  final String? unit;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const Tracker({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.unit,
    this.isShared = true,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class TrackerLog {
  final String id;
  final String trackerId;
  final String userId;
  final DateTime timestamp;
  final double? valueNum;
  final String? valueText;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const TrackerLog({
    required this.id,
    required this.trackerId,
    required this.userId,
    required this.timestamp,
    this.valueNum,
    this.valueText,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class Habit {
  final String id;
  final String userId;
  final String trackerId;
  final String title;
  final String? description;
  final HabitFrequency frequency;
  final double targetValue;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const Habit({
    required this.id,
    required this.userId,
    required this.trackerId,
    required this.title,
    this.description,
    required this.frequency,
    required this.targetValue,
    required this.startDate,
    this.endDate,
    this.isShared = true,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool isCompleted;
  final double progressValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.isCompleted,
    required this.progressValue,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
}

class Activity {
  final String id;
  final String userId;
  final String title;
  final String? notes;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final bool isCompleted;
  final String? category;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const Activity({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.scheduledStart,
    this.scheduledEnd,
    this.isCompleted = false,
    this.category,
    this.isShared = true,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class StudySubject {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const StudySubject({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class StudySession {
  final String id;
  final String userId;
  final String subjectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int duration; // in seconds
  final String? notes;
  final String? sessionType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const StudySession({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.startedAt,
    this.endedAt,
    this.duration = 0,
    this.notes,
    this.sessionType,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class Meal {
  final String id;
  final String userId;
  final String mealType;
  final DateTime recordedAt;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;
  
  // Loaded separately
  final List<MealItem> items;

  const Meal({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.recordedAt,
    this.notes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
    this.items = const [],
  });
}

class MealItem {
  final String id;
  final String mealId;
  final String name;
  final double quantity;
  final String unit;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? notes;

  const MealItem({
    required this.id,
    required this.mealId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.notes,
  });
}

class SleepRecord {
  final String id;
  final String userId;
  final DateTime sleepStart;
  final DateTime wakeTime;
  final int duration;
  final int quality;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const SleepRecord({
    required this.id,
    required this.userId,
    required this.sleepStart,
    required this.wakeTime,
    required this.duration,
    required this.quality,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class ExerciseSession {
  final String id;
  final String userId;
  final String exerciseType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int duration;
  final double? distance;
  final int? calories;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const ExerciseSession({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    this.distance,
    this.calories,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class MoodLog {
  final String id;
  final String userId;
  final DateTime date;
  final int moodRating;
  final int energyRating;
  final int stressRating;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const MoodLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodRating,
    required this.energyRating,
    required this.stressRating,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class JournalEntry {
  final String id;
  final String userId;
  final JournalType journalType;
  final String? title;
  final String body;
  final String? moodId;
  final DateTime date;
  final String? tags;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.journalType,
    this.title,
    required this.body,
    this.moodId,
    required this.date,
    this.tags,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class SharedGoal {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final double target;
  final double currentProgress;
  final String? unit;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const SharedGoal({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.target,
    this.currentProgress = 0.0,
    this.unit,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class SharedHabit {
  final String id;
  final String coupleId;
  final String title;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const SharedHabit({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.frequency,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class SharedActivity {
  final String id;
  final String coupleId;
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const SharedActivity({
    required this.id,
    required this.coupleId,
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class Memory {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final DateTime date;
  final String? mediaUrl;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const Memory({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.date,
    this.mediaUrl,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

enum ScreenTimeAccessState {
  unknown,
  checking,
  granted,
  denied,
  error,
}

class AppUsage {
  final String packageName;
  final String appName;
  final Duration duration;

  const AppUsage({
    required this.packageName,
    required this.appName,
    required this.duration,
  });
}

class ScreenTimeSummary {
  final DateTime date;
  final Duration totalDuration;
  final int appCount;
  final DateTime lastUpdated;
  final List<AppUsage> topApps;

  const ScreenTimeSummary({
    required this.date,
    required this.totalDuration,
    required this.appCount,
    required this.lastUpdated,
    required this.topApps,
  });
}

class ScreenTimeDay {
  final DateTime date;
  final Duration totalDuration;

  const ScreenTimeDay({
    required this.date,
    required this.totalDuration,
  });
}

enum GoalType {
  habitConsistency,
  studyDuration,
  exerciseDuration,
  waterIntake,
  sleepDuration,
  screenTimeReduction,
  custom,
}

enum DataAvailability {
  available,
  partiallyAvailable,
  unavailable,
}

enum AnalyticsPeriod {
  last7Days,
  last30Days,
  last90Days,
}

class PersonalGoal {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final GoalType goalType;
  final double targetValue;
  final double? currentValue;
  final String? unit;
  final DateTime startDate;
  final DateTime? targetDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const PersonalGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.goalType,
    required this.targetValue,
    this.currentValue,
    this.unit,
    required this.startDate,
    this.targetDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}

class GoalProgress {
  final String goalId;
  final double target;
  final double actual;
  final double progressRatio;
  final int percentage;
  final GoalStatus status;
  final DataAvailability dataAvailability;
  final DateTime calculatedAt;

  const GoalProgress({
    required this.goalId,
    required this.target,
    required this.actual,
    required this.progressRatio,
    required this.percentage,
    required this.status,
    required this.dataAvailability,
    required this.calculatedAt,
  });
}

class ReminderSchedule {
  final String id;
  final String userId;
  final ReminderType type;
  final String title;
  final String body;
  final String? referenceId;
  final DateTime scheduledTime;
  final RecurrenceType recurrenceType;
  final List<int>? daysOfWeek;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const ReminderSchedule({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    required this.scheduledTime,
    required this.recurrenceType,
    this.daysOfWeek,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
  });
}
