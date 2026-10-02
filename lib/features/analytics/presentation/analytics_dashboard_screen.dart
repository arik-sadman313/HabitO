import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/analytics/presentation/providers.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<AnalyticsPeriod>(
            segments: const [
              ButtonSegment(value: AnalyticsPeriod.last7Days, label: Text('7 Days')),
              ButtonSegment(value: AnalyticsPeriod.last30Days, label: Text('30 Days')),
              ButtonSegment(value: AnalyticsPeriod.last90Days, label: Text('90 Days')),
            ],
            selected: {period},
            onSelectionChanged: (set) {
              ref.read(analyticsPeriodProvider.notifier).setPeriod(set.first);
            },
          ),
          const SizedBox(height: 24),
          const _StudyAnalyticsSection(),
          const SizedBox(height: 24),
          const _LifestyleAnalyticsSection(),
          const SizedBox(height: 24),
          const _WellbeingAnalyticsSection(),
          const SizedBox(height: 24),
          const _ScreenTimeAnalyticsSection(),
        ],
      ),
    );
  }
}

class _StudyAnalyticsSection extends ConsumerWidget {
  const _StudyAnalyticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyAsync = ref.watch(studyAnalyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Study', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            studyAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) return const Text('No study data recorded.');
                final totalSeconds = sessions.fold<int>(0, (s, e) => s + e.duration);
                final hours = totalSeconds / 3600.0;
                return Text('Total study time: ${hours.toStringAsFixed(1)} h\nSessions completed: ${sessions.length}');
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading study analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifestyleAnalyticsSection extends ConsumerWidget {
  const _LifestyleAnalyticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifeAsync = ref.watch(lifestyleAnalyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lifestyle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            lifeAsync.when(
              data: (data) {
                final exercises = data['exercises'] as List;
                final sleep = data['sleep'] as List;
                
                final totalExercise = exercises.fold<int>(0, (s, e) => s + (e.duration as int));
                final totalSleep = sleep.fold<int>(0, (s, e) => s + (e.duration as int));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exercises.isEmpty) const Text('Exercise: Not enough data')
                    else Text('Exercise: ${exercises.length} sessions (${totalExercise / 60} h)'),
                    const SizedBox(height: 8),
                    if (sleep.isEmpty) const Text('Sleep: Not enough data')
                    else Text('Avg Sleep: ${(totalSleep / sleep.length / 60.0).toStringAsFixed(1)} h/night'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading lifestyle analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WellbeingAnalyticsSection extends ConsumerWidget {
  const _WellbeingAnalyticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wbAsync = ref.watch(wellbeingAnalyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wellbeing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            wbAsync.when(
              data: (logs) {
                if (logs.isEmpty) return const Text('No wellbeing data recorded.');
                final avgMood = logs.fold<int>(0, (s, e) => s + e.moodRating) / logs.length;
                final avgEnergy = logs.fold<int>(0, (s, e) => s + e.energyRating) / logs.length;
                final avgStress = logs.fold<int>(0, (s, e) => s + e.stressRating) / logs.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mood average: ${avgMood.toStringAsFixed(1)} / 5'),
                    Text('Energy average: ${avgEnergy.toStringAsFixed(1)} / 5'),
                    Text('Stress average: ${avgStress.toStringAsFixed(1)} / 5'),
                    Text('Check-in days: ${logs.length}'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading wellbeing analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenTimeAnalyticsSection extends ConsumerWidget {
  const _ScreenTimeAnalyticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stAsync = ref.watch(screenTimeAnalyticsProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screen Time', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            stAsync.when(
              data: (logs) {
                if (logs.isEmpty) return const Text('Not enough data');
                final totalSec = logs.fold<int>(0, (s, e) => s + e.totalDuration.inSeconds);
                final avgSec = totalSec / logs.length;
                final avgHours = avgSec / 3600.0;
                return Text('Average daily screen time: ${avgHours.toStringAsFixed(1)} h');
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading screen time analytics'),
            ),
          ],
        ),
      ),
    );
  }
}
