import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../config/app_config.dart';
import '../../features/activities/data/activity_repository.dart';
import '../../features/habits/data/habit_repository.dart';
import '../../features/trackers/data/tracker_repository.dart';
import '../../features/study/data/study_repository.dart';
import '../../features/lifestyle/data/lifestyle_repositories.dart';
import '../../features/journal/data/journal_repository.dart';
import '../../features/wellbeing/data/mood_repository.dart';
import '../../features/goals/data/personal_goal_repository.dart';
import '../../features/screen_time/data/screen_time_repository.dart';
import '../../features/us/data/us_repository.dart';
import '../../features/us/data/couple_api.dart';
import '../database/enums.dart';
import 'dtos.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    ref.read(databaseProvider),
    ref.read(dioClientProvider),
    ActivityRepositoryImpl(ref.read(databaseProvider)),
    HabitRepositoryImpl(ref.read(databaseProvider)),
    TrackerRepositoryImpl(ref.read(databaseProvider)),
    StudyRepositoryImpl(ref.read(databaseProvider)),
    MealRepositoryImpl(ref.read(databaseProvider)),
    SleepRepositoryImpl(ref.read(databaseProvider)),
    ExerciseRepositoryImpl(ref.read(databaseProvider)),
    JournalRepositoryImpl(ref.read(databaseProvider)),
    MoodRepositoryImpl(ref.read(databaseProvider)),
    PersonalGoalRepositoryImpl(ref.read(databaseProvider)),
    ScreenTimeRepositoryImpl(ref.read(databaseProvider)),
    UsRepositoryImpl(ref.read(databaseProvider), ref.read(coupleApiProvider)),
  );
});

class SyncEngine {
  final AppDatabase _db;
  final DioClient _dioClient;
  final ActivityRepository _activityRepo;
  final HabitRepository _habitRepo;
  final TrackerRepository _trackerRepo;
  final StudyRepository _studyRepo;
  final MealRepository _mealRepo;
  final SleepRepository _sleepRepo;
  final ExerciseRepository _exerciseRepo;
  final JournalRepository _journalRepo;
  final MoodRepository _moodRepo;
  final PersonalGoalRepository _goalRepo;
  final ScreenTimeRepository _screenTimeRepo;
  final UsRepository _usRepo;

  static const String _cursorKey = 'sync_cursor';
  static const String _deviceIdKey = 'device_id';

  SyncEngine(
    this._db,
    this._dioClient,
    this._activityRepo,
    this._habitRepo,
    this._trackerRepo,
    this._studyRepo,
    this._mealRepo,
    this._sleepRepo,
    this._exerciseRepo,
    this._journalRepo,
    this._moodRepo,
    this._goalRepo,
    this._screenTimeRepo,
    this._usRepo,
  );

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  Future<void> push() async {
    if (AppConfig.useMockAuth) return;
    
    final pendingOps = await _db.select(_db.syncQueueTable).get();
    if (pendingOps.isEmpty) return;

    // Filter couple operations if not in active couple
    final coupleRecord = await (_db.select(_db.couplesTable)..limit(1)).getSingleOrNull();
    final isCoupleActive = coupleRecord != null && coupleRecord.status == CoupleStatus.active;
    final activeCoupleId = isCoupleActive ? coupleRecord.id : null;

    final deviceId = await _getDeviceId();
    
    final operationsPayload = pendingOps.where((op) {
      if (op.scopeType == 'couple') {
        return isCoupleActive && op.scopeId == activeCoupleId;
      }
      return true;
    }).map((op) {
      return {
        'entity_type': op.entityType,
        'entity_id': op.entityId,
        'scope_type': op.scopeType,
        'scope_id': op.scopeId,
        'operation': op.operation,
        'changed_at': op.createdAt.toUtc().toIso8601String(),
        'payload': op.payload != null ? jsonDecode(op.payload!) : null,
        'is_deleted': op.operation == 'delete',
      };
    }).toList();
    
    if (operationsPayload.isEmpty) return;

    try {
      final response = await _dioClient.dio.post('/sync/push', data: {
        'device_id': deviceId,
        'operations': operationsPayload,
      });

      if (response.statusCode == 200) {
        await _db.delete(_db.syncQueueTable).go();
      }
    } catch (e) {
      // Keep in queue for next time
    }
  }

