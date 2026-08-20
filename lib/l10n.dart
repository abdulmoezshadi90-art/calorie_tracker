import 'models.dart';
import 'profile.dart';

/// Hand-rolled localization: two locales, Western digits everywhere.
/// All numbers are formatted by the fmt* helpers (never locale-aware
/// formatters), so Arabic text keeps 0-9 digits by construction.
class L10n {
  final bool isAr;
  const L10n(String code) : isAr = code == 'ar';

  String get appTitle => isAr ? 'زبدة' : 'Zibda';
  String get today => isAr ? 'اليوم' : 'Today';

  /// Time-of-day greeting, e.g. "Good morning," / "صباح الخير،".
  String greeting(int hour) {
    if (hour < 12) return isAr ? 'صباح الخير،' : 'Good morning,';
    if (hour < 18) return isAr ? 'مساء الخير،' : 'Good afternoon,';
    return isAr ? 'مساء الخير،' : 'Good evening,';
  }

  String get caloriesToday => isAr ? 'سعرات اليوم' : "Today's calories";
  String get kcal => isAr ? 'سعرة' : 'kcal';
  String ofGoalKcal(num goal) =>
      isAr ? 'من ${fmtInt(goal)} سعرة' : 'of ${fmtInt(goal)} kcal';
  String kcalLeftToday(num n) =>
      isAr ? 'تبقّى ${fmtInt(n)} سعرة اليوم' : '${fmtInt(n)} kcal left today';
  String kcalOverToday(num n) =>
      isAr ? 'زيادة ${fmtInt(n)} سعرة اليوم' : '${fmtInt(n)} kcal over today';

  String get carb => isAr ? 'كربوهيدرات' : 'Carbs';
  String get fat => isAr ? 'دهون' : 'Fat';
  String get protein => isAr ? 'بروتين' : 'Protein';
  String get grams => isAr ? 'جم' : 'g';

  String get meals => isAr ? 'الوجبات' : 'Meals';
  String mealCountOf(int done, int total) => isAr
      ? '${fmtInt(done)} من ${fmtInt(total)}'
      : '${fmtInt(done)} of ${fmtInt(total)}';
  String kcalAmount(num n, {bool approx = false}) =>
      '${approx ? '~' : ''}${fmtInt(n)} ${isAr ? 'سعرة' : 'kcal'}';
  String get notLoggedYet => isAr ? 'لم تُسجل بعد' : 'Not logged yet';
  String get addMeal => isAr ? 'أضف وجبة' : 'Add meal';
  String get chooseMeal => isAr ? 'اختر وجبة' : 'Choose a meal';

  String get searchHint => isAr ? 'ابحث عن طعام…' : 'Search foods…';
  String get noResults => isAr ? 'لا توجد نتائج' : 'No foods found';
  String get servings => isAr ? 'عدد الحصص' : 'Servings';
  String get add => isAr ? 'إضافة' : 'Add';
  String get added => isAr ? 'تمت الإضافة' : 'Added';
  String get delete => isAr ? 'حذف' : 'Delete';
  // Undo pattern: local-only storage has no server backup for a mis-tap.
  String get removed => isAr ? 'تم الحذف' : 'Removed';
  String get undo => isAr ? 'تراجع' : 'Undo';
  String get total => isAr ? 'المجموع' : 'Total';
  String get perServing => isAr ? 'لكل حصة' : 'per serving';
  String get toggleLabel => isAr ? 'EN' : 'ع';

  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get dailyGoals => isAr ? 'الأهداف اليومية' : 'Daily goals';
  String get calories => isAr ? 'سعرات حرارية' : 'Calories';
  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get language => isAr ? 'اللغة' : 'Language';
  String get languageName => isAr ? 'العربية' : 'English';
  String get appearance => isAr ? 'المظهر' : 'Appearance';
  String get themeSystem => isAr ? 'النظام' : 'System';
  String get themeLight => isAr ? 'فاتح' : 'Light';
  String get themeDark => isAr ? 'داكن' : 'Dark';
  String get about => isAr ? 'حول التطبيق' : 'About';
  String get version => isAr ? 'الإصدار' : 'Version';
  String get disclaimerTitle => isAr ? 'إخلاء مسؤولية' : 'Disclaimer';
  String get disclaimerBody => isAr
      ? 'القيم الغذائية في هذا التطبيق تقريبية. قيم المنتجات المعبأة مأخوذة من ملصقات المنتجات، وقيم الأطباق المنزلية تقديرية بناءً على وصفات شائعة. هذا التطبيق لا يقدم استشارة طبية. إذا كنت تعاني من حالة صحية مثل السكري، استشر طبيبك أو أخصائي التغذية.'
      : 'Nutrition values in this app are approximate. Packaged food values come from product labels. Home dish values are estimates based on typical recipes. This app does not provide medical advice. If you manage a medical condition such as diabetes, consult your doctor or dietitian.';
  String get invalidNumber =>
      isAr ? 'أدخل رقمًا صحيحًا' : 'Enter a valid number';
  String get valueTooLow => isAr
      ? 'هذه القيمة أقل من المعتاد. هل تريد المتابعة؟'
      : 'This value is lower than typical. Continue anyway?';
  String get goalsSaved => isAr ? 'تم حفظ الأهداف' : 'Goals saved';
  // Storage write failure — the only real error a local-only app has.
  String get saveFailed =>
      isAr ? 'تعذّر الحفظ — حاول مرة أخرى' : "Couldn't save — try again";

