import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/screen_time/data/screen_time_repository.dart';
import 'package:habito/core/models/domain_models.dart';
import 'dart:async';

final screenTimeRepositoryProvider = Provider<ScreenTimeRepository>((ref) {
  return ScreenTimeRepositoryImpl(db.AppDatabase());
});

final screenTimeAccessStateProvider = FutureProvider<ScreenTimeAccessState>((ref) async {
  return ref.watch(screenTimeRepositoryProvider).checkAccessState();
});

class TodayScreenTimeNotifier extends Notifier<AsyncValue<ScreenTimeSummary?>> {
  @override
  AsyncValue<ScreenTimeSummary?> build() {
    _refresh();
    final timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    ref.onDispose(() => timer.cancel());
    return const AsyncValue.loading();
  }

  Future<void> _refresh() async {
    final repo = ref.read(screenTimeRepositoryProvider);
    final user = ref.read(authNotifierProvider).user;
    
    try {
      state = const AsyncValue.loading();
      final summary = await repo.getTodaySummary();
      
      if (summary != null && user != null) {
        await repo.syncTodaySnapshot(user.id, summary);
      }
      
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> refresh() => _refresh();
}

final todayScreenTimeProvider = NotifierProvider<TodayScreenTimeNotifier, AsyncValue<ScreenTimeSummary?>>(() {
  return TodayScreenTimeNotifier();
});

final weeklyScreenTimeProvider = FutureProvider<List<ScreenTimeDay>>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  if (user == null) return [];
  // Also watch the today summary so this refreshes when today's data is updated/synced
  ref.watch(todayScreenTimeProvider);
  return ref.watch(screenTimeRepositoryProvider).getWeeklyHistory(user.id);
});
