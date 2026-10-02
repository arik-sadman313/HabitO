import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/us/presentation/providers.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';

class UsState {
  final bool isLoading;
  final String? error;
  final String? inviteCode;

  UsState({this.isLoading = false, this.error, this.inviteCode});

  UsState copyWith({bool? isLoading, String? error, String? inviteCode, bool clearError = false, bool clearInvite = false}) {
    return UsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      inviteCode: clearInvite ? null : (inviteCode ?? this.inviteCode),
    );
  }
}

class UsNotifier extends Notifier<UsState> {
  @override
  UsState build() {
    return UsState();
  }

  Future<void> createCouple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(usRepositoryProvider).createCouple();
      ref.invalidate(currentCoupleProvider);
      ref.invalidate(partnerProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> generateInvite() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ref.read(usRepositoryProvider).generateInvite();
      state = state.copyWith(inviteCode: res['invite_code']);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> joinCouple(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(usRepositoryProvider).joinCouple(code);
      ref.invalidate(currentCoupleProvider);
      ref.invalidate(partnerProvider);
    } catch (e) {
      state = state.copyWith(error: 'Failed to join couple. Check invite code.');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> leaveCouple() async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(usRepositoryProvider).leaveCouple(user.id);
      ref.invalidate(currentCoupleProvider);
      ref.invalidate(partnerProvider);
      state = state.copyWith(clearInvite: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final usNotifierProvider = NotifierProvider<UsNotifier, UsState>(() {
  return UsNotifier();
});
