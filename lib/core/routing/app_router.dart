import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/routing/main_scaffold.dart';
import 'package:habito/features/auth/domain/auth_state.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/auth/presentation/screens/login_screen.dart';
import 'package:habito/features/auth/presentation/screens/register_screen.dart';
import 'package:habito/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:habito/features/home/presentation/home_screen.dart';
import 'package:habito/features/activities/presentation/today_screen.dart';
import 'package:habito/features/us/presentation/us_screen.dart';
import 'package:habito/features/trackers/presentation/track_screen.dart';
import 'package:habito/features/activities/presentation/activity_form_screen.dart';
import 'package:habito/features/study/presentation/study_screen.dart';
import 'package:habito/features/study/presentation/study_timer_screen.dart';
import 'package:habito/features/lifestyle/presentation/food_screen.dart';
import 'package:habito/features/lifestyle/presentation/water_screen.dart';
import 'package:habito/features/lifestyle/presentation/sleep_screen.dart';
import 'package:habito/features/lifestyle/presentation/exercise_screen.dart';
import 'package:habito/features/journal/presentation/journal_screen.dart';
import 'package:habito/features/journal/presentation/journal_editor_screen.dart';
import 'package:habito/features/journal/presentation/journal_detail_screen.dart';
import 'package:habito/features/wellbeing/presentation/wellbeing_screen.dart';
import 'package:habito/features/wellbeing/presentation/mood_checkin_screen.dart';
import 'package:habito/features/screen_time/presentation/screen_time_dashboard.dart';
import 'package:habito/features/goals/presentation/goals_dashboard_screen.dart';
import 'package:habito/features/goals/presentation/goal_detail_screen.dart';
import 'package:habito/features/goals/presentation/create_goal_screen.dart';
import 'package:habito/features/analytics/presentation/analytics_dashboard_screen.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/reminders/presentation/reminders_dashboard_screen.dart';
import 'package:habito/features/reminders/presentation/create_reminder_screen.dart';
import 'package:habito/features/settings/presentation/notification_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorTodayKey = GlobalKey<NavigatorState>(debugLabel: 'shellToday');
final _shellNavigatorTrackKey = GlobalKey<NavigatorState>(debugLabel: 'shellTrack');
final _shellNavigatorUsKey = GlobalKey<NavigatorState>(debugLabel: 'shellUs');
final _shellNavigatorJournalKey = GlobalKey<NavigatorState>(debugLabel: 'shellJournal');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isSplash = authState.status == AuthStatus.authenticating && authState.user == null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isSplash) return null; // Splash handled implicitly
      if (!isAuth) return isLoggingIn ? null : '/login';
      if (isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(navigatorKey: _shellNavigatorHomeKey, routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(navigatorKey: _shellNavigatorTodayKey, routes: [
            GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
          ]),
          StatefulShellBranch(navigatorKey: _shellNavigatorTrackKey, routes: [
            GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
          ]),
          StatefulShellBranch(navigatorKey: _shellNavigatorUsKey, routes: [
            GoRoute(path: '/us', builder: (context, state) => const UsScreen()),
          ]),
          StatefulShellBranch(navigatorKey: _shellNavigatorJournalKey, routes: [
            GoRoute(path: '/journal', builder: (context, state) => const JournalScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/study',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StudyScreen(),
      ),
      GoRoute(
        path: '/lifestyle/food',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FoodScreen(),
      ),
      GoRoute(
        path: '/lifestyle/water',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WaterScreen(),
      ),
      GoRoute(
        path: '/reminders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RemindersDashboardScreen(),
      ),
      GoRoute(
        path: '/reminders/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateReminderScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/lifestyle/sleep',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SleepScreen(),
      ),
      GoRoute(
        path: '/lifestyle/exercise',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: '/activity/new',
        builder: (context, state) => const ActivityFormScreen(),
      ),
      GoRoute(
        path: '/activity/edit',
        builder: (context, state) {
          final activity = state.extra as Activity;
          return ActivityFormScreen(existingActivity: activity);
        },
      ),
      GoRoute(
        path: '/study/timer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StudyTimerScreen(),
      ),
      GoRoute(
        path: '/journal/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const JournalEditorScreen(),
      ),
      GoRoute(
        path: '/journal/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => JournalDetailScreen(entryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/wellbeing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WellbeingScreen(),
      ),
      GoRoute(
        path: '/wellbeing/check-in',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MoodCheckInScreen(),
      ),
      GoRoute(
        path: '/screen-time',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScreenTimeDashboard(),
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/goals',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GoalsDashboardScreen(),
      ),
      GoRoute(
        path: '/goals/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateGoalScreen(),
      ),
      GoRoute(
        path: '/goals/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
    ],
  );
});
