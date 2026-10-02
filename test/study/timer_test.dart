import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/study/presentation/timer_notifier.dart';
import 'package:habito/features/study/presentation/providers.dart';

void main() {
  group('StudyTimerNotifier', () {
    test('Initial state is idle', () {
      final container = ProviderContainer();
      final state = container.read(studyTimerProvider);
      
      expect(state.status, StudyTimerStatus.idle);
      expect(state.currentDuration, Duration.zero);
    });
    
    // We cannot easily test the Provider directly without a container, but we can test the State class logic
    test('State calculates elapsed time based on timestamps, not ticks', () {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 5));
      
      final state = StudyTimerState(
        status: StudyTimerStatus.running,
        subjectId: 'sub1',
        startedAt: startedAt,
      );
      
      // Elapsed should be ~5 minutes
      expect(state.currentDuration.inMinutes, 5);
    });
    
    test('Paused state locks the elapsed time', () {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 10));
      final pausedAt = DateTime.now().subtract(const Duration(minutes: 5));
      
      // Ran for 5 minutes, then paused 5 minutes ago
      final state = StudyTimerState(
        status: StudyTimerStatus.paused,
        subjectId: 'sub1',
        startedAt: startedAt,
        lastPausedAt: pausedAt,
      );
      
      expect(state.currentDuration.inMinutes, 5); // Should lock at 5 minutes, despite 10 minutes passing since start
    });
    
    test('Resumed state deducts accumulated paused duration', () {
      final startedAt = DateTime.now().subtract(const Duration(minutes: 15));
      
      // Started 15 mins ago, but was paused for 7 of those minutes
      final state = StudyTimerState(
        status: StudyTimerStatus.running,
        subjectId: 'sub1',
        startedAt: startedAt,
        accumulatedPausedDuration: const Duration(minutes: 7),
      );
      
      expect(state.currentDuration.inMinutes, 8); // 15 - 7 = 8
    });
  });
}
