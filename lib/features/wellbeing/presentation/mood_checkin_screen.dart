import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/wellbeing/presentation/providers.dart';
import 'package:uuid/uuid.dart';

class MoodCheckInScreen extends ConsumerStatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  int _mood = 3;
  int _energy = 3;
  int _stress = 3;

  void _save() async {
    final userId = ref.read(authNotifierProvider).user!.id;
    final repo = ref.read(moodRepositoryProvider);
    
    final log = MoodLog(
      id: const Uuid().v4(),
      userId: userId,
      date: DateTime.now(),
      moodRating: _mood,
      energyRating: _energy,
      stressRating: _stress,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingInsert,
    );
    
    await repo.saveCheckIn(log);
    if (mounted) context.pop();
  }

  Widget _buildRatingSelector(String title, int value, ValueChanged<int> onChanged, {List<String>? labels}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final val = index + 1;
            final isSelected = value == val;
            return GestureDetector(
              onTap: () => onChanged(val),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(labels?[index] ?? '$val', style: TextStyle(fontSize: labels != null ? 24 : 16)),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How are you feeling?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            _buildRatingSelector('Mood', _mood, (v) => setState(() => _mood = v), labels: ['😢', '😔', '😐', '🙂', '😊']),
            const SizedBox(height: 32),
            _buildRatingSelector('Energy', _energy, (v) => setState(() => _energy = v)),
            const SizedBox(height: 32),
            _buildRatingSelector('Stress', _stress, (v) => setState(() => _stress = v)),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Save Check-In'),
            )
          ],
        ),
      ),
    );
  }
}
