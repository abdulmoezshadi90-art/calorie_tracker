import 'package:flutter/material.dart';

import 'app_state.dart';
import 'food_db.dart';
import 'food_picker.dart';
import 'models.dart';
import 'settings_screen.dart' show WesternDigitsFormatter;
import 'theme.dart';

/// Full-screen meal builder: name, optional meal-type tag, the shared food
/// picker (food_picker.dart — All Foods/History/My Meals, same as the log
/// flow), running list with per-item serving edit, live totals, save.
/// Picking a food or saved meal here adds a draft row instead of pushing a
/// detail screen or logging to today, since there is no "today" in a
/// draft meal. [existing] non-null puts the screen in edit mode (My Meals
/// tab long-press → Edit): fields prefill from it and Save updates it in
/// place instead of creating
/// a new SavedMeal.
class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key, this.existing});
  final SavedMeal? existing;

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  final _nameController = TextEditingController();
  MealType? _mealType;
  final List<SavedMealItem> _items = [];
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _mealType = existing.mealType;
      _items.addAll(existing.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Picking a food from the shared picker (row tap or quick-add — there is
  /// no separate detail-screen step here, so both mean the same thing:
  /// add a draft row starting at [servings]). Merges into an existing row
  /// for the same food rather than duplicating it.
  void _addFood(FoodItem food, double servings) {
    setState(() {
      final index = _items.indexWhere((i) => i.foodId == food.id);
      if (index >= 0) {
        _items[index] = SavedMealItem(
          foodId: food.id,
          servings: _items[index].servings + servings,
        );
      } else {
        _items.add(SavedMealItem(foodId: food.id, servings: servings));
      }
    });
  }

  /// Picking a saved meal from the shared picker's My Meals tab — merges
  /// every one of its items into the draft the same way a single food does.
  void _addSavedMealItems(SavedMeal meal) {
    setState(() {
      for (final item in meal.items) {
        final index = _items.indexWhere((i) => i.foodId == item.foodId);
        if (index >= 0) {
          _items[index] = SavedMealItem(
            foodId: item.foodId,
            servings: _items[index].servings + item.servings,
          );
        } else {
          _items.add(item);
        }
      }
    });
  }

  void _updateServings(int index, double servings) {
    setState(() {
      _items[index] = SavedMealItem(
        foodId: _items[index].foodId,
        servings: servings,
      );
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Future<void> _save() async {
    final state = AppScope.of(context);
    final l = state.l;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l.mealNameRequired);
      return;
    }
    final existing = widget.existing;
    final meal = existing != null
        ? existing.copyWith(
            name: name,
            mealType: _mealType,
            clearMealType: _mealType == null,
            items: List.of(_items),
          )
        : SavedMeal(
            id: state.newSavedMealId(),
            name: name,
            mealType: _mealType,
            items: List.of(_items),
            createdAt: state.now(),
          );
    final ok = existing != null
        ? await state.updateSavedMeal(meal)
        : await state.addSavedMeal(meal);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.saveFailed)));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.mealSaved)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    double sumFor(double Function(FoodItem) pick) =>
        _items.fold(0.0, (sum, item) {
          final food = foodById[item.foodId];
          if (food == null) return sum;
          return sum + pick(food) * item.servings;
        });
    final kcal = sumFor((f) => f.kcal.toDouble());
    final carbs = sumFor((f) => f.carbs);
    final fat = sumFor((f) => f.fat);
    final protein = sumFor((f) => f.protein);
    final canSave = _nameController.text.trim().isNotEmpty && _items.isNotEmpty;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(l.createMealTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metadata = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() => _nameError = null),
                  style: TextStyle(color: c.ink),
                  decoration: InputDecoration(
                    labelText: l.mealNameLabel,
                    errorText: _nameError,
                    filled: true,
                    fillColor: c.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.mealTypeOptional,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MealTypeChip(
                          label: l.noneOption,
                          selected: _mealType == null,
                          onTap: () => setState(() => _mealType = null),
                        ),
                        for (final m in MealType.values)
                          _MealTypeChip(
                            label: l.mealName(m),
                            selected: _mealType == m,
                            onTap: () => setState(() => _mealType = m),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Text(
                      l.meals,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (_items.isEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l.noFoodsAddedYet,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: c.muted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_items.isNotEmpty)
                // Bounded height, own scroll: this list can grow past
                // what a short screen has room for, and it must never
                // eat into the picker's space below as it does — a
                // fixed-height Column here would just move the overflow
                // instead of fixing it.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _MealItemRow(
                        key: ValueKey(_items[i].foodId),
                        item: _items[i],
                        onServingsChanged: (v) => _updateServings(i, v),
                        onRemove: () => _removeItem(i),
                      ),
                    ),
                  ),
                ),
            ],
          );

          // Below ~700px tall (an iPhone 5/SE-class screen, or the picker's
          // own minimum tab content squeezed by a compact meal already in
          // progress) there usually isn't room for the metadata section's
          // natural height AND the picker's own minimum. Cap and scroll it
          // there; on every normal screen it renders at its natural size
          // with no scroll wrapper, so nothing gets silently clipped into
          // an easy-to-miss scroll region the way a permanent flex split
          // would (see the empty_state.dart scroll safety-net for the
          // picker's own remaining-squeeze case).
          final isShort = constraints.maxHeight < 700;

          return Column(
            children: [
              if (isShort)
                Flexible(child: SingleChildScrollView(child: metadata))
              else
                metadata,
              Container(height: 1, color: c.divider),
              Expanded(
                child: FoodPicker(
                  onFoodTap: _addFood,
                  onFoodQuickAdd: _addFood,
                  onMealTap: _addSavedMealItems,
                  onMealQuickAdd: _addSavedMealItems,
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    boxShadow: c.cardShadow,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l.total,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            '${fmtInt(kcal)} ${l.kcal}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.kcalAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l.carb} ${fmtGrams(carbs)}${l.grams}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: c.carb),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${l.fat} ${fmtGrams(fat)}${l.grams}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: c.fat),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${l.protein} ${fmtGrams(protein)}${l.grams}',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: c.protein),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                          onPressed: canSave ? _save : null,
                          child: Text(
                            l.save,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  const _MealTypeChip({
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.chipBg,
      backgroundColor: c.card,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? c.chipText : c.ink,
      ),
      side: BorderSide(color: selected ? c.accent : c.divider),
    );
  }
}

/// One added-food row: name, a -/+ 0.5-step servings stepper (same pattern
/// as the quantity stepper in food_detail_screen.dart's _DecimalPicker,
/// duplicated here since that widget is private to that file), and remove.
class _MealItemRow extends StatefulWidget {
  const _MealItemRow({
    super.key,
    required this.item,
    required this.onServingsChanged,
    required this.onRemove,
  });
  final SavedMealItem item;
  final ValueChanged<double> onServingsChanged;
  final VoidCallback onRemove;

  @override
  State<_MealItemRow> createState() => _MealItemRowState();
}

class _MealItemRowState extends State<_MealItemRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: fmtServings(widget.item.servings),
    );
  }

  @override
  void didUpdateWidget(covariant _MealItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.servings != widget.item.servings) {
      _controller.text = fmtServings(widget.item.servings);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(double delta) {
    final v = double.tryParse(_controller.text) ?? widget.item.servings;
    final next = (v + delta).clamp(0.5, 99.0);
    final rounded = (next * 10).round() / 10;
    _controller.text = fmtServings(rounded);
    widget.onServingsChanged(rounded);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = AppScope.of(context);
    final l = state.l;
    final food = foodById[widget.item.foodId];
    if (food == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.foodName(food),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: c.ink),
            ),
          ),
          IconButton(
            iconSize: 16,
            onPressed: () => _step(-0.5),
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              backgroundColor: c.macroTrack,
              foregroundColor: c.ink,
            ),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [
                WesternDigitsFormatter(allowDecimal: true),
              ],
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed > 0) {
                  widget.onServingsChanged(parsed);
                }
              },
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: c.macroTrack,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            iconSize: 16,
            onPressed: () => _step(0.5),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: c.macroTrack,
              foregroundColor: c.ink,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: c.muted),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
