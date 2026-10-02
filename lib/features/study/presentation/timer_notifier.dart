import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StudyTimerStatus { idle, running, paused, completed }

class StudyTimerState {
  final StudyTimerStatus status;
  final String? subjectId;
  final DateTime? startedAt;
  final Duration accumulatedPausedDuration;
  final DateTime? lastPausedAt;

  const StudyTimerState({
    this.status = StudyTimerStatus.idle,
    this.subjectId,
    this.startedAt,
    this.accumulatedPausedDuration = Duration.zero,
    this.lastPausedAt,
  });

  StudyTimerState copyWith({
    StudyTimerStatus? status,
    String? subjectId,
    DateTime? startedAt,
    Duration? accumulatedPausedDuration,
    DateTime? lastPausedAt,
  }) {
    return StudyTimerState(
      status: status ?? this.status,
      subjectId: subjectId ?? this.subjectId,
      startedAt: startedAt ?? this.startedAt,
      accumulatedPausedDuration: accumulatedPausedDuration ?? this.accumulatedPausedDuration,
      lastPausedAt: lastPausedAt ?? this.lastPausedAt,
    );
  }

  Duration get currentDuration {
    if (status == StudyTimerStatus.idle || startedAt == null) {
      return Duration.zero;
    }
    
    if (status == StudyTimerStatus.paused && lastPausedAt != null) {
      return lastPausedAt!.difference(startedAt!) - accumulatedPausedDuration;
    }
    
    if (status == StudyTimerStatus.running) {
      return DateTime.now().difference(startedAt!) - accumulatedPausedDuration;
    }
    
    return Duration.zero;
  }
}

class StudyTimerNotifier extends Notifier<StudyTimerState> {
  Timer? _ticker;
  
  @override
  StudyTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const StudyTimerState();
  }

  void start(String subjectId) {
    if (state.status != StudyTimerStatus.idle) return;

    state = StudyTimerState(
      status: StudyTimerStatus.running,
      subjectId: subjectId,
      startedAt: DateTime.now(),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != StudyTimerStatus.running) return;

    _ticker?.cancel();
    state = state.copyWith(
      status: StudyTimerStatus.paused,
      lastPausedAt: DateTime.now(),
    );
  }

  void resume() {
    if (state.status != StudyTimerStatus.paused || state.lastPausedAt == null) return;

    final pausedDuration = DateTime.now().difference(state.lastPausedAt!);
    state = state.copyWith(
      status: StudyTimerStatus.running,
      accumulatedPausedDuration: state.accumulatedPausedDuration + pausedDuration,
      lastPausedAt: null, // Clear this as we are running
    );
    _startTicker();
  }

  void complete() {
    _ticker?.cancel();
    state = state.copyWith(status: StudyTimerStatus.completed);
  }
  
  void reset() {
    _ticker?.cancel();
    state = const StudyTimerState();
  }

  void _startTicker() {
    _ticker?.cancel();
    // Ticker only exists to force UI rebuilds every second
    // The actual duration is calculated via timestamps in state.currentDuration
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Re-assigning state to trigger listeners. 
      // The state object properties haven't changed, but riverpod needs a new instance or a notification.
      // Since we rely on getters for currentDuration, we can just trigger a rebuild by replacing state.
      state = state.copyWith();
    });
  }
}
