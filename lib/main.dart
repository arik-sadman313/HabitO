import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/routing/app_router.dart';
import 'package:habito/core/theme/app_theme.dart';
import 'package:habito/core/utils/logger.dart';

import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/notifications/notification_scheduler.dart';
import 'package:habito/features/reminders/presentation/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  appLogger.i('App started');

  runApp(
    const ProviderScope(
      child: HabitOApp(),
    ),
  );
}

class HabitOApp extends ConsumerWidget {
  const HabitOApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<List<ReminderSchedule>>(enabledRemindersProvider, (previous, next) {
      ref.read(notificationSchedulerProvider).reconcile(next);
    });

    ref.listen<AsyncValue<String?>>(notificationPayloadProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        final payload = next.value!;
        final parts = payload.split(':');
        final type = parts[0];
        final refId = parts.length > 1 ? parts[1] : null;
        
        final router = ref.read(appRouterProvider);
        switch (type) {
          case 'habit':
            if (refId != null && refId.isNotEmpty) {
              router.go('/habits/$refId');
            }
            break;
          case 'study':
            router.go('/study');
            break;
          case 'goal':
            if (refId != null && refId.isNotEmpty) {
              router.go('/goals/$refId');
            } else {
              router.go('/goals');
            }
            break;
          case 'water':
            router.go('/track');
            break;
          case 'exercise':
            router.go('/track');
            break;
          case 'sleep':
            router.go('/track');
            break;
          case 'journal':
            router.go('/journal');
            break;
          case 'activity':
            router.go('/today');
            break;
        }
      }
    });

    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HabitO',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
