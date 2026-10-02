import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/goals/presentation/providers.dart';
import 'package:habito/core/database/enums.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();

  GoalType _selectedType = GoalType.studyDuration;
  final DateTime _startDate = DateTime.now();
  DateTime? _targetDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId == null) return;

    final goal = PersonalGoal(
      id: const Uuid().v4(),
      userId: userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      goalType: _selectedType,
      targetValue: double.parse(_targetController.text),
      currentValue: 0.0,
      unit: _unitController.text.trim(),
      startDate: _startDate,
      targetDate: _targetDate,
      status: GoalStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingInsert,
    );

    await ref.read(personalGoalRepositoryProvider).createGoal(goal);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Goal'),
        actions: [
          TextButton(
            onPressed: _saveGoal,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g., Study 50 hours this month'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<GoalType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Goal Type'),
              items: GoalType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'HabitO will use real data to automatically calculate progress for this goal.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetController,
                    decoration: const InputDecoration(labelText: 'Target Value', hintText: 'e.g., 50'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Valid number required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit', hintText: 'e.g., hours'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Target Date (Optional)'),
              subtitle: Text(_targetDate != null ? _targetDate!.toIso8601String().split('T')[0] : 'No deadline'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (d != null) setState(() => _targetDate = d);
              },
            ),
          ],
        ),
      ),
    );
  }
}
