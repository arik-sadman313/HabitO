import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

class TrackerDto {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final String type;
  final String? unit;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  TrackerDto({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.unit,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory TrackerDto.fromDomain(Tracker domain) {
    return TrackerDto(
      id: domain.id,
      userId: domain.userId,
      name: domain.name,
      icon: domain.icon,
      color: domain.color,
      type: domain.type.name,
      unit: domain.unit,
      isShared: domain.isShared,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  Tracker toDomain(SyncStatus syncStatus) {
    return Tracker(
      id: id,
      userId: userId,
      name: name,
      icon: icon,
      color: color,
      type: TrackerType.values.firstWhere((e) => e.name == type, orElse: () => TrackerType.boolean),
      unit: unit,
      isShared: isShared,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'unit': unit,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory TrackerDto.fromJson(Map<String, dynamic> json) {
    return TrackerDto(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      type: json['type'],
      unit: json['unit'],
      isShared: json['is_shared'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class TrackerLogDto {
  final String id;
  final String trackerId;
  final String userId;
  final DateTime timestamp;
  final double? valueNum;
  final String? valueText;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  TrackerLogDto({
    required this.id,
    required this.trackerId,
    required this.userId,
    required this.timestamp,
    this.valueNum,
    this.valueText,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory TrackerLogDto.fromDomain(TrackerLog domain) {
    return TrackerLogDto(
      id: domain.id,
      trackerId: domain.trackerId,
      userId: domain.userId,
      timestamp: domain.timestamp,
      valueNum: domain.valueNum,
      valueText: domain.valueText,
      notes: domain.notes,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  TrackerLog toDomain(SyncStatus syncStatus) {
    return TrackerLog(
      id: id,
      trackerId: trackerId,
      userId: userId,
      timestamp: timestamp,
      valueNum: valueNum,
      valueText: valueText,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracker_id': trackerId,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'value_num': valueNum,
      'value_text': valueText,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory TrackerLogDto.fromJson(Map<String, dynamic> json) {
    return TrackerLogDto(
      id: json['id'],
      trackerId: json['tracker_id'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      valueNum: (json['value_num'] as num?)?.toDouble(),
      valueText: json['value_text'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class HabitDto {
  final String id;
  final String userId;
  final String trackerId;
  final String title;
  final String? description;
  final String frequency;
  final double targetValue;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  HabitDto({
    required this.id,
    required this.userId,
    required this.trackerId,
    required this.title,
    this.description,
    required this.frequency,
    required this.targetValue,
    required this.startDate,
    this.endDate,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory HabitDto.fromDomain(Habit domain) {
    return HabitDto(
      id: domain.id,
      userId: domain.userId,
      trackerId: domain.trackerId,
      title: domain.title,
      description: domain.description,
      frequency: domain.frequency.name,
      targetValue: domain.targetValue,
      startDate: domain.startDate,
      endDate: domain.endDate,
      isShared: domain.isShared,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  Habit toDomain(SyncStatus syncStatus) {
    return Habit(
      id: id,
      userId: userId,
      trackerId: trackerId,
      title: title,
      description: description,
      frequency: HabitFrequency.values.firstWhere((e) => e.name == frequency, orElse: () => HabitFrequency.daily),
      targetValue: targetValue,
      startDate: startDate,
      endDate: endDate,
      isShared: isShared,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tracker_id': trackerId,
      'title': title,
      'description': description,
      'frequency': frequency,
      'target_value': targetValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory HabitDto.fromJson(Map<String, dynamic> json) {
    return HabitDto(
      id: json['id'],
      userId: json['user_id'],
      trackerId: json['tracker_id'],
      title: json['title'],
      description: json['description'],
      frequency: json['frequency'],
      targetValue: (json['target_value'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isShared: json['is_shared'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class HabitLogDto {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool isCompleted;
  final double progressValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  HabitLogDto({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.isCompleted,
    required this.progressValue,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory HabitLogDto.fromDomain(HabitLog domain) {
    return HabitLogDto(
      id: domain.id,
      habitId: domain.habitId,
      userId: domain.userId,
      date: domain.date,
      isCompleted: domain.isCompleted,
      progressValue: domain.progressValue,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: false, // HabitLog does not have isDeleted in flutter yet, just implicitly false.
    );
  }

  HabitLog toDomain(SyncStatus syncStatus) {
    return HabitLog(
      id: id,
      habitId: habitId,
      userId: userId,
      date: date,
      isCompleted: isCompleted,
      progressValue: progressValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'progress_value': progressValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory HabitLogDto.fromJson(Map<String, dynamic> json) {
    return HabitLogDto(
      id: json['id'],
      habitId: json['habit_id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      isCompleted: json['is_completed'] ?? false,
      progressValue: (json['progress_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class ActivityDto {
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
  final bool isDeleted;

  ActivityDto({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    required this.scheduledStart,
    this.scheduledEnd,
    required this.isCompleted,
    this.category,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory ActivityDto.fromDomain(Activity domain) {
    return ActivityDto(
      id: domain.id,
      userId: domain.userId,
      title: domain.title,
      notes: domain.notes,
      scheduledStart: domain.scheduledStart,
      scheduledEnd: domain.scheduledEnd,
      isCompleted: domain.isCompleted,
      category: domain.category,
      isShared: domain.isShared,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  Activity toDomain(SyncStatus syncStatus) {
    return Activity(
      id: id,
      userId: userId,
      title: title,
      notes: notes,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      isCompleted: isCompleted,
      category: category,
      isShared: isShared,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd?.toIso8601String(),
      'is_completed': isCompleted,
      'category': category,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      notes: json['notes'],
      scheduledStart: DateTime.parse(json['scheduled_start']),
      scheduledEnd: json['scheduled_end'] != null ? DateTime.parse(json['scheduled_end']) : null,
      isCompleted: json['is_completed'] ?? false,
      category: json['category'],
      isShared: json['is_shared'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class StudySubjectDto {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  StudySubjectDto({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory StudySubjectDto.fromDomain(StudySubject domain) {
    return StudySubjectDto(
      id: domain.id,
      userId: domain.userId,
      name: domain.name,
      description: domain.description,
      icon: domain.icon,
      color: domain.color,
      isActive: domain.isActive,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  StudySubject toDomain(SyncStatus syncStatus) {
    return StudySubject(
      id: id,
      userId: userId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory StudySubjectDto.fromJson(Map<String, dynamic> json) {
    return StudySubjectDto(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class StudySessionDto {
  final String id;
  final String userId;
  final String subjectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int duration;
  final String? notes;
  final String? sessionType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  StudySessionDto({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    this.notes,
    this.sessionType,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory StudySessionDto.fromDomain(StudySession domain) {
    return StudySessionDto(
      id: domain.id,
      userId: domain.userId,
      subjectId: domain.subjectId,
      startedAt: domain.startedAt,
      endedAt: domain.endedAt,
      duration: domain.duration,
      notes: domain.notes,
      sessionType: domain.sessionType,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  StudySession toDomain(SyncStatus syncStatus) {
    return StudySession(
      id: id,
      userId: userId,
      subjectId: subjectId,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: duration,
      notes: notes,
      sessionType: sessionType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject_id': subjectId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'session_type': sessionType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory StudySessionDto.fromJson(Map<String, dynamic> json) {
    return StudySessionDto(
      id: json['id'],
      userId: json['user_id'],
      subjectId: json['subject_id'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      duration: (json['duration'] as num).toInt(),
      notes: json['notes'],
      sessionType: json['session_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class MealDto {
  final String id;
  final String userId;
  final String mealType;
  final DateTime recordedAt;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  MealDto({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.recordedAt,
    this.notes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory MealDto.fromDomain(Meal domain) {
    return MealDto(
      id: domain.id,
      userId: domain.userId,
      mealType: domain.mealType,
      recordedAt: domain.recordedAt,
      notes: domain.notes,
      photoUrl: domain.photoUrl,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  Meal toDomain(SyncStatus syncStatus, [List<MealItem> items = const []]) {
    return Meal(
      id: id,
      userId: userId,
      mealType: mealType,
      recordedAt: recordedAt,
      notes: notes,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory MealDto.fromJson(Map<String, dynamic> json) {
    return MealDto(
      id: json['id'],
      userId: json['user_id'],
      mealType: json['meal_type'],
      recordedAt: DateTime.parse(json['recorded_at']),
      notes: json['notes'],
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class MealItemDto {
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  MealItemDto({
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
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory MealItemDto.fromDomain(MealItem domain) {
    return MealItemDto(
      id: domain.id,
      mealId: domain.mealId,
      name: domain.name,
      quantity: domain.quantity,
      unit: domain.unit,
      calories: domain.calories,
      protein: domain.protein,
      carbs: domain.carbs,
      fat: domain.fat,
      notes: domain.notes,
      createdAt: DateTime.now().toUtc(), // Not maintained in MealItem local schema
      updatedAt: DateTime.now().toUtc(),
      isDeleted: false,
    );
  }

  MealItem toDomain() {
    return MealItem(
      id: id,
      mealId: mealId,
      name: name,
      quantity: quantity,
      unit: unit,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory MealItemDto.fromJson(Map<String, dynamic> json) {
    return MealItemDto(
      id: json['id'],
      mealId: json['meal_id'],
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      calories: json['calories'] != null ? (json['calories'] as num).toDouble() : null,
      protein: json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
      fat: json['fat'] != null ? (json['fat'] as num).toDouble() : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now().toUtc(),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class SleepRecordDto {
  final String id;
  final String userId;
  final DateTime sleepStart;
  final DateTime wakeTime;
  final int duration;
  final int quality;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SleepRecordDto({
    required this.id,
    required this.userId,
    required this.sleepStart,
    required this.wakeTime,
    required this.duration,
    required this.quality,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SleepRecordDto.fromDomain(SleepRecord domain) {
    return SleepRecordDto(
      id: domain.id,
      userId: domain.userId,
      sleepStart: domain.sleepStart,
      wakeTime: domain.wakeTime,
      duration: domain.duration,
      quality: domain.quality,
      notes: domain.notes,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  SleepRecord toDomain(SyncStatus syncStatus) {
    return SleepRecord(
      id: id,
      userId: userId,
      sleepStart: sleepStart,
      wakeTime: wakeTime,
      duration: duration,
      quality: quality,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sleep_start': sleepStart.toIso8601String(),
      'wake_time': wakeTime.toIso8601String(),
      'duration': duration,
      'quality': quality,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory SleepRecordDto.fromJson(Map<String, dynamic> json) {
    return SleepRecordDto(
      id: json['id'],
      userId: json['user_id'],
      sleepStart: DateTime.parse(json['sleep_start']),
      wakeTime: DateTime.parse(json['wake_time']),
      duration: (json['duration'] as num).toInt(),
      quality: (json['quality'] as num).toInt(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class ExerciseSessionDto {
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
  final bool isDeleted;

  ExerciseSessionDto({
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
    required this.isDeleted,
  });

  factory ExerciseSessionDto.fromDomain(ExerciseSession domain) {
    return ExerciseSessionDto(
      id: domain.id,
      userId: domain.userId,
      exerciseType: domain.exerciseType,
      startedAt: domain.startedAt,
      endedAt: domain.endedAt,
      duration: domain.duration,
      distance: domain.distance,
      calories: domain.calories,
      notes: domain.notes,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  ExerciseSession toDomain(SyncStatus syncStatus) {
    return ExerciseSession(
      id: id,
      userId: userId,
      exerciseType: exerciseType,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: duration,
      distance: distance,
      calories: calories,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_type': exerciseType,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration': duration,
      'distance': distance,
      'calories': calories,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory ExerciseSessionDto.fromJson(Map<String, dynamic> json) {
    return ExerciseSessionDto(
      id: json['id'],
      userId: json['user_id'],
      exerciseType: json['exercise_type'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: DateTime.parse(json['ended_at']),
      duration: (json['duration'] as num).toInt(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      calories: json['calories'] != null ? (json['calories'] as num).toInt() : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class MoodLogDto {
  final String id;
  final String userId;
  final DateTime date;
  final int moodRating;
  final int energyRating;
  final int stressRating;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  MoodLogDto({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodRating,
    required this.energyRating,
    required this.stressRating,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory MoodLogDto.fromDomain(MoodLog domain) {
    return MoodLogDto(
      id: domain.id,
      userId: domain.userId,
      date: domain.date,
      moodRating: domain.moodRating,
      energyRating: domain.energyRating,
      stressRating: domain.stressRating,
      note: domain.note,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  MoodLog toDomain(SyncStatus syncStatus) {
    return MoodLog(
      id: id,
      userId: userId,
      date: date,
      moodRating: moodRating,
      energyRating: energyRating,
      stressRating: stressRating,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'mood_rating': moodRating,
      'energy_rating': energyRating,
      'stress_rating': stressRating,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory MoodLogDto.fromJson(Map<String, dynamic> json) {
    return MoodLogDto(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      moodRating: (json['mood_rating'] as num).toInt(),
      energyRating: (json['energy_rating'] as num).toInt(),
      stressRating: (json['stress_rating'] as num).toInt(),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class JournalEntryDto {
  final String id;
  final String userId;
  final int journalType; // JournalType enum index: 0=personal, 1=shared
  final String? title;
  final String body;
  final String? moodId;
  final DateTime date;
  final String? tags;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  JournalEntryDto({
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
    required this.isDeleted,
  });

  factory JournalEntryDto.fromDomain(JournalEntry domain) {
    return JournalEntryDto(
      id: domain.id,
      userId: domain.userId,
      journalType: domain.journalType.index,
      title: domain.title,
      body: domain.body,
      moodId: domain.moodId,
      date: domain.date,
      tags: domain.tags,
      photoUrl: domain.photoUrl,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  JournalEntry toDomain(SyncStatus syncStatus) {
    return JournalEntry(
      id: id,
      userId: userId,
      journalType: JournalType.values[journalType],
      title: title,
      body: body,
      moodId: moodId,
      date: date,
      tags: tags,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'journal_type': journalType,
      'title': title,
      'body': body,
      'mood_id': moodId,
      'date': date.toIso8601String(),
      'tags': tags,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory JournalEntryDto.fromJson(Map<String, dynamic> json) {
    return JournalEntryDto(
      id: json['id'],
      userId: json['user_id'],
      journalType: (json['journal_type'] as num).toInt(),
      title: json['title'],
      body: json['body'],
      moodId: json['mood_id'],
      date: DateTime.parse(json['date']),
      tags: json['tags'],
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class PersonalGoalDto {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String goalType;
  final double targetValue;
  final double? currentValue;
  final String? unit;
  final DateTime startDate;
  final DateTime? targetDate;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  PersonalGoalDto({
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
    required this.isDeleted,
  });

  factory PersonalGoalDto.fromDomain(PersonalGoal domain) {
    return PersonalGoalDto(
      id: domain.id,
      userId: domain.userId,
      title: domain.title,
      description: domain.description,
      goalType: domain.goalType.name,
      targetValue: domain.targetValue,
      currentValue: domain.currentValue,
      unit: domain.unit,
      startDate: domain.startDate,
      targetDate: domain.targetDate,
      status: domain.status.index,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
      isDeleted: domain.isDeleted,
    );
  }

  PersonalGoal toDomain(SyncStatus syncStatus) {
    return PersonalGoal(
      id: id,
      userId: userId,
      title: title,
      description: description,
      goalType: GoalType.values.firstWhere((e) => e.name == goalType, orElse: () => GoalType.custom),
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      startDate: startDate,
      targetDate: targetDate,
      status: GoalStatus.values[status],
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'goal_type': goalType,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory PersonalGoalDto.fromJson(Map<String, dynamic> json) {
    return PersonalGoalDto(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      goalType: json['goal_type'],
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: json['current_value'] != null ? (json['current_value'] as num).toDouble() : null,
      unit: json['unit'],
      startDate: DateTime.parse(json['start_date']),
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      status: (json['status'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class ScreenTimeDailySnapshotDto {
  final String id;
  final String userId;
  final DateTime date;
  final int totalDurationSeconds;
  final int appCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  ScreenTimeDailySnapshotDto({
    required this.id,
    required this.userId,
    required this.date,
    required this.totalDurationSeconds,
    required this.appCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'total_duration_seconds': totalDurationSeconds,
      'app_count': appCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory ScreenTimeDailySnapshotDto.fromJson(Map<String, dynamic> json) {
    return ScreenTimeDailySnapshotDto(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      totalDurationSeconds: (json['total_duration_seconds'] as num).toInt(),
      appCount: (json['app_count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class SharedGoalDto {
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
  final bool isDeleted;

  SharedGoalDto({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.target,
    required this.currentProgress,
    this.unit,
    this.deadline,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SharedGoalDto.fromDomain(SharedGoal goal) {
    return SharedGoalDto(
      id: goal.id,
      coupleId: goal.coupleId,
      title: goal.title,
      description: goal.description,
      target: goal.target,
      currentProgress: goal.currentProgress,
      unit: goal.unit,
      deadline: goal.deadline,
      isCompleted: goal.isCompleted,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      isDeleted: goal.isDeleted,
    );
  }

  SharedGoal toDomain() {
    return SharedGoal(
      id: id,
      coupleId: coupleId,
      title: title,
      description: description,
      target: target,
      currentProgress: currentProgress,
      unit: unit,
      deadline: deadline,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'target': target,
      'current_progress': currentProgress,
      'unit': unit,
      'deadline': deadline?.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory SharedGoalDto.fromJson(Map<String, dynamic> json) {
    return SharedGoalDto(
      id: json['id'],
      coupleId: json['couple_id'],
      title: json['title'],
      description: json['description'],
      target: (json['target'] as num).toDouble(),
      currentProgress: (json['current_progress'] as num).toDouble(),
      unit: json['unit'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class SharedHabitDto {
  final String id;
  final String coupleId;
  final String title;
  final int frequency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SharedHabitDto({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.frequency,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SharedHabitDto.fromDomain(SharedHabit habit) {
    return SharedHabitDto(
      id: habit.id,
      coupleId: habit.coupleId,
      title: habit.title,
      frequency: habit.frequency.index,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
      isDeleted: habit.isDeleted,
    );
  }

  SharedHabit toDomain() {
    return SharedHabit(
      id: id,
      coupleId: coupleId,
      title: title,
      frequency: HabitFrequency.values[frequency],
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory SharedHabitDto.fromJson(Map<String, dynamic> json) {
    return SharedHabitDto(
      id: json['id'],
      coupleId: json['couple_id'],
      title: json['title'],
      frequency: (json['frequency'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class SharedActivityDto {
  final String id;
  final String coupleId;
  final String title;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  SharedActivityDto({
    required this.id,
    required this.coupleId,
    required this.title,
    this.notes,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SharedActivityDto.fromDomain(SharedActivity activity) {
    return SharedActivityDto(
      id: activity.id,
      coupleId: activity.coupleId,
      title: activity.title,
      notes: activity.notes,
      startTime: activity.startTime,
      endTime: activity.endTime,
      isCompleted: activity.isCompleted,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
      isDeleted: activity.isDeleted,
    );
  }

  SharedActivity toDomain() {
    return SharedActivity(
      id: id,
      coupleId: coupleId,
      title: title,
      notes: notes,
      startTime: startTime,
      endTime: endTime,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'notes': notes,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory SharedActivityDto.fromJson(Map<String, dynamic> json) {
    return SharedActivityDto(
      id: json['id'],
      coupleId: json['couple_id'],
      title: json['title'],
      notes: json['notes'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class MemoryDto {
  final String id;
  final String coupleId;
  final String title;
  final String? description;
  final DateTime date;
  final String? mediaUrl;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  MemoryDto({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    required this.date,
    this.mediaUrl,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory MemoryDto.fromDomain(Memory memory) {
    return MemoryDto(
      id: memory.id,
      coupleId: memory.coupleId,
      title: memory.title,
      description: memory.description,
      date: memory.date,
      mediaUrl: memory.mediaUrl,
      tags: memory.tags,
      createdAt: memory.createdAt,
      updatedAt: memory.updatedAt,
      isDeleted: memory.isDeleted,
    );
  }

  Memory toDomain() {
    return Memory(
      id: id,
      coupleId: coupleId,
      title: title,
      description: description,
      date: date,
      mediaUrl: mediaUrl,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.synced,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'couple_id': coupleId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'media_url': mediaUrl,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory MemoryDto.fromJson(Map<String, dynamic> json) {
    return MemoryDto(
      id: json['id'],
      coupleId: json['couple_id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      mediaUrl: json['media_url'],
      tags: json['tags'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}