  // Weight logging + progress (neutral wording, no judgement by design).
  String get progress => isAr ? 'التقدّم' : 'Progress';
  String get logWeight => isAr ? 'سجّل وزنك' : 'Log weight';
  String get weightTrend => isAr ? 'الوزن' : 'Weight';
  String get weightSaved => isAr ? 'تم حفظ الوزن' : 'Weight saved';
  String get weightOverwrite => isAr
      ? 'سجّلت وزنك اليوم بالفعل. هل تريد استبداله؟'
      : "You already logged today's weight. Replace it?";
  String get weightEmptyLine =>
      isAr ? 'لا يوجد وزن مسجّل بعد' : 'No weight logged yet';
  String get weightEmptyHint => isAr
      ? 'سجّل وزنك لتتبّع تقدّمك هنا'
      : 'Log your weight to track your progress here';
  String get weightTrendHint => isAr
      ? 'سجّل وزنك بانتظام لرؤية اتجاهك'
      : 'Log weight regularly to see your trend';
  String get kg => isAr ? 'كجم' : 'kg';

  String get foods => isAr ? 'الأطعمة' : 'Foods';
  String get approxMarker => isAr ? 'تقريبي' : 'approx.';
  String get approxMarkerExplanation => isAr
      ? 'لم يتم التحقق من هذه القيمة من ملصق منتج بعد — اعتبرها تقديرية'
      : 'This value hasn\'t been checked against a product label yet — treat it as an estimate';

  // Food detail page.
  String get unit => isAr ? 'الوحدة' : 'Unit';
  String get quantity => isAr ? 'الكمية' : 'Quantity';
  String get fractionMode => isAr ? 'كسور' : 'Fraction';
  String get decimalMode => isAr ? 'عشري' : 'Decimal';
  String get whole => isAr ? 'عدد كامل' : 'Whole';
  String get invalidQuantity =>
      isAr ? 'أدخل كمية بين 0.1 و 99' : 'Enter a quantity between 0.1 and 99';
  String get time => isAr ? 'الوقت' : 'Time';
  String get verifiedBadgeExplanation => isAr
      ? 'تم التحقق من هذه القيمة من ملصق منتج فعلي'
      : 'Verified against a real product label';

  /// A [ServingUnit]'s display label — generic weight/volume units (never
  /// per-food data) are recognized by id and localized here; food-specific
  /// units use the label strings food_db.dart already stored on them.
  String unitLabel(ServingUnit u) {
    final generic = GenericUnitKind.fromUnitId(u.id);
    if (generic != null) return genericUnitLabel(generic);
    return isAr ? u.labelAr : u.labelEn;
  }

