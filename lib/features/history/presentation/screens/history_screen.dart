import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/dashboard/presentation/screens/dashboard_screen.dart';

final _historyDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_historyDateProvider);
    final dateKey = DateFormat('yyyy-MM-dd').format(selected);
    final mealsAsync = ref.watch(mealsForDateProvider(dateKey));
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(
              height: 76,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: 14,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = DateTime(now.year, now.month, now.day)
                      .subtract(Duration(days: i));
                  final isSelected = day.year == selected.year &&
                      day.month == selected.month &&
                      day.day == selected.day;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(_historyDateProvider.notifier).state = day,
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(day),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: mealsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
                error: (err, _) => Center(
                  child: Text(
                    err.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (meals) {
                  if (meals.isEmpty) {
                    return const Center(
                      child: Text(
                        'No meals logged this day',
                        style: TextStyle(color: AppTheme.lightTextSecondary),
                      ),
                    );
                  }
                  var total = 0;
                  for (final m in meals) {
                    if (m is Map) {
                      total += ((m['total_calories'] ?? 0) as num).toInt();
                    }
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total consumed',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(total)} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...meals.map((m) => _HistoryMealTile(meal: m as Map)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMealTile extends StatelessWidget {
  final Map meal;

  const _HistoryMealTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    String name = 'Meal';
    final items = meal['items'];
    if (items is List && items.isNotEmpty && items.first is Map) {
      name = (items.first['food_name'] ?? 'Meal').toString();
    } else if (meal['notes'] != null) {
      name = meal['notes'].toString();
    }
    final type = (meal['meal_type'] ?? '').toString();
    final kcal = ((meal['total_calories'] ?? 0) as num).toInt();
    final imageUrl = (meal['image_url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 46,
              height: 46,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const _Placeholder(),
                    )
                  : const _Placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  type.isNotEmpty
                      ? type[0].toUpperCase() + type.substring(1)
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$kcal kcal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.lightInputFill,
      child: Center(
        child: Icon(Icons.restaurant_rounded, size: 20, color: AppTheme.primaryBlue),
      ),
    );
  }
}
