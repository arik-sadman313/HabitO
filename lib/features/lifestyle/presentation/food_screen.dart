import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:uuid/uuid.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todayMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Food')),
      body: mealsAsync.when(
        data: (meals) {
          if (meals.isEmpty) {
            return const EmptyStateCard(message: 'No meals logged today.', actionLabel: '+ Add Meal',);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.mealType, style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      if (meal.items.isEmpty)
                        Text(meal.notes ?? 'No items')
                      else
                        ...meal.items.map((item) => Text('• ${item.quantity} ${item.unit} ${item.name}')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, WidgetRef ref) {
    // Quick Add Mockup for MVP
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick Add Meal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _saveMockMeal(ref, 'Breakfast', ['Eggs', 'Bread', 'Tea']);
                Navigator.pop(context);
              },
              child: const Text('Breakfast'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _saveMockMeal(ref, 'Lunch', ['Rice', 'Chicken', 'Vegetables']);
                Navigator.pop(context);
              },
              child: const Text('Lunch'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMockMeal(WidgetRef ref, String type, List<String> items) {
    final repo = ref.read(mealRepositoryProvider);
    final userId = ref.read(authNotifierProvider).user!.id;
    final mealId = const Uuid().v4();
    
    final meal = Meal(
      id: mealId,
      userId: userId,
      mealType: type,
      recordedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    repo.saveMeal(meal);
    
    for (final item in items) {
      repo.saveMealItem(MealItem(
        id: const Uuid().v4(),
        mealId: mealId,
        name: item,
        quantity: 1,
        unit: 'serving',
      ));
    }
  }
}
