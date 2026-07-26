import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
import 'food_detail_screen.dart';
import 'models.dart';
import 'theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.meal});
  final MealType meal;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodItem> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return foodDatabase;
    return foodDatabase
        .where(
          (f) => f.nameEn.toLowerCase().contains(q) || f.nameAr.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final results = _results;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text('${l.add} · ${l.mealName(widget.meal)}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: c.ink),
              decoration: InputDecoration(
                hintText: l.searchHint,
                hintStyle: TextStyle(color: c.muted),
                prefixIcon: Icon(Icons.search, color: c.muted),
                filled: true,
                fillColor: c.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_outlined,
                    line: l.noResults,
                    hint: l.searchEmptyHint,
                    actionLabel: l.clearSearch,
                    onAction: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: results.length,
                    itemBuilder: (context, i) =>
                        _FoodTile(food: results[i], meal: widget.meal),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.meal});
  final FoodItem food;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    return Container(
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
            '${l.servingLabel(food)} · ${l.category(food.category)}',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          // Row order only — never flipped by hand, so RTL mirrors it.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${fmtInt(food.kcal)} ${l.kcal}',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.protein,
                    ),
                  ),
                ),
              ),
              _QuickAddButton(food: food, meal: meal),
            ],
          ),
          // Search is itself a pushed route; when the detail page reports a
          // successful log (pop(true)), also close search so the user lands
          // back on Home, matching the old sheet-on-search behavior.
          onTap: () async {
            final logged = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => FoodDetailScreen(food: food, meal: meal),
              ),
            );
            if (logged == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}

/// Logs one base serving straight into [meal] without leaving the list:
/// haptic, then an undo snackbar (mirrors the delete-undo pattern) since
/// local-only storage has no backup for a mis-tap. Min 44×44 tap target.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.food, required this.meal});
  final FoodItem food;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    // Exact 44×44 footprint: IconButton's own min-tap-target padding would
    // overflow a SizedBox wrapper, so build the circle directly.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _quickAdd(context, state),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_circle_outline, color: c.accent),
        ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, AppState state) async {
    final l = state.l;
    HapticFeedback.lightImpact();
    final date = state.selectedDate;
    final ok = await state.addEntry(date, food.id, 1.0, meal);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
      return;
    }
    final kcal = food.kcal;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${l.added}: ${l.foodName(food)} · ${fmtInt(kcal)} ${l.kcal}'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            // Quick add always logs exactly one fresh entry; find and
            // remove it by matching food+meal+quantity on today's list —
            // safe because it was just added and ids are unique per tap.
            final match = state
                .entriesFor(date, meal: meal)
                .lastWhere(
                  (e) => e.foodId == food.id && e.quantity == 1.0,
                );
            await state.removeEntry(date, match.id);
          },
        ),
      ),
    );
  }
}
