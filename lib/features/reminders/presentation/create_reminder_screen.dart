import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/reminders/presentation/providers.dart';
import 'package:uuid/uuid.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final ReminderType? initialType;
  final String? initialReferenceId;

  const CreateReminderScreen({
    super.key,
    this.initialType,
    this.initialReferenceId,
  });

  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  ReminderType _type = ReminderType.general;
  RecurrenceType _recurrence = RecurrenceType.once;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);

    final reminder = ReminderSchedule(
      id: const Uuid().v4(),
      userId: user.id,
      type: _type,
      title: _titleController.text,
      body: _bodyController.text,
      referenceId: widget.initialReferenceId,
      scheduledTime: scheduled,
      recurrenceType: _recurrence,
      enabled: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingUpdate,
    );

    await ref.read(reminderRepositoryProvider).saveReminder(reminder);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ReminderType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ReminderType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.value));
              }).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Time'),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Recurrence'),
              items: RecurrenceType.values.map((t) {
                return DropdownMenuItem(value: t, child: Text(t.value));
              }).toList(),
              onChanged: (v) => setState(() => _recurrence = v!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