  String genericUnitLabel(GenericUnitKind k) => switch (k) {
    GenericUnitKind.gram => isAr ? 'غرام' : 'g',
    GenericUnitKind.hundredGrams => isAr ? '100 غرام' : '100 g',
    GenericUnitKind.kilogram => isAr ? 'كيلوغرام' : 'kg',
    GenericUnitKind.ounce => isAr ? 'أونصة' : 'oz',
    GenericUnitKind.pound => isAr ? 'رطل' : 'lb',
    GenericUnitKind.milliliter => isAr ? 'مل' : 'ml',
    GenericUnitKind.hundredMilliliters => isAr ? '100 مل' : '100 ml',
    GenericUnitKind.liter => isAr ? 'لتر' : 'l',
    GenericUnitKind.fluidOunce => isAr ? 'أونصة سائلة' : 'fl oz',
    GenericUnitKind.cup => isAr ? 'كوب' : 'cup',
    GenericUnitKind.tablespoon => isAr ? 'ملعقة كبيرة' : 'tbsp',
    GenericUnitKind.teaspoon => isAr ? 'ملعقة صغيرة' : 'tsp',
  };

  // Serving-unit picker sheet (Change 2: bottom sheet replacing inline chips).
  String get chooseUnit => isAr ? 'اختر الوحدة' : 'Choose a unit';
  String get namedServingsSection =>
      isAr ? 'حصص هذا الطعام' : "This food's servings";
  String get weightUnitsSection => isAr ? 'وحدات الوزن' : 'Weight units';
  String get volumeUnitsSection => isAr ? 'وحدات الحجم' : 'Volume units';

  String get history => isAr ? 'السجل' : 'History';
  String get historyEmpty =>
      isAr ? 'لا توجد أيام مسجلة بعد' : 'No logged days yet';
  // Neutral goal wording by design: no alarm colors, no judgement.
  String get withinGoal => isAr ? 'ضمن الهدف' : 'Within goal';
  String get overGoal => isAr ? 'فوق الهدف' : 'Over goal';
  String get last7Days => isAr ? 'آخر 7 أيام' : 'Last 7 days';

  /// Accessibility label for the streak chip. Neutral wording only.
  String streakDays(int n) => isAr
      ? '${fmtInt(n)} أيام تسجيل متتالية'
      : '${fmtInt(n)} consecutive days logged';

  String get chooseLanguage => isAr ? 'اختر اللغة' : 'Choose your language';
  String get next => isAr ? 'التالي' : 'Next';
  String get skip => isAr ? 'تخطي' : 'Skip';
  String get getStarted => isAr ? 'ابدأ الآن' : 'Get started';
  String get introTitle => isAr ? 'سجّل ما تأكل' : 'Log what you eat';
  // No em dashes (house style), and no naming specific foods that aren't
  // actually searchable yet: Kalee was never a real Libyan brand (removed
  // from food_db.dart), and named home dishes like bazin aren't in the
  // database yet either, only their raw ingredients are. Local packaged
  // brands are the real, honest hook today.
  String get introBody => isAr
      ? 'ابحث عن العلامات الليبية والأطعمة اليومية، بالعربية أو الإنجليزية، وأضفها لوجباتك بضغطة واحدة. يعمل بدون إنترنت، وبياناتك تبقى في هاتفك فقط.'
      : 'Search Libyan brands and everyday foods, in Arabic or English, and add them to your meals with a tap. Works offline, your data never leaves your phone.';
  String get onboardGoalsTitle =>
      isAr ? 'حدد أهدافك اليومية' : 'Set your daily goals';
  String get onboardGoalsBody => isAr
      ? 'يمكنك البدء بالأهداف الافتراضية وتغييرها في أي وقت من الإعدادات.'
      : 'You can start with the defaults and change them anytime in settings.';
  String get replayOnboarding => isAr ? 'إعادة عرض المقدمة' : 'Replay intro';
  String get sendFeedback => isAr ? 'أرسل ملاحظاتك' : 'Send feedback';
  String get feedbackCopied =>
      isAr ? 'تم نسخ عنوان البريد الإلكتروني' : 'Email address copied';

