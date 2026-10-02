import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/us/data/us_repository.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/us/data/couple_api.dart';

final usRepositoryProvider = Provider<UsRepository>((ref) {
  return UsRepositoryImpl(db.AppDatabase(), ref.read(coupleApiProvider));
});

final currentCoupleProvider = FutureProvider<Couple?>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  if (user == null) return null;
  return ref.read(usRepositoryProvider).getCurrentCouple(user.id);
});

final partnerProvider = FutureProvider<User?>((ref) async {
  final user = ref.watch(authNotifierProvider).user;
  if (user == null) return null;
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) return null;
  return ref.read(usRepositoryProvider).getPartner(user.id, couple.id);
});

final sharedGoalsProvider = StreamProvider<List<SharedGoal>>((ref) async* {
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) {
    yield [];
    return;
  }
  yield* ref.watch(usRepositoryProvider).watchSharedGoals(couple.id);
});

final memoriesProvider = StreamProvider<List<Memory>>((ref) async* {
  final couple = await ref.watch(currentCoupleProvider.future);
  if (couple == null) {
    yield [];
    return;
  }
  yield* ref.watch(usRepositoryProvider).watchMemories(couple.id);
});
