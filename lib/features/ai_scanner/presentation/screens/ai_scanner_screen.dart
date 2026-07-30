import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/ai_scanner/presentation/controllers/ai_scanner_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:my_diet_app/features/dashboard/presentation/screens/dashboard_screen.dart';

class AiScannerScreen extends ConsumerStatefulWidget {
  const AiScannerScreen({super.key});

  @override
  ConsumerState<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends ConsumerState<AiScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (photo != null) {
        ref.read(aiScannerControllerProvider.notifier).setImage(File(photo.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Could not open camera. Check camera permission in Settings.'
                : 'Could not open photo library. Check photo permission in Settings.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiScannerControllerProvider);
    final controller = ref.read(aiScannerControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('AI Meal Scanner 📷'),
        centerTitle: true,
        actions: [
          if (state.imageFile != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => controller.reset(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.imageFile == null)
                _buildImagePickerPrompt(context)
              else
                _buildImagePreviewAndResults(context, state, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerPrompt(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            size: 64,
            color: AppTheme.primaryEmerald,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Snap Your Meal',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a photo or pick from gallery. Our AI will identify each item line-by-line (Rice, Chicken, Kuah, etc.).',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),

        ElevatedButton.icon(
          icon: const Icon(Icons.camera_rounded),
          label: const Text('Take Photo with Camera'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onPressed: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text('Choose from Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildImagePreviewAndResults(
    BuildContext context,
    AiScannerState state,
    AiScannerController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Preview Box
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                state.imageFile!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              if (state.isScanning) ...[
                Container(
                  height: 240,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryEmerald),
                      SizedBox(height: 16),
                      Text(
                        'AI is analyzing components...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Identifying Rice, Chicken, Kuah, Vegetables 1-by-1',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.amber.shade800),
                    const SizedBox(width: 10),
                    const Text(
                      'Rate Limit Active',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.lightTextPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry Scanning Now'),
                    onPressed: () => controller.scanImage(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (state.scannedResult != null) ...[
          // Total Meal Summary Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.lightBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Meal Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'AI Confidence: ${state.scannedResult!.confidence.toUpperCase()}',
                        style: const TextStyle(
                          color: AppTheme.primaryEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Portion: ${state.scannedResult!.portionSize}',
                  style: const TextStyle(color: AppTheme.lightTextSecondary, fontSize: 13),
                ),
                const Divider(height: 24, color: AppTheme.lightBorder),

                // Overall Macro Totals
                Row(
                  children: [
                    _MacroTile(
                      label: 'Calories',
                      value: '${state.scannedResult!.calories}',
                      unit: 'kcal',
                      color: AppTheme.primaryEmerald,
                    ),
                    const SizedBox(width: 8),
                    _MacroTile(
                      label: 'Protein',
                      value: '${state.scannedResult!.protein}',
                      unit: 'g',
                      color: AppTheme.secondaryTeal,
                    ),
                    const SizedBox(width: 8),
                    _MacroTile(
                      label: 'Carbs',
                      value: '${state.scannedResult!.carbs}',
                      unit: 'g',
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    _MacroTile(
                      label: 'Fat',
                      value: '${state.scannedResult!.fat}',
                      unit: 'g',
                      color: AppTheme.accentOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1-by-1 Itemized Component Breakdown Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DETECTED FOOD ITEMS (1 BY 1)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.lightTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${state.scannedResult!.items.length} items',
                style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (state.scannedResult!.items.isNotEmpty)
            ...state.scannedResult!.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getFoodIcon(item.foodName),
                          color: AppTheme.primaryEmerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.lightTextPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.grams}g • P: ${item.protein}g | C: ${item.carbs}g | F: ${item.fat}g',
                              style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.lightInputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.calories} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 20),

          // Meal Type Selector
          const Text(
            'SELECT MEAL TYPE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.lightTextSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MealTypeChip(
                label: 'Breakfast',
                icon: Icons.wb_sunny_rounded,
                isSelected: state.selectedMealType == 'breakfast',
                onTap: () => controller.setMealType('breakfast'),
              ),
              const SizedBox(width: 8),
              _MealTypeChip(
                label: 'Lunch',
                icon: Icons.lunch_dining_rounded,
                isSelected: state.selectedMealType == 'lunch',
                onTap: () => controller.setMealType('lunch'),
              ),
              const SizedBox(width: 8),
              _MealTypeChip(
                label: 'Dinner',
                icon: Icons.dinner_dining_rounded,
                isSelected: state.selectedMealType == 'dinner',
                onTap: () => controller.setMealType('dinner'),
              ),
              const SizedBox(width: 8),
              _MealTypeChip(
                label: 'Snack',
                icon: Icons.cookie_rounded,
                isSelected: state.selectedMealType == 'snack',
                onTap: () => controller.setMealType('snack'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Save Button
          ElevatedButton.icon(
            icon: state.isLogging
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(state.isLogging ? 'Logging Meal...' : 'Log This Meal'),
            onPressed: state.isLogging
                ? null
                : () async {
                    final success = await controller.saveMeal();
                    if (success && context.mounted) {
                      ref.invalidate(dashboardControllerProvider);
                      ref.invalidate(mealsForDateProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${state.scannedResult!.foodName} logged successfully! 🎉'),
                          backgroundColor: AppTheme.primaryEmerald,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ],
    );
  }

  IconData _getFoodIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rice') || lower.contains('nasi')) return Icons.grain_rounded;
    if (lower.contains('chicken') || lower.contains('ayam') || lower.contains('meat')) return Icons.kebab_dining_rounded;
    if (lower.contains('gravy') || lower.contains('kuah') || lower.contains('curry') || lower.contains('soup')) return Icons.soup_kitchen_rounded;
    if (lower.contains('veg') || lower.contains('sayur')) return Icons.eco_rounded;
    return Icons.restaurant_rounded;
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              unit,
              style: const TextStyle(fontSize: 10, color: AppTheme.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryEmerald : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryEmerald : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
