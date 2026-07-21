import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'empty_state.dart';
import 'food_db.dart';
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
    final l = AppScope.of(context).l;
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
          trailing: Text(
            '${fmtInt(food.kcal)} ${l.kcal}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.protein,
            ),
          ),
          onTap: () => _showAddSheet(context),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    var servings = 1.0;
    // Brief checkmark flash on the confirm button before the sheet pops,
    // confirming the tap landed (the home meter fill is the fuller cue).
    var justSaved = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final l = state.l;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final kcal = (food.kcal * servings).round();
            // Scrollable: preset chips can push the sheet past short
            // screens, and the keyboard shrinks the space further.
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.foodName(food),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.servingLabel(food)} · ${fmtInt(food.kcal)} ${l.kcal} ${l.perServing}',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l.protein}: ${fmtGrams(food.protein)}${l.grams} · '
                    '${l.carb}: ${fmtGrams(food.carbs)}${l.grams} · '
                    '${l.fat}: ${fmtGrams(food.fat)}${l.grams}',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                  // Household portion chips (Phase 4): tapping one sets the
                  // servings from its exact gram weight; the stepper below
                  // remains for fine adjustment.
                  if (food.presets.isNotEmpty && food.servingGrams != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in food.presets)
                          _PresetChip(
                            label:
                                '${l.isAr ? preset.nameAr : preset.nameEn} · ${fmtGrams(preset.grams)} ${l.grams}',
                            selected:
                                servings == food.servingsFor(preset),
                            onTap: () => setSheetState(
                              () => servings = food.servingsFor(preset),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.servings,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Row(
                        children: [
                          _stepBtn(c, Icons.remove, () {
                            if (servings > 0.5) {
                              setSheetState(() => servings -= 0.5);
                            }
                          }),
                          SizedBox(
                            width: 48,
                            child: Text(
                              fmtServings(servings),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                          ),
                          _stepBtn(c, Icons.add, () {
                            if (servings < 10) {
                              setSheetState(() => servings += 0.5);
                            }
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      // No-op (not null) while flashing so the button keeps
                      // its accent styling instead of greying out.
                      onPressed: justSaved
                          ? () {}
                          : () async {
                              HapticFeedback.lightImpact();
                              // Await the write; only proceed on success so
                              // the meter never confirms an unsaved entry.
                              final ok = await state.addEntry(
                                state.selectedDate,
                                food.id,
                                servings,
                                meal,
                              );
                              if (!sheetContext.mounted) return;
                              if (!ok) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text(l.saveFailed)),
                                );
                                return;
                              }
                              // Flash the checkmark, then pop.
                              setSheetState(() => justSaved = true);
                              await Future<void>.delayed(
                                const Duration(milliseconds: 350),
                              );
                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${l.added}: ${l.foodName(food)} · ${fmtInt(kcal)} ${l.kcal}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                      child: justSaved
                          ? Icon(Icons.check, size: 22, color: c.onAccent)
                          : Text(
                              '${l.add} · ${fmtInt(kcal)} ${l.kcal}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _stepBtn(AppColors c, IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: c.macroTrack,
        foregroundColor: c.ink,
      ),
    );
  }
}

/// Portion chip: selected state uses the accent, idle stays neutral.
/// Min 44px tall for touch targets; ink ripple on tap.
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: selected ? c.accent : c.chipBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? c.onAccent : c.chipText,
            ),
          ),
        ),
      ),
    );
  }
}