  // Empty states: short friendly line + one clear action each.
  String get emptyTodayLine =>
      isAr ? 'لم تسجّل شيئًا اليوم بعد' : 'Nothing logged today yet';
  String get emptyTodayAction => isAr ? 'سجّل أول وجبة' : 'Log your first meal';
  String get searchEmptyHint => isAr
      ? 'جرّب اسمًا آخر، بالعربية أو الإنجليزية'
      : 'Try another name, in Arabic or English';
  String get clearSearch => isAr ? 'مسح البحث' : 'Clear search';
  String get historyEmptyHint => isAr
      ? 'الأيام التي تسجّل فيها وجباتك ستظهر هنا'
      : 'Days you log meals will show up here';
  String get backToToday => isAr ? 'العودة إلى اليوم' : 'Back to today';
  String get addFood => isAr ? 'أضف طعامًا' : 'Add a food';

  // Profile step (decision 8). Deliberately never "login"/"sign up"/"account"
  // wording — it is a local profile, nothing leaves the phone.
  String get profileTitle => isAr ? 'ملفك الشخصي' : 'Your profile';
  String get profileIntro => isAr
      ? 'نحسب لك هدفًا يوميًا يناسب جسمك. كل الإجابات تبقى على هاتفك.'
      : 'We calculate a daily goal that fits your body. All answers stay on your phone.';
  // Inline field labels (inside the TextField itself) — deliberately
  // shorter than the step heading above them (nameQuestion/ageQuestion/
  // weightQuestion/heightQuestion) now that those headings are plain nouns
  // too: a unit-only or bare hint reads as a field cue, not a duplicate of
  // the heading it sits under.
  String get nameOptional => isAr ? 'الاسم' : 'Name';
  String get ageLabel => isAr ? 'سنة' : 'Years';
  String get weightLabel => isAr ? 'كجم' : 'kg';
  String get heightLabel => isAr ? 'سم' : 'cm';
  String get calculateGoal => isAr ? 'احسب هدفي' : 'Calculate my goal';
  String get suggestedGoal =>
      isAr ? 'هدفك اليومي المقترح' : 'Your suggested daily goal';
  String maintenanceLine(num n) => isAr
      ? 'سعرات المحافظة: ~${fmtInt(n)} سعرة'
      : 'Maintenance: ~${fmtInt(n)} kcal';
  String get estimateNote => isAr
      ? 'هذا تقدير — الاحتياج الحقيقي يختلف بحوالي 10%'
      : 'This is an estimate — real needs vary by ~10%';
  String get under18Note => isAr
      ? 'لأن عمرك أقل من 18، نقترح سعرات المحافظة فقط دون عجز.'
      : 'Because you are under 18, we suggest maintenance calories only, with no deficit.';
  String get useThisGoal => isAr ? 'اعتماد الهدف' : 'Use this goal';
  String get adjust => isAr ? 'تعديل' : 'Adjust';
  String get completeFields =>
      isAr ? 'أكمل الحقول أعلاه' : 'Complete the fields above';
  // Used by the standalone weight-log entry field (weight_log.dart) — the
  // profile wizard's own age/weight/height steps no longer show this.
  String rangeHint(int min, int max) => isAr
      ? 'بين ${fmtInt(min)} و ${fmtInt(max)}'
      : '${fmtInt(min)}–${fmtInt(max)}';
  String get recalculateGoal =>
      isAr ? 'إعادة حساب الهدف' : 'Recalculate my goal';
  // Empty/unset profile prompt — shown when the wizard was skipped, so
  // the profile area invites setup instead of looking blank.
  String get setUpProfile => isAr ? 'أنشئ ملفك الشخصي' : 'Set up your profile';
  String get setUpProfileHint =>
      isAr ? 'للحصول على هدف يومي مخصص لك' : 'for a personalized daily goal';

