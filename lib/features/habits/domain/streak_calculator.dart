import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';

class HabitAnalytics {
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  
  const HabitAnalytics({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
  });
}

class StreakCalculator {
  static HabitAnalytics calculate(Habit habit, List<HabitLog> logs) {
    if (logs.isEmpty) {
      return const HabitAnalytics(currentStreak: 0, longestStreak: 0, completionRate: 0.0);
    }

    // Sort logs descending by date
    final sortedLogs = List<HabitLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate Completion Rate
    final completedCount = sortedLogs.where((l) => l.isCompleted).length;
    final completionRate = completedCount / sortedLogs.length;

    // We only fully support daily frequency for strict streaks in this MVP phase
    if (habit.frequency != HabitFrequency.daily) {
      // Simplified streak for non-daily (just count consecutive completed logs)
      return _calculateSimpleConsecutive(sortedLogs, completionRate);
    }

    return _calculateDailyStreak(sortedLogs, completionRate);
  }

  static HabitAnalytics _calculateSimpleConsecutive(List<HabitLog> sortedLogs, double completionRate) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (var i = 0; i < sortedLogs.length; i++) {
      final log = sortedLogs[i];
      if (log.isCompleted) {
        tempStreak++;
        if (i == tempStreak - 1) { // Still on current streak
          currentStreak = tempStreak;
        }
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 0;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    return HabitAnalytics(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate,
    );
  }

  static HabitAnalytics _calculateDailyStreak(List<HabitLog> sortedLogs, double completionRate) {
    int currentStreak = 0;
    int longestStreak = 0;
    
    // We only care about unique dates for daily habits
    final completedDates = sortedLogs
        .where((l) => l.isCompleted)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();

    if (completedDates.isEmpty) {
      return HabitAnalytics(currentStreak: 0, longestStreak: 0, completionRate: completionRate);
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // Calculate current streak
    DateTime checkDate = todayStart;
    
    // If today is not completed, we allow the streak to be active if yesterday was completed
    if (!completedDates.contains(todayStart)) {
      if (completedDates.contains(yesterdayStart)) {
        checkDate = yesterdayStart;
      } else {
        // Today is not completed and neither was yesterday -> current streak broken
        currentStreak = 0;
      }
    }

    // Trace backward for current streak
    if (currentStreak != 0 || checkDate == todayStart || checkDate == yesterdayStart) {
      while (completedDates.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Calculate longest streak by grouping all consecutive dates in history
    final sortedCompletedDates = completedDates.toList()..sort((a, b) => a.compareTo(b));
    int tempStreak = 1;
    longestStreak = 1;

    for (int i = 1; i < sortedCompletedDates.length; i++) {
      final current = sortedCompletedDates[i];
      final previous = sortedCompletedDates[i - 1];
      
      // If exactly 1 day apart
      if (current.difference(previous).inDays == 1) {
        tempStreak++;
      } else {
        if (tempStreak > longestStreak) longestStreak = tempStreak;
        tempStreak = 1;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;
    
    // Safety check, longest streak can't be less than current streak
    if (currentStreak > longestStreak) longestStreak = currentStreak;

    return HabitAnalytics(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate,
    );
  }
}
