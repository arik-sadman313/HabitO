import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/screen_time/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';

class ScreenTimeDashboard extends ConsumerStatefulWidget {
  const ScreenTimeDashboard({super.key});

  @override
  ConsumerState<ScreenTimeDashboard> createState() => _ScreenTimeDashboardState();
}

class _ScreenTimeDashboardState extends ConsumerState<ScreenTimeDashboard> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(screenTimeAccessStateProvider);
      ref.read(todayScreenTimeProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessStateAsync = ref.watch(screenTimeAccessStateProvider);
    final summaryAsync = ref.watch(todayScreenTimeProvider);
    final weeklyAsync = ref.watch(weeklyScreenTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(screenTimeAccessStateProvider);
          await ref.read(todayScreenTimeProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            accessStateAsync.when(
              data: (state) {
                if (state != ScreenTimeAccessState.granted) {
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Usage Access Required', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          )),
                          const SizedBox(height: 8),
                          Text(
                            'To track your screen time and most used apps, HabitO requires Android Usage Access permission.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(screenTimeRepositoryProvider).requestAccess();
                            },
                            child: const Text('Grant Usage Access'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => const Text('Error checking access'),
            ),
            
            const SizedBox(height: 16),
            const SectionHeader(title: 'TODAY'),
            summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return const EmptyStateCard(message: 'No usage data available for today.');
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          '${summary.totalDuration.inHours}h ${summary.totalDuration.inMinutes.remainder(60)}m',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total screen time',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (e, st) => Text('Error: $e'),
            ),

            const SizedBox(height: 32),
            const SectionHeader(title: 'WEEKLY TREND'),
            weeklyAsync.when(
              data: (days) {
                if (days.isEmpty) {
                  return const EmptyStateCard(message: 'Not enough data to show a trend yet.');
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: days.map((day) {
                        final maxDuration = days.map((d) => d.totalDuration.inSeconds).reduce((a, b) => a > b ? a : b);
                        final fraction = maxDuration > 0 ? day.totalDuration.inSeconds / maxDuration : 0.0;
                        final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.date.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(weekday),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${day.totalDuration.inHours}h ${day.totalDuration.inMinutes.remainder(60)}m',
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'TOP APPS'),
            summaryAsync.when(
              data: (summary) {
                if (summary == null || summary.topApps.isEmpty) {
                  return const EmptyStateCard(message: 'No app usage recorded.');
                }
                return Column(
                  children: summary.topApps.map((app) {
                    final fraction = summary.totalDuration.inSeconds > 0 
                        ? app.duration.inSeconds / summary.totalDuration.inSeconds 
                        : 0.0;
                    return AppUsageTile(usage: app, percentage: fraction);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class AppUsageTile extends StatelessWidget {
  final AppUsage usage;
  final double percentage;

  const AppUsageTile({super.key, required this.usage, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(usage.appName.isNotEmpty ? usage.appName[0].toUpperCase() : '?'),
        ),
        title: Text(usage.appName),
        subtitle: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(percentage * 100).toInt()}%'),
          ],
        ),
        trailing: Text(
          '${usage.duration.inHours > 0 ? "${usage.duration.inHours}h " : ""}${usage.duration.inMinutes.remainder(60)}m',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