  // Wizard step headings — one clear heading per screen. Plain noun labels
  // (no leading question word, no trailing "?", no colon), not questions —
  // getter names below still say "Question" for now (renaming risks a
  // collision with the already-distinct weightLabel/heightLabel getters
  // used for the input fields themselves; left as a known naming staleness
  // rather than a functional issue).
  String get nameQuestion => isAr ? 'الاسم (اختياري)' : 'Name (optional)';
  String get sexQuestion => isAr ? 'الجنس' : 'Sex';
  String get ageQuestion => isAr ? 'العمر' : 'Age';
  String get weightQuestion => isAr ? 'الوزن (كجم)' : 'Weight (kg)';
  String get heightQuestion => isAr ? 'الطول (سم)' : 'Height (cm)';
  String get activityQuestion => isAr ? 'مستوى النشاط' : 'Training intensity';
  String get goalQuestion => isAr ? 'الهدف' : 'Goal';
  String goalRateQuestion(GoalDirection d) => switch (d) {
    GoalDirection.lose => isAr ? 'معدّل إنقاص الوزن' : 'Weight loss rate',
    GoalDirection.gain => isAr ? 'معدّل زيادة الوزن' : 'Weight gain rate',
    GoalDirection.maintain => '', // unreachable — maintain skips this step
  };
  // Note shown under the daily target when the floor guard clamps it —
  // plain sentence, no alarm wording (design decision 2).
  String get goalFloorNote => isAr
      ? 'تم رفع هدفك إلى الحد الأدنى الآمن.'
      : 'Your target was raised to a safe minimum.';
  String get continueLabel => isAr ? 'متابعة' : 'Continue';
  // "Exercise" was defined here, but "intense" (used in the High and
  // Athlete activity descriptions below) never was — added a second
  // sentence using the standard talk-test definition.
  String get exerciseHelper => isAr
      ? 'التمرين يعني نشاطًا يرفع نبض القلب لمدة 15 إلى 30 دقيقة أو أكثر. أما الشاق فيعني صعوبة الحديث أثناء الأداء.'
      : 'Exercise means 15 to 30+ minutes of elevated heart rate activity. Intense means hard enough that talking through it is difficult.';

  String activityDesc(ActivityLevel a) => switch (a) {
    ActivityLevel.sedentary =>
      isAr
          ? 'حياة مكتبية، تمرين قليل أو معدوم'
          : 'Desk life, little or no exercise',
    ActivityLevel.light =>
      isAr ? 'تمرين 1 إلى 3 مرات في الأسبوع' : 'Exercise 1 to 3 times a week',
    ActivityLevel.moderate =>
      isAr ? 'تمرين 4 إلى 5 مرات في الأسبوع' : 'Exercise 4 to 5 times a week',
    ActivityLevel.high =>
      isAr
          ? 'تمرين يومي، أو تمرين شاق 3 إلى 6 مرات في الأسبوع'
          : 'Daily exercise, or intense exercise 3 to 6 times a week',
    ActivityLevel.athlete =>
      isAr
          ? 'تدريب يومي شاق جدًا أو عمل بدني'
          : 'Very intense daily training or a physical job',
  };

  // Direction step: verb-first phrasing (Lose/Maintain/Gain weight).
  String goalDirectionName(GoalDirection d) => switch (d) {
    GoalDirection.lose => isAr ? 'إنقاص الوزن' : 'Lose weight',
    GoalDirection.maintain => isAr ? 'تثبيت الوزن' : 'Maintain weight',
    GoalDirection.gain => isAr ? 'زيادة الوزن' : 'Gain weight',
  };

  /// Rate-step card title, mirrored per direction: "Mild/—/Extreme weight
  /// loss" vs "Mild/—/Fast weight gain".
  String goalRateName(GoalDirection d, GoalRate r) => switch ((d, r)) {
    (GoalDirection.lose, GoalRate.mild) =>
      isAr ? 'إنقاص خفيف' : 'Mild weight loss',
    (GoalDirection.lose, GoalRate.normal) =>
      isAr ? 'إنقاص الوزن' : 'Weight loss',
    (GoalDirection.lose, GoalRate.extreme) =>
      isAr ? 'إنقاص شديد للوزن' : 'Extreme weight loss',
    (GoalDirection.gain, GoalRate.mild) =>
      isAr ? 'زيادة خفيفة للوزن' : 'Mild weight gain',
    (GoalDirection.gain, GoalRate.normal) =>
      isAr ? 'زيادة الوزن' : 'Weight gain',
    (GoalDirection.gain, GoalRate.extreme) =>
      isAr ? 'زيادة سريعة للوزن' : 'Fast weight gain',
    (GoalDirection.maintain, _) => '', // unreachable — no rate step to maintain
  };

