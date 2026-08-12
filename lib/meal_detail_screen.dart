import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'search_screen.dart';
import 'theme.dart';

/// Deletes an entry with a 4-second undo: local-only storage means a
/// mis-tap has no server backup, so a one-tap restore matters. The
/// removed entry (and its position) come back from [AppState.removeEntry].
Future<void> _deleteWithUndo(
  BuildContext context,
  AppState state,
  LogEntry entry,
) async {
  final l = state.l;
  final date = state.selectedDate;
  // Delete is a more consequential tap than an add — a stronger cue than
  // the lightImpact used for logging.
  HapticFeedback.mediumImpact();
  final removed = await state.removeEntry(date, entry.id);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  if (removed == null) {
    // Nothing was removed (write failed → rolled back): surface the error.
    messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
    return;
  }
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l.removed),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l.undo,
        onPressed: () => state.restoreEntry(date, removed.entry, removed.index),
      ),
    ),
  );
}

/// Row exit animation duration — collapse + fade before the entry actually
/// leaves [AppState], so the list never just blinks an item away.
const _rowAnimDuration = Duration(milliseconds: 200);

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final entries = state.entriesFor(state.selectedDate, meal: meal);
    final totalKcal = entries.fold<double>(
      0,
      (sum, e) => sum + (foodById[e.foodId]?.kcal ?? 0) * e.servings,
    );

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Row(
          children: [
            MealIcon(meal, size: 22),
            const SizedBox(width: 10),
            Text(l.mealName(meal)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => SearchScreen(meal: meal))),
        child: const Icon(Icons.add),
      ),
      body: entries.isEmpty
          ? EmptyState(
              graphic: MealIcon(meal, size: 30, color: c.accent),
              line: l.notLoggedYet,
              actionLabel: l.addFood,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SearchScreen(meal: meal)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final food = foodById[entry.foodId];
                      if (food == null) return const SizedBox.shrink();
                      return _EntryRow(
                        key: ValueKey(entry.id),
                        entry: entry,
                        food: food,
                        state: state,
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.total,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          '${fmtInt(totalKcal)} ${l.kcal}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: c.kcalAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A single meal-detail row: fades + slides in on first appearance and
/// collapses before the entry actually leaves [AppState] on delete — a
/// plain rebuild would otherwise just blink the row in and out.
class _EntryRow extends StatefulWidget {
  const _EntryRow({
    super.key,
    required this.entry,
    required this.food,
    required this.state,
  });
  final LogEntry entry;
  final FoodItem food;
  final AppState state;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _rowAnimDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entered) return;
    _entered = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!MediaQuery.of(context).disableAnimations) {
      await _controller.reverse();
    }
    if (!mounted) return;
    await _deleteWithUndo(context, widget.state, widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = widget.state.l;
    final entry = widget.entry;
    final food = widget.food;
    final kcal = (food.kcal * entry.servings).round();

    return SizeTransition(
      sizeFactor: _controller,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: c.cardShadow,
            ),
            child: Material(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  l.foodName(food),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                subtitle: Text(
                  entry.loggedAt == null
                      ? '${fmtServings(entry.servings)} × ${l.servingLabel(food)}'
                      : '${fmtServings(entry.servings)} × '
                            '${l.servingLabel(food)} · '
                            '${fmtTime(entry.loggedAt!.hour, entry.loggedAt!.minute)}',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${fmtInt(kcal)} ${l.kcal}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.kcalAccent,
                      ),
                    ),
                    IconButton(
                      tooltip: l.delete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: c.muted,
                      ),
                      onPressed: _handleDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
