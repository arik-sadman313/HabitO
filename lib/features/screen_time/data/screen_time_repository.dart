import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:drift/drift.dart';

abstract class ScreenTimeRepository {
  Future<ScreenTimeAccessState> checkAccessState();
  Future<void> requestAccess();
  Future<ScreenTimeSummary?> getTodaySummary();
  Future<List<ScreenTimeDay>> getWeeklyHistory(String userId);
  Future<void> syncTodaySnapshot(String userId, ScreenTimeSummary summary);
}

class ScreenTimeRepositoryImpl implements ScreenTimeRepository {
  static const _channel = MethodChannel('com.habito.habito/screen_time');
  final db.AppDatabase _db;

  ScreenTimeRepositoryImpl(this._db);

  @override
  Future<ScreenTimeAccessState> checkAccessState() async {
    try {
      final bool hasAccess = await _channel.invokeMethod('checkUsageAccess') ?? false;
      return hasAccess ? ScreenTimeAccessState.granted : ScreenTimeAccessState.denied;
    } on PlatformException {
      return ScreenTimeAccessState.error;
    } catch (e) {
      return ScreenTimeAccessState.error;
    }
  }

  @override
  Future<void> requestAccess() async {
    try {
      await _channel.invokeMethod('requestUsageAccess');
    } catch (_) {}
  }

  @override
  Future<ScreenTimeSummary?> getTodaySummary() async {
    final state = await checkAccessState();
    if (state != ScreenTimeAccessState.granted) return null;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    try {
      final String jsonStr = await _channel.invokeMethod('getUsageStats', {
        'startTime': startOfDay.millisecondsSinceEpoch,
        'endTime': now.millisecondsSinceEpoch,
      });

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      
      int totalDurationMs = 0;
      final List<AppUsage> topApps = [];

      for (final item in jsonList) {
        final durationMs = item['duration'] as int;
        totalDurationMs += durationMs;
        topApps.add(AppUsage(
          packageName: item['packageName'] as String,
          appName: item['appName'] as String,
          duration: Duration(milliseconds: durationMs),
        ));
      }

      // Sort apps by duration descending
      topApps.sort((a, b) => b.duration.compareTo(a.duration));

      return ScreenTimeSummary(
        date: startOfDay,
        totalDuration: Duration(milliseconds: totalDurationMs),
        appCount: topApps.length,
        lastUpdated: now,
        topApps: topApps,
      );
    } catch (e) {
      return null; // Silent fail, handle at UI if null and state == granted -> error
    }
  }

  @override
  Future<void> syncTodaySnapshot(String userId, ScreenTimeSummary summary) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Convert to seconds
    final seconds = summary.totalDuration.inSeconds;
    
    // We use a composite id or just find existing
    final existing = await (_db.select(_db.screenTimeDailySnapshotsTable)
          ..where((t) => t.userId.equals(userId) & t.date.equals(startOfDay)))
        .getSingleOrNull();
        
    if (existing != null) {
      await _db.update(_db.screenTimeDailySnapshotsTable).replace(
        existing.copyWith(
          totalDurationSeconds: seconds,
          appCount: summary.appCount,
          updatedAt: now,
        )
      );
    } else {
      await _db.into(_db.screenTimeDailySnapshotsTable).insert(
        db.ScreenTimeDailySnapshotsTableCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()), // Simple UUID alternative
          userId: Value(userId),
          date: Value(startOfDay),
          totalDurationSeconds: Value(seconds),
          appCount: Value(summary.appCount),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        )
      );
    }
  }

  @override
  Future<List<ScreenTimeDay>> getWeeklyHistory(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final aWeekAgo = startOfDay.subtract(const Duration(days: 7));
    
    final records = await (_db.select(_db.screenTimeDailySnapshotsTable)
          ..where((t) => t.userId.equals(userId) & t.date.isBiggerOrEqualValue(aWeekAgo))
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
        
    return records.map((r) => ScreenTimeDay(
      date: r.date,
      totalDuration: Duration(seconds: r.totalDurationSeconds),
    )).toList();
  }
}