  /// "0.25 kg per week" — the exact chosen rate, not an approximation, so
  /// no "~" (unlike the old flat-adjustment phrasing it replaces).
  String goalRateKgLine(GoalRate r) => isAr
      ? '${fmtServings(r.kgPerWeek)} كجم أسبوعيًا'
      : '${fmtServings(r.kgPerWeek)} kg per week';

  String sexName(Sex s) => switch (s) {
    Sex.male => isAr ? 'ذكر' : 'Male',
    Sex.female => isAr ? 'أنثى' : 'Female',
  };

  String activityName(ActivityLevel a) => switch (a) {
    ActivityLevel.sedentary => isAr ? 'خامل' : 'Sedentary',
    ActivityLevel.light => isAr ? 'خفيف' : 'Light',
    ActivityLevel.moderate => isAr ? 'متوسط' : 'Moderate',
    ActivityLevel.high => isAr ? 'عالي' : 'High',
    ActivityLevel.athlete => isAr ? 'رياضي' : 'Athlete',
  };

  String mealName(MealType meal) => switch (meal) {
    MealType.breakfast => isAr ? 'الفطور' : 'Breakfast',
    MealType.lunch => isAr ? 'الغداء' : 'Lunch',
    MealType.dinner => isAr ? 'العشاء' : 'Dinner',
    MealType.snack => isAr ? 'وجبة خفيفة' : 'Snack',
  };

  String category(FoodCategory c) => switch (c) {
    FoodCategory.snack => isAr ? 'وجبات خفيفة' : 'Snacks',
    FoodCategory.main => isAr ? 'أطباق رئيسية' : 'Mains',
    FoodCategory.breakfast => isAr ? 'فطور' : 'Breakfast',
    FoodCategory.sweet => isAr ? 'حلويات' : 'Sweets',
    FoodCategory.drink => isAr ? 'مشروبات' : 'Drinks',
    FoodCategory.custom => isAr ? 'أطعمتي' : 'My Foods',
  };

  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  // Full weekday names, indexed by DateTime.weekday % 7 (Sunday = 0).
  static const _fullEn = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  static const _fullAr = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  /// Header subtitle, e.g. "Thursday, July 16" / "الخميس، 16 يوليو".
  String dateLine(DateTime d) {
    final wd = (isAr ? _fullAr : _fullEn)[d.weekday % 7];
    final month = (isAr ? _monthsAr : _monthsEn)[d.month - 1];
    return isAr ? '$wd، ${d.day} $month' : '$wd, $month ${d.day}';
  }

  /// Calendar sheet header, e.g. "August 2026" / "أغسطس 2026". Year is
  /// plain int interpolation, same as every other on-screen number here —
  /// never intl-based formatting, which could slip in Eastern Arabic
  /// numerals (hard requirement 1).
  String monthYear(DateTime d) =>
      '${(isAr ? _monthsAr : _monthsEn)[d.month - 1]} ${d.year}';

