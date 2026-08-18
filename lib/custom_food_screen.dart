import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'models.dart';
import 'settings_screen.dart' show WesternDigitsFormatter;
import 'theme.dart';

/// Add or edit a custom (user-created) food: a name plus per-serving
/// calories/protein/carbs/fat, nothing else — no gram weight, no unit
/// picker, no bilingual name (the single name the user types is used for
/// both nameEn/nameAr, matching the log flow's own display regardless of
/// locale). [existing] non-null puts the screen in edit mode (All Foods
/// tab long-press → Edit): fields prefill from it and Save updates it in
/// place instead of creating a new one.
class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key, this.existing});
  final FoodItem? existing;

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  String? _nameError;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.nameEn ?? '');
    _kcalController = TextEditingController(
      text: existing == null ? '' : '${existing.kcal}',
    );
    _proteinController = TextEditingController(
      text: existing == null ? '' : fmtGrams(existing.protein),
    );
    _carbsController = TextEditingController(
      text: existing == null ? '' : fmtGrams(existing.carbs),
    );
    _fatController = TextEditingController(
      text: existing == null ? '' : fmtGrams(existing.fat),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final l = state.l;
    final name = _nameController.text.trim();
    final kcal = int.tryParse(_kcalController.text);
    final protein = double.tryParse(_proteinController.text);
    final carbs = double.tryParse(_carbsController.text);
    final fat = double.tryParse(_fatController.text);

    final nameError = name.isEmpty ? l.foodNameRequired : null;
    final numbersValid =
        kcal != null &&
        kcal >= 0 &&
        protein != null &&
        protein >= 0 &&
        carbs != null &&
        carbs >= 0 &&
        fat != null &&
        fat >= 0;
    if (nameError != null || !numbersValid) {
      setState(() {
        _nameError = nameError;
        _numberError = numbersValid ? null : l.invalidNumber;
      });
      return;
    }

    final existing = widget.existing;
    final food = FoodItem(
      id: existing?.id ?? state.newCustomFoodId(),
      nameEn: name,
      nameAr: name,
      servingEn: '1 serving',
      servingAr: 'حصة واحدة',
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      category: FoodCategory.custom,
      sourceNote: 'User-added food, not verified.',
    );
    final ok = existing != null
        ? await state.updateCustomFood(food)
        : await state.addCustomFood(food);
    if (!mounted) return;
    if (!ok) {
      setState(() => _numberError = l.saveFailed);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.foodSaved)));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: c.pageBg,
      appBar: AppBar(
        backgroundColor: c.headerTop,
        foregroundColor: c.onHeader,
        title: Text(isEditing ? l.editFoodTitle : l.addFoodTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() => _nameError = null),
              style: TextStyle(color: c.ink),
              decoration: InputDecoration(
                labelText: l.foodNameLabel,
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
            Row(
              children: [
                Expanded(child: _numberField(c, l.calories, _kcalController)),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    c,
                    '${l.protein} (${l.grams})',
                    _proteinController,
                    allowDecimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    c,
                    '${l.carb} (${l.grams})',
                    _carbsController,
                    allowDecimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    c,
                    '${l.fat} (${l.grams})',
                    _fatController,
                    allowDecimal: true,
                  ),
                ),
              ],
            ),
            if (_numberError != null) ...[
              const SizedBox(height: 10),
              Text(
                _numberError!,
                style: TextStyle(fontSize: 13, color: c.fieldError),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _save,
              child: Text(
                l.save,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    AppColors c,
    String label,
    TextEditingController controller, {
    bool allowDecimal = false,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() => _numberError = null),
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        WesternDigitsFormatter(allowDecimal: allowDecimal),
        LengthLimitingTextInputFormatter(6),
      ],
      style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: c.muted),
        filled: true,
        fillColor: c.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Long-press options on a custom-food row (All Foods tab) — edit pushes
/// this same screen in edit mode, delete removes it with the same
/// delete-then-undo pattern as My Meals (local storage has no server
/// backup for a mis-tap). Never shown for food_db.dart entries, those
/// aren't user-editable.
void showCustomFoodOptionsSheet({
  required BuildContext context,
  required FoodItem food,
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
          ListTile(
            leading: Icon(Icons.edit_outlined, color: c.ink),
            title: Text(
              l.editAction,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomFoodScreen(existing: food),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: c.fieldError),
            title: Text(
              l.delete,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: c.fieldError,
              ),
            ),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              final ok = await state.deleteCustomFood(food.id);
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              if (!ok) {
                messenger.showSnackBar(SnackBar(content: Text(l.saveFailed)));
                return;
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l.removed),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: l.undo,
                    onPressed: () => state.addCustomFood(food),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
