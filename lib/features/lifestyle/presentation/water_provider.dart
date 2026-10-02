import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/trackers/presentation/providers.dart';
import 'package:uuid/uuid.dart';

// Provider that guarantees a "Water" tracker exists
final waterTrackerProvider = FutureProvider<Tracker>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) throw Exception('Not authenticated');

  final repo = ref.watch(trackerRepositoryProvider);
  
  // Wait for the stream to emit a value
  final trackers = await repo.watchTrackers(userId).first;
  
  // Find existing Water tracker
  try {
    return trackers.firstWhere((t) => t.name.toLowerCase() == 'water' && t.type == TrackerType.decimal);
  } catch (_) {
    // Doesn't exist, create it
    final newWaterTracker = Tracker(
      id: const Uuid().v4(),
      userId: userId,
      name: 'Water',
      icon: 'water_drop',
      color: 'blue',
      type: TrackerType.decimal,
      unit: 'ml',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    await repo.saveTracker(newWaterTracker);
    return newWaterTracker;
  }
});

// Watch logs for today
final todayWaterLogsProvider = StreamProvider<List<TrackerLog>>((ref) {
  final waterTrackerAsync = ref.watch(waterTrackerProvider);
  
  return waterTrackerAsync.when(
    data: (tracker) {
      final repo = ref.watch(trackerRepositoryProvider);
      final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Need a custom query if watchLogsForTrackerDate range isn't available, but we can filter memory
      return repo.watchLogsForTracker(tracker.id).map((logs) {
        return logs.where((log) => 
          log.timestamp.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
          log.timestamp.isBefore(endOfDay)
        ).toList();
      });
    },
    loading: () => Stream.value([]),
    error: (e, st) => Stream.value([]),
  );
});

// Aggregate today's total
final todayWaterTotalProvider = Provider<double>((ref) {
  final logs = ref.watch(todayWaterLogsProvider).value ?? [];
  return logs.fold(0.0, (sum, log) => sum + (log.valueNum ?? 0.0));
});

// Configure daily target (configurable in future, hardcoded 2500 ml for MVP)
final dailyWaterGoalProvider = Provider<double>((ref) {
  return 2500.0;
});
