import 'package:flutter/material.dart';

import 'app_state.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Persistent bottom navigation: Today, History, Add (center, prominent),
/// Settings. Today/History/Settings are kept alive in an IndexedStack;
/// Add is an action, not a tab — it opens the meal chooser → search flow.
/// Row-based, so item order mirrors automatically in RTL.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Lets embedded tab screens switch tabs (e.g. History's empty-state
/// "Back to today"). Null when a screen is shown outside the shell.
class AppTabs extends InheritedWidget {
  const AppTabs({super.key, required this.select, required super.child});
  final void Function(int index) select;

  static AppTabs? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabs>();

  @override
  bool updateShouldNotify(AppTabs oldWidget) => false;
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return Scaffold(
      body: AppTabs(
        select: (i) => setState(() => _tab = i),
        child: IndexedStack(
          index: _tab,
          children: const [HomeScreen(), HistoryScreen(), SettingsScreen()],
        ),
      ),
      // Manual shadow like the cards (elevation renders as solid black
      // under the golden test's disabled-shadows mode).
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.card, boxShadow: c.cardShadow),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: l.today,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _NavItem(
                  icon: Icons.history,
                  selectedIcon: Icons.history,
                  label: l.history,
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _AddButton(
                  key: const Key('nav-add'),
                  label: l.add,
                  onTap: () {
                    // Adding always concerns today's diary.
                    setState(() => _tab = 0);
                    showMealChooser(context, state);
                  },
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: l.settings,
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.accent : c.muted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Center, prominent: a raised accent circle, per the adopted pattern.
class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: c.cardShadow,
            ),
            child: Material(
              color: c.accent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.add, size: 28, color: c.onAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
