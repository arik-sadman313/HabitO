import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:uuid/uuid.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  JournalType _journalType = JournalType.personal;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_bodyController.text.trim().isEmpty) return;

    final userId = ref.read(authNotifierProvider).user!.id;
    final repo = ref.read(journalRepositoryProvider);
    
    final entry = JournalEntry(
      id: const Uuid().v4(),
      userId: userId,
      journalType: _journalType,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      tags: _tagsController.text.trim(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingInsert,
    );

    await repo.saveEntry(entry);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SegmentedButton<JournalType>(
              segments: const [
                ButtonSegment(value: JournalType.personal, label: Text('My Journal')),
                ButtonSegment(value: JournalType.shared, label: Text('Our Journal')),
              ],
              selected: {_journalType},
              onSelectionChanged: (set) => setState(() => _journalType = set.first),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                hintText: 'Start writing...',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: '#tags (comma separated)',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