  Future<void> pull() async {
    if (AppConfig.useMockAuth) return;
    
    final prefs = await SharedPreferences.getInstance();
    final cursor = prefs.getInt(_cursorKey) ?? 0;
    
    try {
      final response = await _dioClient.dio.get(
        '/sync/pull',
        queryParameters: {'cursor': cursor},
      );
      
      final data = response.data;
      final changes = data['changes'] as List<dynamic>;
      final newCursor = data['cursor'] as int;
      
      if (changes.isEmpty) return;

      // Dependency ordering: Parents before children
      final orderMap = {
        'tracker': 0,
        'habit': 1,
        'activity': 1,
        'study_subject': 1,
        'meal': 1,
        'sleep_record': 1,
        'exercise_session': 1,
        'mood_log': 1,
        'journal_entry': 1,
        'personal_goal': 1,
        'screen_time_daily_snapshot': 1,
        'shared_goal': 1,
        'shared_habit': 1,
        'shared_activity': 1,
        'memory': 1,
        'tracker_log': 2,
        'habit_log': 2,
        'study_session': 2,
        'meal_item': 2,
      };

      changes.sort((a, b) {
        final orderA = orderMap[a['entity_type']] ?? 99;
        final orderB = orderMap[b['entity_type']] ?? 99;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return (a['version'] as int).compareTo(b['version'] as int);
      });

      // Apply changes within a single transaction so failure rolls back everything
      await _db.transaction(() async {
        for (var change in changes) {
          final entityType = change['entity_type'];
          final operation = change['operation'];
          final payload = change['payload'];

          if (payload == null && operation != 'delete') continue;
          
          final safePayload = payload ?? {'id': change['entity_id']}; // For delete
          // Set updated_at for delete DTO fallback
          if (operation == 'delete' && !safePayload.containsKey('updated_at')) {
            safePayload['updated_at'] = change['changed_at'];
          }

          try {
            switch (entityType) {
              case 'tracker':
                final dto = TrackerDto.fromJson(safePayload);
                await _trackerRepo.applyRemoteTrackerChange(dto, operation);
                break;
              case 'tracker_log':
                final dto = TrackerLogDto.fromJson(safePayload);
                await _trackerRepo.applyRemoteTrackerLogChange(dto, operation);
                break;
              case 'habit':
                final dto = HabitDto.fromJson(safePayload);
                await _habitRepo.applyRemoteHabitChange(dto, operation);
                break;
              case 'habit_log':
                final dto = HabitLogDto.fromJson(safePayload);
                await _habitRepo.applyRemoteHabitLogChange(dto, operation);
                break;
              case 'activity':
                final dto = ActivityDto.fromJson(safePayload);
                await _activityRepo.applyRemoteChange(dto, operation);
                break;
              case 'study_subject':
                if (operation == 'delete') {
                  await _studyRepo.applyRemoteSubjectDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = StudySubjectDto.fromJson(safePayload);
                  await _studyRepo.applyRemoteSubjectChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'study_session':
                if (operation == 'delete') {
                  await _studyRepo.applyRemoteSessionDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = StudySessionDto.fromJson(safePayload);
                  await _studyRepo.applyRemoteSessionChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'meal':
                if (operation == 'delete') {
                  await _mealRepo.applyRemoteMealDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = MealDto.fromJson(safePayload);
                  await _mealRepo.applyRemoteMealChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'meal_item':
                if (operation == 'delete') {
                  await _mealRepo.applyRemoteMealItemDelete(change['entity_id']);
                } else {
                  final dto = MealItemDto.fromJson(safePayload);
                  await _mealRepo.applyRemoteMealItemChange(dto.toDomain());
                }
                break;
              case 'sleep_record':
                if (operation == 'delete') {
                  await _sleepRepo.applyRemoteSleepDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = SleepRecordDto.fromJson(safePayload);
                  await _sleepRepo.applyRemoteSleepChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'exercise_session':
                if (operation == 'delete') {
                  await _exerciseRepo.applyRemoteExerciseDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = ExerciseSessionDto.fromJson(safePayload);
                  await _exerciseRepo.applyRemoteExerciseChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'mood_log':
                if (operation == 'delete') {
                  await _moodRepo.applyRemoteMoodDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = MoodLogDto.fromJson(safePayload);
                  await _moodRepo.applyRemoteMoodChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'journal_entry':
                if (operation == 'delete') {
                  await _journalRepo.applyRemoteJournalDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = JournalEntryDto.fromJson(safePayload);
                  await _journalRepo.applyRemoteJournalChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'personal_goal':
                if (operation == 'delete') {
                  await _goalRepo.applyRemotePersonalGoalDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = PersonalGoalDto.fromJson(safePayload);
                  await _goalRepo.applyRemotePersonalGoalChange(dto.toDomain(SyncStatus.synced));
                }
                break;
              case 'screen_time_daily_snapshot':
                if (operation == 'delete') {
                  await _screenTimeRepo.applyRemoteScreenTimeSnapshotDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = ScreenTimeDailySnapshotDto.fromJson(safePayload);
                  await _screenTimeRepo.applyRemoteScreenTimeSnapshotChange(dto);
                }
                break;
              case 'shared_goal':
                if (operation == 'delete') {
                  await _usRepo.applyRemoteSharedGoalDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = SharedGoalDto.fromJson(safePayload);
                  await _usRepo.applyRemoteSharedGoalChange(dto.toDomain());
                }
                break;
              case 'shared_habit':
                if (operation == 'delete') {
                  await _usRepo.applyRemoteSharedHabitDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = SharedHabitDto.fromJson(safePayload);
                  await _usRepo.applyRemoteSharedHabitChange(dto.toDomain());
                }
                break;
              case 'shared_activity':
                if (operation == 'delete') {
                  await _usRepo.applyRemoteSharedActivityDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = SharedActivityDto.fromJson(safePayload);
                  await _usRepo.applyRemoteSharedActivityChange(dto.toDomain());
                }
                break;
              case 'memory':
                if (operation == 'delete') {
                  await _usRepo.applyRemoteMemoryDelete(change['entity_id'], DateTime.parse(safePayload['updated_at']));
                } else {
                  final dto = MemoryDto.fromJson(safePayload);
                  await _usRepo.applyRemoteMemoryChange(dto.toDomain());
                }
                break;
            }
          } catch (e) {
            // Rethrowing will rollback the transaction
            throw Exception('Failed applying $entityType: $e');
          }
        }
      });

      // Advance cursor only if transaction succeeded
      await prefs.setInt(_cursorKey, newCursor);
    } catch (e) {
      // Rollback occurred or network failed, ignore and try again later
    }
  }
  
  Future<void> sync() async {
    await push();
    await pull();
  }
}

