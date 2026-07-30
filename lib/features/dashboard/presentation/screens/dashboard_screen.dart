import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/ai_scanner/presentation/controllers/ai_scanner_controller.dart';
import 'package:my_diet_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/meals/presentation/widgets/add_food_sheet.dart';
import 'package:my_diet_app/features/profile/presentation/screens/update_goals_screen.dart';

/// Currently selected day on the dashboard (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Meals for a given date, keyed by 'yyyy-MM-dd'.
final mealsForDateProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, dateStr) {
  final date = DateFormat('yyyy-MM-dd').parse(dateStr);
  return ref.watch(mealRepositoryProvider).getMealsForDate(date);
});

String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final selectedDate = ref.watch(selectedDateProvider);
    final mealsAsync = ref.watch(mealsForDateProvider(_dateKey(selectedDate)));

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            ref.invalidate(dashboardControllerProvider);
            ref.invalidate(mealsForDateProvider);
            await ref.read(dashboardControllerProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              _Header(name: user?.name.split(' ').first ?? 'there'),
              const SizedBox(height: 20),
              const _DateSelector(),
              const SizedBox(height: 16),
              dashboardAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                ),
                error: (err, _) => _ErrorBox(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(dashboardControllerProvider),
                ),
                data: (data) => _CaloriesCard(
                  calorieTarget: data.calorieTarget,
                  proteinTarget: data.proteinTarget,
                  carbsTarget: data.carbsTarget,
                  fatTarget: data.fatTarget,
                  meals: mealsAsync.valueOrNull ?? const [],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Food Today',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => showAddFoodSheet(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 18, color: AppTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Add Food',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...mealsAsync.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
                  ),
                ],
                error: (err, _) => [
                  _ErrorBox(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(mealsForDateProvider),
                  ),
                ],
                data: (meals) => [
                  for (final type in const ['breakfast', 'lunch', 'snack', 'dinner'])
                    _MealGroupCard(
                      mealType: type,
                      meals: meals.where((m) {
                        final t = (m is Map ? m['meal_type'] : null)?.toString() ?? '';
                        return t == type;
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $name 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.lightTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's reach your goal today!",
                style: TextStyle(fontSize: 14, color: AppTheme.lightTextSecondary),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.lightTextPrimary,
                size: 22,
              ),
            ),
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateSelector extends ConsumerWidget {
  const _DateSelector();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    final isToday = _isSameDay(selected, now);
    final isYesterday = _isSameDay(selected, now.subtract(const Duration(days: 1)));

    final label = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('EEEE').format(selected);

    void shift(int days) {
      final next = selected.add(Duration(days: days));
      if (next.isAfter(now) && !_isSameDay(next, now)) return;
      ref.read(selectedDateProvider.notifier).state = next;
    }

    return Row(
      children: [
        _ArrowButton(icon: Icons.chevron_left_rounded, onTap: () => shift(-1)),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selected,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now,
                );
                if (picked != null) {
                  ref.read(selectedDateProvider.notifier).state = picked;
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy').format(selected),
                            style: const TextStyle(
                              color: AppTheme.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.lightTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: isToday ? null : () => shift(1),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ArrowButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 52,
          child: Icon(
            icon,
            color: onTap == null
                ? AppTheme.lightBorder
                : AppTheme.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final int calorieTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final List<dynamic> meals;

  const _CaloriesCard({
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    var calories = 0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;

    for (final m in meals) {
      if (m is! Map) continue;
      calories += ((m['total_calories'] ?? m['calories'] ?? 0) as num).toInt();
      final items = m['items'];
      if (items is List && items.isNotEmpty) {
        for (final it in items) {
          if (it is! Map) continue;
          protein += ((it['protein'] ?? 0) as num).toDouble();
          carbs += ((it['carbs'] ?? 0) as num).toDouble();
          fat += ((it['fat'] ?? 0) as num).toDouble();
        }
      } else {
        protein += ((m['total_protein'] ?? 0) as num).toDouble();
      }
    }

    final target = calorieTarget > 0 ? calorieTarget : 1;
    final left = calorieTarget - calories;
    final over = left < 0;
    final ratio = (calories / target).clamp(0.0, 1.0);
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Calories left
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calories Left',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fmt.format(over ? -left : left),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          color: over ? const Color(0xFFFF5C5C) : AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Text(
                      over ? 'kcal over' : 'kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: over ? const Color(0xFFFF5C5C) : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UpdateGoalsScreen()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'of ${fmt.format(calorieTarget)} kcal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Consumed ring
              Expanded(
                flex: 6,
                child: Center(
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 128,
                          height: 128,
                          child: CircularProgressIndicator(
                            value: ratio,
                            strokeWidth: 11,
                            strokeCap: StrokeCap.round,
                            backgroundColor: const Color(0xFFE8EEFB),
                            valueColor: AlwaysStoppedAnimation(
                              over ? const Color(0xFFFF5C5C) : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fmt.format(calories),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.lightTextPrimary,
                              ),
                            ),
                            const Text(
                              'Consumed',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Macro totals
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroDotRow(
                      label: 'Protein',
                      value: '${protein.round()} / ${proteinTarget}g',
                      color: AppTheme.macroProtein,
                    ),
                    const SizedBox(height: 14),
                    _MacroDotRow(
                      label: 'Carbs',
                      value: '${carbs.round()} / ${carbsTarget}g',
                      color: AppTheme.macroCarbs,
                    ),
                    const SizedBox(height: 14),
                    _MacroDotRow(
                      label: 'Fat',
                      value: '${fat.round()} / ${fatTarget}g',
                      color: AppTheme.macroFat,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MacroProgress(
                  label: 'Protein',
                  icon: Icons.egg_alt_outlined,
                  consumed: protein,
                  target: proteinTarget,
                  color: AppTheme.macroProtein,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgress(
                  label: 'Carbs',
                  icon: Icons.rice_bowl_outlined,
                  consumed: carbs,
                  target: carbsTarget,
                  color: AppTheme.macroCarbs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroProgress(
                  label: 'Fat',
                  icon: Icons.water_drop_outlined,
                  consumed: fat,
                  target: fatTarget,
                  color: AppTheme.macroFat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroDotRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroDotRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroProgress extends StatelessWidget {
  final String label;
  final IconData icon;
  final double consumed;
  final int target;
  final Color color;

  const _MacroProgress({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = target > 0 ? target : 1;
    final p = (consumed / t).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              '${(p * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MealGroupCard extends StatefulWidget {
  final String mealType;
  final List<dynamic> meals;

  const _MealGroupCard({required this.mealType, required this.meals});

  @override
  State<_MealGroupCard> createState() => _MealGroupCardState();
}

class _MealGroupCardState extends State<_MealGroupCard> {
  bool _expanded = true;

  String get _title =>
      widget.mealType[0].toUpperCase() + widget.mealType.substring(1);

  IconData get _icon {
    switch (widget.mealType) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.light_mode_outlined;
      case 'snack':
        return Icons.bakery_dining_outlined;
      default:
        return Icons.nightlight_outlined;
    }
  }

  Color get _color {
    switch (widget.mealType) {
      case 'breakfast':
        return AppTheme.accentOrange;
      case 'lunch':
        return AppTheme.macroProtein;
      case 'snack':
        return AppTheme.accentPurple;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String get _defaultTime {
    switch (widget.mealType) {
      case 'breakfast':
        return '8:00 AM';
      case 'lunch':
        return '1:00 PM';
      case 'snack':
        return '4:30 PM';
      default:
        return '7:30 PM';
    }
  }

  String get _timeLabel {
    for (final m in widget.meals) {
      if (m is Map && m['meal_time'] != null) {
        final parsed = DateTime.tryParse(m['meal_time'].toString());
        if (parsed != null) return DateFormat('h:mm a').format(parsed);
      }
    }
    return _defaultTime;
  }

  int get _kcal {
    var total = 0;
    for (final m in widget.meals) {
      if (m is Map) {
        total += ((m['total_calories'] ?? m['calories'] ?? 0) as num).toInt();
      }
    }
    return total;
  }

  List<_FoodRowData> get _rows {
    final rows = <_FoodRowData>[];
    for (final m in widget.meals) {
      if (m is! Map) continue;
      final imageUrl = (m['image_url'] ?? '').toString();
      final items = m['items'];
      if (items is List && items.isNotEmpty) {
        for (final it in items) {
          if (it is! Map) continue;
          final grams = ((it['grams'] ?? 0) as num).toInt();
          rows.add(_FoodRowData(
            name: (it['food_name'] ?? it['name'] ?? 'Meal').toString(),
            portion: grams > 0 ? '${grams}g' : '',
            kcal: ((it['calories'] ?? 0) as num).toInt(),
            imageUrl: imageUrl,
          ));
        }
      } else {
        rows.add(_FoodRowData(
          name: (m['notes'] ?? 'Meal').toString(),
          portion: '',
          kcal: ((m['total_calories'] ?? m['calories'] ?? 0) as num).toInt(),
          imageUrl: imageUrl,
        ));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, size: 20, color: _color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_kcal kcal',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.lightTextSecondary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nothing logged yet — tap + Add Food',
                    style: TextStyle(fontSize: 13, color: AppTheme.lightTextSecondary),
                  ),
                ),
              )
            else
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: r.imageUrl.isNotEmpty
                              ? Image.network(
                                  r.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _Thumb(icon: _icon, color: _color),
                                )
                              : _Thumb(icon: _icon, color: _color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (r.portion.isNotEmpty)
                              Text(
                                r.portion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.kcal} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FoodRowData {
  final String name;
  final String portion;
  final int kcal;
  final String imageUrl;

  const _FoodRowData({
    required this.name,
    required this.portion,
    required this.kcal,
    required this.imageUrl,
  });
}

class _Thumb extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Thumb({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.1),
      child: Center(child: Icon(icon, size: 20, color: color)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
