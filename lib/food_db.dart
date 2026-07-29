import 'models.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// PLACEHOLDER DATABASE — the real product list was cleared to make room for
/// verified entries entered through the label-photo data pipeline (see
/// CLAUDE.md → DATA PIPELINE). These generic "Sample …" entries exist only
/// so the app has something to show/search/log while that pipeline fills
/// in; every kcal/macro number is a carried-over placeholder estimate, not
/// a real product's value. Replace/extend this list category by category.
/// ─────────────────────────────────────────────────────────────────────────
const List<FoodItem> foodDatabase = [
  // ── Snacks ──
  FoodItem(
    id: 'sample_snack_1',
    nameEn: 'Sample Snack A',
    nameAr: 'وجبة خفيفة تجريبية أ',
    servingEn: '1 pack (25 g)',
    servingAr: 'عبوة (25 جم)',
    kcal: 130,
    protein: 2,
    carbs: 15,
    fat: 7,
    category: FoodCategory.snack,
  ),
  FoodItem(
    id: 'sample_snack_2',
    nameEn: 'Sample Snack B',
    nameAr: 'وجبة خفيفة تجريبية ب',
    servingEn: '1 pack (25 g)',
    servingAr: 'عبوة (25 جم)',
    kcal: 128,
    protein: 1.8,
    carbs: 16,
    fat: 6.5,
    category: FoodCategory.snack,
  ),
  FoodItem(
    id: 'sample_snack_3',
    nameEn: 'Sample Snack C',
    nameAr: 'وجبة خفيفة تجريبية ج',
    servingEn: '1 pack (25 g)',
    servingAr: 'عبوة (25 جم)',
    kcal: 129,
    protein: 1.8,
    carbs: 15.5,
    fat: 6.8,
    category: FoodCategory.snack,
  ),
  FoodItem(
    id: 'sample_snack_4',
    nameEn: 'Sample Snack D',
    nameAr: 'وجبة خفيفة تجريبية د',
    servingEn: '1 pack (20 g)',
    servingAr: 'عبوة (20 جم)',
    kcal: 105,
    protein: 1.5,
    carbs: 12,
    fat: 5.5,
    category: FoodCategory.snack,
  ),

  // ── Mains ──
  FoodItem(
    id: 'sample_main_1',
    nameEn: 'Sample Main Dish A',
    nameAr: 'طبق رئيسي تجريبي أ',
    servingEn: '1 serving (350 g)',
    servingAr: 'حصة (350 جم)',
    kcal: 540,
    protein: 25,
    carbs: 75,
    fat: 15,
    category: FoodCategory.main,
    servingGrams: 350,
    presets: [
      PortionPreset('Modest share', 'حصة صغيرة', 250),
      PortionPreset('Normal share', 'حصة عادية', 350),
      PortionPreset('Generous share', 'حصة كبيرة', 500),
    ],
  ),
  FoodItem(
    id: 'sample_main_2',
    nameEn: 'Sample Main Dish B',
    nameAr: 'طبق رئيسي تجريبي ب',
    servingEn: '1 plate (350 g)',
    servingAr: 'صحن (350 جم)',
    kcal: 550,
    protein: 30,
    carbs: 65,
    fat: 17,
    category: FoodCategory.main,
    servingGrams: 350,
    presets: [
      PortionPreset('Small plate', 'صحن صغير', 250),
      PortionPreset('Plate', 'صحن عادي', 350),
      PortionPreset('Large plate', 'صحن كبير', 500),
    ],
  ),
  FoodItem(
    id: 'sample_main_3',
    nameEn: 'Sample Main Dish C',
    nameAr: 'طبق رئيسي تجريبي ج',
    servingEn: '1 plate (300 g)',
    servingAr: 'صحن (300 جم)',
    kcal: 480,
    protein: 18,
    carbs: 72,
    fat: 12,
    category: FoodCategory.main,
  ),

  // ── Breakfast ──
  FoodItem(
    id: 'sample_breakfast_1',
    nameEn: 'Sample Breakfast A',
    nameAr: 'فطور تجريبي أ',
    servingEn: '1 bowl (200 g)',
    servingAr: 'صحن (200 جم)',
    kcal: 260,
    protein: 14,
    carbs: 34,
    fat: 8,
    category: FoodCategory.breakfast,
    servingGrams: 200,
    presets: [
      PortionPreset('Small bowl', 'صحن صغير', 120),
      PortionPreset('Bowl', 'صحن', 200),
      PortionPreset('Large bowl', 'صحن كبير', 300),
    ],
  ),
  FoodItem(
    id: 'sample_breakfast_2',
    nameEn: 'Sample Breakfast B',
    nameAr: 'فطور تجريبي ب',
    servingEn: '2 pieces',
    servingAr: 'قطعتان',
    kcal: 140,
    protein: 12,
    carbs: 1,
    fat: 10,
    category: FoodCategory.breakfast,
  ),
  FoodItem(
    id: 'sample_breakfast_3',
    nameEn: 'Sample Breakfast C',
    nameAr: 'فطور تجريبي ج',
    servingEn: '1 piece (90 g)',
    servingAr: 'قطعة (90 جم)',
    kcal: 240,
    protein: 8,
    carbs: 48,
    fat: 2,
    category: FoodCategory.breakfast,
    servingGrams: 90,
    presets: [
      PortionPreset('Half serving', 'نصف حصة', 45),
      PortionPreset('Serving', 'حصة', 90),
      PortionPreset('Double serving', 'حصتان', 180),
    ],
  ),
  // Zero-fat, zero-protein on purpose — exercises the all-carb edge of the
  // macro-percentage math (kcalPercents).
  FoodItem(
    id: 'sample_breakfast_4',
    nameEn: 'Sample Breakfast D',
    nameAr: 'فطور تجريبي د',
    servingEn: '1 tbsp (21 g)',
    servingAr: 'ملعقة كبيرة (21 جم)',
    kcal: 64,
    protein: 0,
    carbs: 17,
    fat: 0,
    category: FoodCategory.breakfast,
  ),

  // ── Sweets ──
  FoodItem(
    id: 'sample_sweet_1',
    nameEn: 'Sample Sweet A',
    nameAr: 'حلوى تجريبية أ',
    servingEn: '1 piece (50 g)',
    servingAr: 'قطعة (50 جم)',
    kcal: 200,
    protein: 3,
    carbs: 30,
    fat: 8,
    category: FoodCategory.sweet,
  ),

  // ── Drinks ──
  FoodItem(
    id: 'sample_drink_1',
    nameEn: 'Sample Drink A',
    nameAr: 'مشروب تجريبي أ',
    servingEn: '1 cup (240 ml)',
    servingAr: 'كاس (240 مل)',
    kcal: 90,
    protein: 0,
    carbs: 22,
    fat: 0,
    category: FoodCategory.drink,
  ),
];

final Map<String, FoodItem> foodById = {for (final f in foodDatabase) f.id: f};
