import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/activities/presentation/providers.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:uuid/uuid.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  final Activity? existingActivity;

  const ActivityFormScreen({super.key, this.existingActivity});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;

  @override
  void initState() {
    super.initState();
    final activity = widget.existingActivity;
    _titleController = TextEditingController(text: activity?.title ?? '');
    _notesController = TextEditingController(text: activity?.notes ?? '');
    
    // Default to the currently selected date in the Today view, or now if editing
    final baseDate = activity != null 
        ? activity.scheduledStart 
        : ref.read(selectedDateProvider);
    
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    
    _startTime = activity != null 
        ? TimeOfDay.fromDateTime(activity.scheduledStart)
        : TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = ref.read(authNotifierProvider).user!.id;
    final repo = ref.read(activityRepositoryProvider);

    final scheduledStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final activity = Activity(
      id: widget.existingActivity?.id ?? const Uuid().v4(),
      userId: userId,
      title: _titleController.text,
      notes: _notesController.text,
      scheduledStart: scheduledStart,
      scheduledEnd: null,
      isCompleted: widget.existingActivity?.isCompleted ?? false,
      isShared: true,
      createdAt: widget.existingActivity?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );

    await repo.saveActivity(activity);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (widget.existingActivity == null) return;
    final repo = ref.read(activityRepositoryProvider);
    await repo.deleteActivity(widget.existingActivity!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingActivity == null ? 'New Activity' : 'Edit Activity'),
        actions: [
          if (widget.existingActivity != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Activity?'),
                    content: const Text('Are you sure you want to delete this activity?'),
                    actions: [
                      TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          context.pop();
                          _delete();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() => _startTime = time);
                  }
                },
              ),
              const Divider(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Save Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
