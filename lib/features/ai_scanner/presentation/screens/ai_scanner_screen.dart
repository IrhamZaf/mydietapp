import 'dart:io';

import 'package:camera/camera.dart';
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

class _AiScannerScreenState extends ConsumerState<AiScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  Future<void>? _cameraFuture;
  bool _capturing = false;
  late final AnimationController _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = backCamera.isNotEmpty ? backCamera.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      setState(() {
        _cameraController = controller;
        _cameraFuture = controller.initialize();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not start camera. Check camera permission in Settings.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickGalleryImage() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted || photo == null) return;
      ref.read(aiScannerControllerProvider.notifier).setImage(File(photo.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not open photo library. Check photo permission in Settings.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _captureFromCamera() async {
    if (_capturing || _cameraController == null) return;
    try {
      setState(() => _capturing = true);
      await _cameraFuture;
      final photo = await _cameraController!.takePicture();
      if (!mounted) return;
      ref.read(aiScannerControllerProvider.notifier).setImage(File(photo.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not capture photo. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiScannerControllerProvider);
    final controller = ref.read(aiScannerControllerProvider.notifier);

    if (state.isScanning) {
      _scanAnimation.repeat(reverse: false);
    } else {
      _scanAnimation.stop();
    }

    final hasCapturedImage = state.imageFile != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: hasCapturedImage
                ? Image.file(state.imageFile!, fit: BoxFit.cover)
                : _LiveCameraPreview(cameraFuture: _cameraFuture, controller: _cameraController),
          ),
          const Positioned.fill(child: _ScannerVignette()),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: _TopBar(
                    hasCapturedImage: hasCapturedImage,
                    onBack: () => Navigator.of(context).maybePop(),
                    onReset: () => controller.reset(),
                  ),
                ),
                if (!hasCapturedImage)
                  const Positioned.fill(
                    child: IgnorePointer(child: _CameraFrame()),
                  ),
                if (!hasCapturedImage)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 28,
                    child: _CaptureControls(
                      isBusy: _capturing,
                      onGalleryTap: _pickGalleryImage,
                      onShutterTap: _captureFromCamera,
                    ),
                  ),
                if (state.isScanning)
                  Positioned.fill(
                    child: _ScanningOverlay(animation: _scanAnimation),
                  ),
                if (state.errorMessage != null && !state.isScanning)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: _ErrorRetryCard(
                      message: state.errorMessage!,
                      onRetry: controller.scanImage,
                      onReset: controller.reset,
                    ),
                  ),
                if (state.scannedResult != null && !state.isScanning)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ResultSheet(
                      state: state,
                      controller: controller,
                      onSaved: () async {
                        final success = await controller.saveMeal();
                        if (success && context.mounted) {
                          ref.invalidate(dashboardControllerProvider);
                          ref.invalidate(mealsForDateProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${state.scannedResult!.foodName} logged successfully!',
                              ),
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _LiveCameraPreview extends StatelessWidget {
  final Future<void>? cameraFuture;
  final CameraController? controller;

  const _LiveCameraPreview({this.cameraFuture, this.controller});

  @override
  Widget build(BuildContext context) {
    if (cameraFuture == null || controller == null) {
      return const ColoredBox(
        color: Color(0xFF0E0E10),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return FutureBuilder<void>(
      future: cameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Color(0xFF0E0E10),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        if (snapshot.hasError) {
          return const ColoredBox(
            color: Color(0xFF0E0E10),
            child: Center(
              child: Text(
                'Camera unavailable',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }
        return CameraPreview(controller!);
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool hasCapturedImage;
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _TopBar({
    required this.hasCapturedImage,
    required this.onBack,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundOverlayButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Spacer(),
        if (hasCapturedImage)
          _RoundOverlayButton(
            icon: Icons.refresh_rounded,
            onTap: onReset,
          ),
      ],
    );
  }
}

class _RoundOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundOverlayButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ScannerVignette extends StatelessWidget {
  const _ScannerVignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.65),
            ],
            stops: const [0, 0.22, 0.65, 1],
          ),
        ),
      ),
    );
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 48,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              _FrameCorner(alignment: Alignment.topLeft),
              _FrameCorner(alignment: Alignment.topRight),
              _FrameCorner(alignment: Alignment.bottomLeft),
              _FrameCorner(alignment: Alignment.bottomRight),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameCorner extends StatelessWidget {
  final Alignment alignment;

  const _FrameCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;

  const _CaptureControls({
    required this.isBusy,
    required this.onGalleryTap,
    required this.onShutterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Food',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onGalleryTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 56),
            GestureDetector(
              onTap: isBusy ? null : onShutterTap,
              child: Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 4),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 56),
          ],
        ),
      ],
    );
  }
}

class _ScanningOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ScanningOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 52,
          height: MediaQuery.of(context).size.height * 0.58,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 2,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Positioned(
                    top: (MediaQuery.of(context).size.height * 0.58 - 8) * animation.value,
                    left: 10,
                    right: 10,
                    child: child!,
                  );
                },
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.75),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onReset;

  const _ErrorRetryCard({
    required this.message,
    required this.onRetry,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppTheme.lightTextSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final AiScannerState state;
  final AiScannerController controller;
  final Future<void> Function() onSaved;

  const _ResultSheet({
    required this.state,
    required this.controller,
    required this.onSaved,
  });

  IconData _getFoodIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rice') || lower.contains('nasi')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('chicken') ||
        lower.contains('ayam') ||
        lower.contains('meat')) {
      return Icons.kebab_dining_rounded;
    }
    if (lower.contains('gravy') ||
        lower.contains('kuah') ||
        lower.contains('curry') ||
        lower.contains('soup')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('veg') || lower.contains('sayur')) {
      return Icons.eco_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final result = state.scannedResult!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.foodName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.portionSize,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.confidence.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MacroTile(
                    label: 'Calories',
                    value: '${result.calories}',
                    unit: 'kcal',
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _MacroTile(
                    label: 'Protein',
                    value: '${result.protein}',
                    unit: 'g',
                    color: AppTheme.macroProtein,
                  ),
                  const SizedBox(width: 8),
                  _MacroTile(
                    label: 'Carbs',
                    value: '${result.carbs}',
                    unit: 'g',
                    color: AppTheme.macroCarbs,
                  ),
                  const SizedBox(width: 8),
                  _MacroTile(
                    label: 'Fat',
                    value: '${result.fat}',
                    unit: 'g',
                    color: AppTheme.macroFat,
                  ),
                ],
              ),
              if (result.items.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Detected items',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...result.items.map(
                  (item) => Container(
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
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getFoodIcon(item.foodName),
                            color: AppTheme.primaryBlue,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.grams}g • P ${item.protein} • C ${item.carbs} • F ${item.fat}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.calories} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Meal type',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.lightTextPrimary,
                ),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: state.isLogging
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(state.isLogging ? 'Saving...' : 'Log This Meal'),
                  onPressed: state.isLogging ? null : onSaved,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