  // Short weekday labels for the week strip, indexed by DateTime.weekday % 7.
  static const _daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _daysAr = [
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  String dayShort(DateTime d) => (isAr ? _daysAr : _daysEn)[d.weekday % 7];

  // Food selection tabs (search_screen.dart): History = every food ever
  // logged, aggregated; My Meals = user-saved food combos. Distinct from
  // the unrelated `history`/`historyEmpty` strings above, which belong to
  // the day-by-day totals history in progress_screen.dart.
  String get logHistoryTab => isAr ? 'السجل' : 'History';
  String get myMeals => isAr ? 'وجباتي' : 'My Meals';
  String get recentlyLogged => isAr ? 'سُجّل مؤخرًا' : 'Recently logged';
  String get createMealAction => isAr ? 'أنشئ وجبة' : 'Create a meal';
  String get copyPreviousMealAction =>
      isAr ? 'نسخ وجبة سابقة' : 'Copy previous meal';

  // Filter/sort controls, shared by both tabs — the button label always
  // shows the active selection (e.g. "Most recent"), never a generic
  // "Sort"/"Filter" placeholder; these two are only the bottom-sheet titles.
  String get filterSheetTitle => isAr ? 'تصفية' : 'Filter';
  String get sortSheetTitle => isAr ? 'ترتيب' : 'Sort';
  String get filterAllMeals => isAr ? 'كل الوجبات' : 'All meals';
  String sortOptionName(SortOption s) => switch (s) {
    SortOption.mostRecent => isAr ? 'الأحدث' : 'Most recent',
    SortOption.mostFrequent => isAr ? 'الأكثر تكرارًا' : 'Most frequent',
    SortOption.aToZ => isAr ? 'أ إلى ي' : 'A to Z',
    SortOption.zToA => isAr ? 'ي إلى أ' : 'Z to A',
  };

  // Empty states for the two tabs (distinct from the generic search empty
  // state above, per the feature spec: "no logs anywhere" reads differently
  // from "logs exist, none match the filter").
  String get historyTabEmptyLine => isAr
      ? 'ستظهر هنا الأطعمة التي تسجّلها'
      : 'Your logged foods will appear here';
  String get noFilterMatchLine => isAr
      ? 'لا يوجد ما يطابق الفلتر الحالي'
      : 'Nothing matches the current filter';
  String get clearFilterAction => isAr ? 'مسح الفلتر' : 'Clear filter';
  String get myMealsEmptyLine => isAr
      ? 'أنشئ وجبتك الأولى لتظهر هنا'
      : 'Create your first meal to see it here';

  // All Foods tab (food_picker.dart) — the always-present A-to-Z browse tab
  // that fixes the first-time-user dead end (History/My Meals start empty).
  String get allFoodsTab => isAr ? 'كل الأطعمة' : 'All Foods';
  String get previouslyLoggedHeader => isAr ? 'سُجّل سابقًا' : 'Previously logged';
  String get allFoodsSectionHeader => isAr ? 'كل الأطعمة' : 'All foods';
  String get browseAllFoods => isAr ? 'تصفح كل الأطعمة' : 'Browse all foods';

  String foodsCount(int n) =>
      isAr ? '${fmtInt(n)} أطعمة' : '${fmtInt(n)} foods';
  String get addAllAction => isAr ? 'أضف الكل' : 'Add all';
  String get editAction => isAr ? 'تعديل' : 'Edit';

  // Create-a-meal screen.
  String get createMealTitle => isAr ? 'إنشاء وجبة' : 'Create a meal';
  String get mealNameLabel => isAr ? 'اسم الوجبة' : 'Meal name';
  String get mealNameRequired => isAr ? 'أدخل اسم الوجبة' : 'Enter a meal name';
  String get mealTypeOptional =>
      isAr ? 'نوع الوجبة (اختياري)' : 'Meal type (optional)';
  String get noneOption => isAr ? 'بدون' : 'None';
  String get noFoodsAddedYet =>
      isAr ? 'لم تُضف أطعمة بعد' : 'No foods added yet';
  String get mealSaved => isAr ? 'تم حفظ الوجبة' : 'Meal saved';

  // Copy-previous-meal sheet.
  String get copyMealSheetTitle =>
      isAr ? 'نسخ وجبة سابقة' : 'Copy a previous meal';
  String get noPreviousMeals =>
      isAr ? 'لا توجد وجبات في آخر 14 يومًا' : 'No meals in the last 14 days';
  String get mealCopied => isAr ? 'تم نسخ الوجبة' : 'Meal copied';

  // Custom food (add-a-product) screen and its All Foods tab entry point.
  String get addFoodAction => isAr ? 'أضف طعامًا' : 'Add a food';
  String get addFoodTitle => isAr ? 'إضافة طعام' : 'Add a food';
  String get editFoodTitle => isAr ? 'تعديل الطعام' : 'Edit food';
  String get foodNameLabel => isAr ? 'اسم الطعام' : 'Food name';
  String get foodNameRequired => isAr ? 'أدخل اسم الطعام' : 'Enter a food name';
  String get foodSaved => isAr ? 'تم حفظ الطعام' : 'Food saved';

  String foodName(FoodItem f) => isAr ? f.nameAr : f.nameEn;
  String servingLabel(FoodItem f) => isAr ? f.servingAr : f.servingEn;

  /// Comma-joined food names for a meal's subtitle line.
  String joinFoods(Iterable<FoodItem> foods) =>
      foods.map(foodName).join(isAr ? '، ' : ', ');
}
