import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/trackers/data/tracker_repository.dart';

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final database = db.AppDatabase();
  return TrackerRepositoryImpl(database);
});

final trackersListProvider = StreamProvider<List<Tracker>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(trackerRepositoryProvider);
  return repo.watchTrackers(userId);
});

final trackerLogsProvider = StreamProvider.family<List<TrackerLog>, String>((ref, trackerId) {
  final repo = ref.watch(trackerRepositoryProvider);
  return repo.watchLogsForTracker(trackerId);
});
