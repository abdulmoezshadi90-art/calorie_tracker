import 'dart:async';

import 'package:flutter/material.dart';

import 'all_foods_tab.dart';
import 'app_state.dart';
import 'food_history_tab.dart';
import 'models.dart';
import 'saved_meals_tab.dart';
import 'theme.dart';

/// Shared search bar + three-tab selector + tab content, reused by every
/// food-selection surface (search_screen.dart's log flow,
/// create_meal_screen.dart's meal builder). What happens when a food or
/// saved meal is picked is entirely caller-defined via callbacks — the
/// picker itself never branches on which screen is hosting it.
///
/// Tab order: All Foods, History, My Meals (mirrored in RTL by
/// Directionality, not by hand). All Foods is always populated (food_db is
/// never empty) so it is what a first-time user sees instead of the old
/// blank History/My Meals tabs.
class FoodPicker extends StatefulWidget {
  const FoodPicker({
    super.key,
    required this.onFoodTap,
    required this.onFoodQuickAdd,
    required this.onMealTap,
    required this.onMealQuickAdd,
    this.onCreateMeal,
    this.onCopyPreviousMeal,
  });

  /// Row tap on All Foods or History — what "picking" a food means is
  /// entirely up to the caller (push a detail screen, add a draft row…).
  /// Second argument is the serving count to start from.
  final void Function(FoodItem food, double servings) onFoodTap;

  /// Plus button on All Foods or History — adds one serving directly.
  final void Function(FoodItem food, double servings) onFoodQuickAdd;

  /// Row tap on My Meals.
  final ValueChanged<SavedMeal> onMealTap;

  /// Plus button on My Meals.
  final ValueChanged<SavedMeal> onMealQuickAdd;

  /// My Meals action cards — null hides the respective card.
  final VoidCallback? onCreateMeal;
  final VoidCallback? onCopyPreviousMeal;

  @override
  State<FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<FoodPicker> {
  static const _debounceDelay = Duration(milliseconds: 150);

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _rawQuery = '';
  String _debouncedQuery = '';

  // The "open on All Foods for a first-time user" rule is an OPENING
  // default, not a standing constraint — applied once, then cleared the
  // moment the user manually picks any tab, so that pick actually sticks
  // (otherwise every rebuild would keep re-forcing All Foods for as long
  // as history stays empty, making History/My Meals untappable).
  bool _forceAllFoods = false;
  bool _defaultTabResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultTabResolved) {
      _defaultTabResolved = true;
      _forceAllFoods = AppScope.read(context).historyEntries.isEmpty;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final wasEmpty = _rawQuery.isEmpty;
    _rawQuery = value;
    // Tab switch is immediate — must feel instant, never waits on the
    // debounce below. Only fires on the empty→non-empty transition, so
    // continuing to type (or switching tabs manually afterward) never
    // fights the user.
    if (wasEmpty && value.isNotEmpty) {
      final state = AppScope.read(context);
      if (state.foodTabIndex != 0) state.setFoodTabIndex(0);
    }
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      setState(() => _debouncedQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    setState(() {
      _rawQuery = '';
      _debouncedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    // A first-time user opens on All Foods — otherwise the last tab they
    // explicitly picked, which AppState persists. _forceAllFoods is only
    // the OPENING default (set once in didChangeDependencies); once the
    // user taps any tab it's cleared, so their pick sticks even while
    // history stays empty (see _selectTab below).
    final selectedTab = _forceAllFoods ? 0 : state.foodTabIndex.clamp(0, 2);

    void selectTab(int i) {
      _forceAllFoods = false;
      state.setFoodTabIndex(i);
    }

    void clearFilters() {
      _clearSearch();
      state.setHistoryFilter(null);
      state.setMealsFilter(null);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
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
        _FoodPickerTabSelector(selected: selectedTab, onSelected: selectTab),
        Expanded(
          child: switch (selectedTab) {
            1 => HistoryTab(
              query: _debouncedQuery,
              onFoodTap: widget.onFoodTap,
              onQuickAdd: widget.onFoodQuickAdd,
              onBrowseAllFoods: () => selectTab(0),
              onClearFilters: clearFilters,
            ),
            2 => MyMealsTab(
              query: _debouncedQuery,
              onMealTap: widget.onMealTap,
              onMealQuickAdd: widget.onMealQuickAdd,
              onCreateMeal: widget.onCreateMeal,
              onCopyPreviousMeal: widget.onCopyPreviousMeal,
            ),
            _ => AllFoodsTab(
              query: _debouncedQuery,
              onFoodTap: widget.onFoodTap,
              onQuickAdd: widget.onFoodQuickAdd,
              onClearSearch: _clearSearch,
            ),
          },
        ),
      ],
    );
  }
}

/// Three equal-width segments — All Foods / History / My Meals. Selected
/// segment fills with the accent color; unselected stays flat on the
/// surrounding chip background, matching the rounded/soft-shadow card
/// language used throughout home_screen.dart. Row order is only ever
/// declared once, left to right; Directionality mirrors it in Arabic, never
/// a manual locale check here.
class _FoodPickerTabSelector extends StatelessWidget {
  const _FoodPickerTabSelector({
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppScope.of(context).l;
    final labels = [l.allFoodsTab, l.logHistoryTab, l.myMeals];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.chipBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _FoodPickerTabSegment(
                label: labels[i],
                selected: selected == i,
                onTap: () => onSelected(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodPickerTabSegment extends StatelessWidget {
  const _FoodPickerTabSegment({
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
      color: selected ? c.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? c.onAccent : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}
