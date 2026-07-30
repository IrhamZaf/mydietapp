import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/core/network/api_exception.dart';
import 'package:my_diet_app/features/ai_scanner/presentation/controllers/ai_scanner_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/screens/dashboard_screen.dart';

class ManualMealScreen extends ConsumerStatefulWidget {
  const ManualMealScreen({super.key});

  @override
  ConsumerState<ManualMealScreen> createState() => _ManualMealScreenState();
}

class _ManualMealScreenState extends ConsumerState<ManualMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbsCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');
  String _mealType = 'lunch';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(mealRepositoryProvider).logMeal(
            name: _nameCtrl.text.trim(),
            mealType: _mealType,
            calories: int.parse(_caloriesCtrl.text.trim()),
            protein: int.tryParse(_proteinCtrl.text.trim()) ?? 0,
            carbs: int.tryParse(_carbsCtrl.text.trim()) ?? 0,
            fat: int.tryParse(_fatCtrl.text.trim()) ?? 0,
          );
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(mealsForDateProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal logged successfully'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to log meal.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Key in Food'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'e.g. Nasi Ayam',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a food name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinCtrl,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsCtrl,
                      decoration: const InputDecoration(labelText: 'Carbs (g)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatCtrl,
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'MEAL TYPE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.lightTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in ['breakfast', 'lunch', 'dinner', 'snack'])
                    ChoiceChip(
                      label: Text(type[0].toUpperCase() + type.substring(1)),
                      selected: _mealType == type,
                      onSelected: (_) => setState(() => _mealType = type),
                      selectedColor: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _mealType == type
                            ? AppTheme.primaryEmerald
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Log Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
