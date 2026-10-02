import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/reminders/presentation/providers.dart';
import 'package:intl/intl.dart';

class RemindersDashboardScreen extends ConsumerWidget {
  const RemindersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings/notifications'),
          ),
        ],
      ),
      body: remindersAsync.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('No reminders configured.'));
          }

          final active = reminders.where((r) => r.enabled).toList();
          final disabled = reminders.where((r) => !r.enabled).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                Text('Active', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...active.map((r) => _ReminderCard(reminder: r)),
                const SizedBox(height: 16),
              ],
              if (disabled.isNotEmpty) ...[
                Text('Disabled', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...disabled.map((r) => _ReminderCard(reminder: r)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reminders/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final ReminderSchedule reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(reminderRepositoryProvider);
    final timeStr = DateFormat.Hm().format(reminder.scheduledTime);
    final recur = reminder.recurrenceType.value;

    return Card(
      child: ListTile(
        title: Text(reminder.title),
        subtitle: Text('$timeStr • $recur • ${reminder.type.value}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.enabled,
              onChanged: (val) {
                repo.saveReminder(ReminderSchedule(
                  id: reminder.id,
                  userId: reminder.userId,
                  type: reminder.type,
                  title: reminder.title,
                  body: reminder.body,
                  scheduledTime: reminder.scheduledTime,
                  recurrenceType: reminder.recurrenceType,
                  daysOfWeek: reminder.daysOfWeek,
                  enabled: val,
                  createdAt: reminder.createdAt,
                  updatedAt: DateTime.now(),
                  syncStatus: SyncStatus.pendingUpdate,
                  referenceId: reminder.referenceId,
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => repo.deleteReminder(reminder.id),
            ),
          ],
        ),
      ),
    );
  }
}
