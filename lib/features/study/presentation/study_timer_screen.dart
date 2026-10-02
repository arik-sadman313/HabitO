import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/features/study/presentation/timer_notifier.dart';
import 'package:habito/features/study/presentation/providers.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:uuid/uuid.dart';

class StudyTimerScreen extends ConsumerWidget {
  const StudyTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(studyTimerProvider);
    final duration = timerState.currentDuration;
    final isRunning = timerState.status == StudyTimerStatus.running;
    final isPaused = timerState.status == StudyTimerStatus.paused;
    final isIdle = timerState.status == StudyTimerStatus.idle;

    final subjectsAsync = ref.watch(studySubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (!isIdle) {
              _showCancelDialog(context, ref);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isIdle)
              subjectsAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const Text('Please create a subject first.');
                  }
                  // Just use the first subject for MVP
                  final sub = subjects.first;
                  return Text('Ready to study ${sub.name}?', style: Theme.of(context).textTheme.titleLarge);
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error $e'),
              ),
              
            const SizedBox(height: 48),
            
            Text(
              _formatTimer(duration),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            
            const SizedBox(height: 64),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isIdle)
                  FloatingActionButton.extended(
                    onPressed: () {
                      final subjects = ref.read(studySubjectsProvider).value;
                      if (subjects != null && subjects.isNotEmpty) {
                        ref.read(studyTimerProvider.notifier).start(subjects.first.id);
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                
                if (isRunning)
                  FloatingActionButton.extended(
                    onPressed: () => ref.read(studyTimerProvider.notifier).pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                
                if (isPaused)
                  FloatingActionButton.extended(
                    onPressed: () => ref.read(studyTimerProvider.notifier).resume(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  
                if (isRunning || isPaused) ...[
                  const SizedBox(width: 24),
                  FloatingActionButton.extended(
                    onPressed: () => _finishSession(context, ref),
                    icon: const Icon(Icons.stop),
                    label: const Text('Finish'),
                    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _finishSession(BuildContext context, WidgetRef ref) {
    final state = ref.read(studyTimerProvider);
    final duration = state.currentDuration;
    
    if (state.subjectId != null && duration.inSeconds > 0) {
      final repo = ref.read(studyRepositoryProvider);
      final userId = ref.read(authNotifierProvider).user!.id;
      
      repo.saveSession(StudySession(
        id: const Uuid().v4(),
        userId: userId,
        subjectId: state.subjectId!,
        startedAt: state.startedAt!,
        endedAt: DateTime.now(),
        duration: duration.inSeconds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
      ));
    }
    
    ref.read(studyTimerProvider.notifier).complete();
    ref.read(studyTimerProvider.notifier).reset();
    context.pop();
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('All progress for this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Studying'),
          ),
          TextButton(
            onPressed: () {
              ref.read(studyTimerProvider.notifier).reset();
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
