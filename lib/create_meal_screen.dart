import 'dart:async';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'food_db.dart';
import 'models.dart';
import 'round_icon_button.dart';
import 'settings_screen.dart' show WesternDigitsFormatter;
import 'theme.dart';

/// Full-screen meal builder: name, optional meal-type tag, food search,
/// running list with per-item serving edit, live totals, save. [existing]
/// non-null puts the screen in edit mode (My Meals tab long-press → Edit):
/// fields prefill from it and Save updates it in place instead of creating
/// a new SavedMeal.
class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key, this.existing});
  final SavedMeal? existing;

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  MealType? _mealType;
  final List<SavedMealItem> _items = [];
  String? _nameError;
  Timer? _debounce;
  List<FoodItem> _searchResults = const [];

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
    _debounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final q = value.trim().toLowerCase();
      if (!mounted) return;
      setState(() {
        _searchResults = q.isEmpty
            ? const []
            : [
                for (final f in foodDatabase)
                  if (f.nameEn.toLowerCase().contains(q) ||
                      f.nameAr.contains(q))
                    f,
              ].take(20).toList();
      });
    });
  }

  void _addFood(FoodItem food) {
    setState(() {
      final index = _items.indexWhere((i) => i.foodId == food.id);
      if (index >= 0) {
        _items[index] = SavedMealItem(
          foodId: food.id,
          servings: _items[index].servings + 1,
        );
      } else {
        _items.add(SavedMealItem(foodId: food.id, servings: 1));
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                TextField(
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
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
                for (final food in _searchResults)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.foodName(food),
                      style: TextStyle(fontSize: 14, color: c.ink),
                    ),
                    subtitle: Text(
                      l.servingLabel(food),
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                    trailing: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _addFood(food),
                        child: RoundIconButton(
                          bg: c.plusIdleBg,
                          icon: Icons.add,
                          iconColor: c.plusIdleIcon,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  l.meals,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l.noFoodsAddedYet,
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                  )
                else
                  for (var i = 0; i < _items.length; i++)
                    _MealItemRow(
                      key: ValueKey(_items[i].foodId),
                      item: _items[i],
                      onServingsChanged: (v) => _updateServings(i, v),
                      onRemove: () => _removeItem(i),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(color: c.card, boxShadow: c.cardShadow),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l.carb} ${fmtGrams(carbs)}${l.grams}',
                        style: TextStyle(fontSize: 12, color: c.carb),
                      ),
                      Text(
                        '${l.fat} ${fmtGrams(fat)}${l.grams}',
                        style: TextStyle(fontSize: 12, color: c.fat),
                      ),
                      Text(
                        '${l.protein} ${fmtGrams(protein)}${l.grams}',
                        style: TextStyle(fontSize: 12, color: c.protein),
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
