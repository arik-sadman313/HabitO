import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/lifestyle/presentation/water_provider.dart';
import 'package:habito/features/trackers/presentation/providers.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:uuid/uuid.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(todayWaterTotalProvider);
    final target = ref.watch(dailyWaterGoalProvider);
    final percentage = (total / target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Water')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Text(
              '${total.toInt()} ml / ${target.toInt()} ml',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage,
              minHeight: 24,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 8),
            Text('${(percentage * 100).toInt()}%', style: Theme.of(context).textTheme.titleLarge),
            
            const Spacer(),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _QuickAddButton(amount: 250),
                _QuickAddButton(amount: 500),
                _QuickAddButton(amount: 750),
                _QuickAddButton(amount: 1000),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends ConsumerWidget {
  final double amount;
  const _QuickAddButton({required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text('+${amount.toInt()} ml', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      padding: const EdgeInsets.all(16),
      onPressed: () async {
        final tracker = await ref.read(waterTrackerProvider.future);
        final repo = ref.read(trackerRepositoryProvider);
        
        final log = TrackerLog(
          id: const Uuid().v4(),
          trackerId: tracker.id,
          userId: tracker.userId!,
          timestamp: DateTime.now(),
          valueNum: amount,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pendingUpdate,
        );
        
        await repo.saveTrackerLog(log);
      },
    );
  }
}
