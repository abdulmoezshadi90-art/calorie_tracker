import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

/// Filter + sort control row shared by the History and My Meals tabs. Both
/// buttons always show the ACTIVE selection as their label (e.g. "Most
/// recent"), never a generic "Sort"/"Filter" placeholder — per the spec.
class FilterSortRow extends StatelessWidget {
  const FilterSortRow({
    super.key,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final MealType? filter;
  final SortOption sort;
  final ValueChanged<MealType?> onFilterChanged;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final filterLabel = filter == null ? l.filterAllMeals : l.mealName(filter!);

    return Row(
      children: [
        Expanded(
          child: _ControlChip(
            icon: Icons.filter_list,
            label: filterLabel,
            onTap: () => showMealFilterSheet(
              context: context,
              selected: filter,
              onSelected: onFilterChanged,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlChip(
            icon: Icons.swap_vert,
            label: l.sortOptionName(sort),
            onTap: () => showSortSheet(
              context: context,
              selected: sort,
              onSelected: onSortChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.chipBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c.chipText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.chipText,
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

/// Single-select meal-type filter sheet — null represents "All meals".
/// Mirrors home_screen.dart's showMealChooser in structure and style.
void showMealFilterSheet({
  required BuildContext context,
  required MealType? selected,
  required ValueChanged<MealType?> onSelected,
}) {
  final c = AppColors.of(context);
  final state = AppScope.of(context);
  final l = state.l;
  final options = <MealType?>[null, ...MealType.values];
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.filterSheetTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
          ),
          for (final option in options)
            ListTile(
              title: Text(
                option == null ? l.filterAllMeals : l.mealName(option),
                style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
              ),
              trailing: option == selected
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(option);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Single-select sort-option sheet, shared by both tabs.
void showSortSheet({
  required BuildContext context,
  required SortOption selected,
  required ValueChanged<SortOption> onSelected,
}) {
  final c = AppColors.of(context);
  final state = AppScope.of(context);
  final l = state.l;
  showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.sortSheetTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
          ),
          for (final option in SortOption.values)
            ListTile(
              title: Text(
                l.sortOptionName(option),
                style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
              ),
              trailing: option == selected
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(option);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
