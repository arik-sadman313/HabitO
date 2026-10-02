import 'package:flutter_test/flutter_test.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/habits/domain/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    final habit = Habit(
      id: 'h1',
      userId: 'u1',
      trackerId: 't1',
      title: 'Read 20 pages',
      frequency: HabitFrequency.daily,
      targetValue: 1,
      startDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );

    test('Empty logs returns 0 streak', () {
      final result = StreakCalculator.calculate(habit, []);
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.completionRate, 0.0);
    });

    test('Consecutive days calculates correctly', () {
      final today = DateTime.now();
      final logs = [
        HabitLog(id: '1', habitId: 'h1', userId: 'u1', date: today, isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        HabitLog(id: '2', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 1)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        HabitLog(id: '3', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 2)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
      ];

      final result = StreakCalculator.calculate(habit, logs);
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.completionRate, 1.0);
    });

    test('Missed day breaks current streak but preserves longest', () {
      final today = DateTime.now();
      final logs = [
        // Missed yesterday!
        HabitLog(id: '1', habitId: 'h1', userId: 'u1', date: today, isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        // Previous 3 days were completed
        HabitLog(id: '3', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 2)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        HabitLog(id: '4', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 3)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        HabitLog(id: '5', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 4)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
      ];

      final result = StreakCalculator.calculate(habit, logs);
      expect(result.currentStreak, 1);
      expect(result.longestStreak, 3);
    });

    test('Streak still active if completed yesterday but not yet today', () {
      final today = DateTime.now();
      final logs = [
        // Completed yesterday, not today
        HabitLog(id: '1', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 1)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
        HabitLog(id: '2', habitId: 'h1', userId: 'u1', date: today.subtract(const Duration(days: 2)), isCompleted: true, progressValue: 1, createdAt: today, updatedAt: today, syncStatus: SyncStatus.synced),
      ];

      final result = StreakCalculator.calculate(habit, logs);
      expect(result.currentStreak, 2);
    });
  });
}
