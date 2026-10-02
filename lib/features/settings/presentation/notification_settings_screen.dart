import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/reminders/presentation/providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Notification Permission'),
            subtitle: permissionAsync.when(
              data: (granted) => Text(granted ? 'Granted' : 'Denied / Not Requested'),
              loading: () => const Text('Checking...'),
              error: (err, stack) => Text('Error: $err'),
            ),
            trailing: permissionAsync.maybeWhen(
              data: (granted) => granted,
              orElse: () => false,
            ) ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.orange),
          ),
          const Divider(),
          const ListTile(
            title: Text('Active Reminders'),
          ),
          remindersAsync.when(
            data: (reminders) {
              final active = reminders.where((r) => r.enabled).length;
              return ListTile(
                title: Text('$active reminders currently active.'),
              );
            },
            loading: () => const ListTile(title: Text('Loading...')),
            error: (err, stack) => ListTile(title: Text('Error: $err')),
          ),
        ],
      ),
    );
  }
}
