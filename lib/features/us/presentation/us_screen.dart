import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/features/us/presentation/providers.dart';
import 'package:habito/features/us/presentation/us_notifier.dart';
import 'package:habito/core/database/enums.dart';

class UsScreen extends ConsumerWidget {
  const UsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(currentCoupleProvider);
    final partnerAsync = ref.watch(partnerProvider);
    final usState = ref.watch(usNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('❤️ Our Space'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: coupleAsync.when(
          data: (couple) {
            if (usState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // State A - No Couple
            if (couple == null || couple.status == CoupleStatus.separated) {
              return _buildNoCoupleState(context, ref, usState);
            }

            return partnerAsync.when(
              data: (partner) {
                // State B - Couple exists, no partner connected yet
                if (partner == null) {
                  return _buildWaitingForPartnerState(context, ref, usState);
                }
                
                // State C - Couple has two members
                return _buildConnectedState(context, ref, partner);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildNoCoupleState(BuildContext context, WidgetRef ref, UsState usState) {
    final codeController = TextEditingController();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (usState.error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Text(usState.error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Sync with a Partner', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Create a couple space or join an existing one.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.read(usNotifierProvider.notifier).createCouple(),
                  child: const Text('Create a Couple Space'),
                ),
                const SizedBox(height: 32),
                const Text('OR JOIN WITH A CODE'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter 6-digit code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (codeController.text.isNotEmpty) {
                          ref.read(usNotifierProvider.notifier).joinCouple(codeController.text);
                        }
                      },
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingForPartnerState(BuildContext context, WidgetRef ref, UsState usState) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (usState.error != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Text(usState.error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.hourglass_empty, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text('Waiting for Partner', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (usState.inviteCode == null)
                  ElevatedButton(
                    onPressed: () => ref.read(usNotifierProvider.notifier).generateInvite(),
                    child: const Text('Generate Invite Code'),
                  )
                else
                  Column(
                    children: [
                      Text('Your Invite Code:', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          usState.inviteCode!,
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: usState.inviteCode!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => ref.read(usNotifierProvider.notifier).leaveCouple(),
                  child: const Text('Cancel & Leave Couple', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedState(BuildContext context, WidgetRef ref, dynamic partner) {
    final sharedGoalsAsync = ref.watch(sharedGoalsProvider);
    final memoriesAsync = ref.watch(memoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Partner Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text('Partner Connected'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _confirmLeaveCouple(context, ref),
                  child: const Text('Leave Couple', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        const SectionHeader(title: 'SHARED GOALS'),
        sharedGoalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyStateCard(
                message: 'No shared goals yet.',
                actionLabel: '+ Create Goal',
                onAction: () {},
              );
            }
            return Column(
              children: goals.map((goal) {
                final progress = goal.target > 0 ? (goal.currentProgress / goal.target) : 0.0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🎯 ${goal.title}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${goal.currentProgress.toInt()} / ${goal.target.toInt()} ${goal.unit ?? ""}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 4),
                        Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
        
        const SizedBox(height: 32),
        const SectionHeader(title: 'MEMORIES'),
        memoriesAsync.when(
          data: (memories) {
            if (memories.isEmpty) {
              return EmptyStateCard(
                message: 'No memories yet.',
                actionLabel: '+ Add Memory',
                onAction: () {},
              );
            }
            return Column(
              children: memories.map((memory) => Card(
                child: ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(memory.title),
                  subtitle: Text(memory.date.toString().split(' ')[0]),
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _confirmLeaveCouple(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Couple?'),
        content: const Text('You will lose access to all shared data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(usNotifierProvider.notifier).leaveCouple();
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }
}
