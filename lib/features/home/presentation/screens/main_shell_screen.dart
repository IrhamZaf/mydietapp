import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_diet_app/core/config/theme.dart';
import 'package:my_diet_app/features/ai_scanner/presentation/screens/ai_scanner_screen.dart';
import 'package:my_diet_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:my_diet_app/features/meals/presentation/screens/manual_meal_screen.dart';
import 'package:my_diet_app/features/profile/presentation/screens/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    ProfileScreen(),
  ];

  void _openAddFoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Food',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan a meal or key in nutrition details',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.lightTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _SheetAction(
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan with Camera',
                  subtitle: 'AI identifies each food item',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiScannerScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.edit_note_rounded,
                  title: 'Key in Food',
                  subtitle: 'Enter calories and macros manually',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManualMealScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: _openAddFoodSheet,
          elevation: 6,
          backgroundColor: AppTheme.primaryEmerald,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 34),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Dashboard',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
              ),
              const SizedBox(width: 72), // space for center FAB
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profile',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryEmerald : AppTheme.lightTextSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.lightBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryEmerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.lightTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
