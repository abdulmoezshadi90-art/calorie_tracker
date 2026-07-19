import 'models.dart';
import 'profile.dart';

/// Hand-rolled localization: two locales, Western digits everywhere.
/// All numbers are formatted by the fmt* helpers (never locale-aware
/// formatters), so Arabic text keeps 0-9 digits by construction.
class L10n {
  final bool isAr;
  const L10n(String code) : isAr = code == 'ar';

  String get appTitle => isAr ? 'متتبع السعرات' : 'Calorie Tracker';
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
  String get about => isAr ? 'حول التطبيق' : 'About';
  String get version => isAr ? 'الإصدار' : 'Version';
  String get disclaimerTitle => isAr ? 'إخلاء مسؤولية' : 'Disclaimer';
  String get disclaimerBody => isAr
      ? 'القيم الغذائية في هذا التطبيق تقريبية. قيم المنتجات المعبأة مأخوذة من ملصقات المنتجات، وقيم الأطباق المنزلية تقديرية بناءً على وصفات شائعة. هذا التطبيق لا يقدم استشارة طبية. إذا كنت تعاني من حالة صحية مثل السكري، استشر طبيبك أو أخصائي التغذية.'
      : 'Nutrition values in this app are approximate. Packaged food values come from product labels. Home dish values are estimates based on typical recipes. This app does not provide medical advice. If you manage a medical condition such as diabetes, consult your doctor or dietitian.';
  String get invalidNumber => isAr ? 'أدخل رقمًا صحيحًا' : 'Enter a valid number';
  String get valueTooLow => isAr
      ? 'هذه القيمة أقل من المعتاد. هل تريد المتابعة؟'
      : 'This value is lower than typical. Continue anyway?';
  String get goalsSaved => isAr ? 'تم حفظ الأهداف' : 'Goals saved';

  String get history => isAr ? 'السجل' : 'History';
  String get historyEmpty => isAr ? 'لا توجد أيام مسجلة بعد' : 'No logged days yet';
  // Neutral goal wording by design: no alarm colors, no judgement.
  String get withinGoal => isAr ? 'ضمن الهدف' : 'Within goal';
  String get overGoal => isAr ? 'فوق الهدف' : 'Over goal';
  String get last7Days => isAr ? 'آخر 7 أيام' : 'Last 7 days';

  String get chooseLanguage => isAr ? 'اختر اللغة' : 'Choose your language';
  String get next => isAr ? 'التالي' : 'Next';
  String get skip => isAr ? 'تخطي' : 'Skip';
  String get getStarted => isAr ? 'ابدأ الآن' : 'Get started';
  String get introTitle => isAr ? 'سجّل ما تأكل' : 'Log what you eat';
  String get introBody => isAr
      ? 'ابحث عن الأطعمة الليبية — من شيبسي كالي إلى البازين — وأضفها إلى وجباتك بضغطة. يعمل التطبيق بدون إنترنت وبياناتك تبقى على هاتفك.'
      : 'Search Libyan foods — from Kalee chips to bazin — and add them to your meals with a tap. Works offline, and your data stays on your phone.';
  String get onboardGoalsTitle => isAr ? 'حدد أهدافك اليومية' : 'Set your daily goals';
  String get onboardGoalsBody => isAr
      ? 'يمكنك البدء بالأهداف الافتراضية وتغييرها في أي وقت من الإعدادات.'
      : 'You can start with the defaults and change them anytime in settings.';
  String get replayOnboarding => isAr ? 'إعادة عرض المقدمة' : 'Replay intro';
  String get sendFeedback => isAr ? 'أرسل ملاحظاتك' : 'Send feedback';
  String get feedbackCopied => isAr
      ? 'تم نسخ عنوان البريد الإلكتروني'
      : 'Email address copied';

  // Empty states: short friendly line + one clear action each.
  String get emptyTodayLine =>
      isAr ? 'لم تسجّل شيئًا اليوم بعد' : 'Nothing logged today yet';
  String get emptyTodayAction =>
      isAr ? 'سجّل أول وجبة' : 'Log your first meal';
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
  String get nameOptional => isAr ? 'الاسم (اختياري)' : 'Name (optional)';
  String get sexLabel => isAr ? 'الجنس' : 'Sex';
  String get ageLabel => isAr ? 'العمر' : 'Age';
  String get weightLabel => isAr ? 'الوزن (كجم)' : 'Weight (kg)';
  String get heightLabel => isAr ? 'الطول (سم)' : 'Height (cm)';
  String get activityLabel => isAr ? 'مستوى النشاط' : 'Training intensity';
  String get goalLabel => isAr ? 'هدف الوزن' : 'Weight goal';
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
  String rangeHint(int min, int max) =>
      isAr ? 'بين ${fmtInt(min)} و ${fmtInt(max)}' : '${fmtInt(min)}–${fmtInt(max)}';
  String get recalculateGoal =>
      isAr ? 'إعادة حساب الهدف' : 'Recalculate my goal';

  // Wizard step questions — one clear heading per screen.
  String get nameQuestion =>
      isAr ? 'ما اسمك؟ (اختياري)' : "What's your name? (optional)";
  String get sexQuestion => isAr ? 'ما هو جنسك؟' : 'What is your sex?';
  String get ageQuestion => isAr ? 'كم عمرك؟' : 'How old are you?';
  String get weightQuestion =>
      isAr ? 'كم وزنك؟ (كجم)' : 'What is your weight? (kg)';
  String get heightQuestion =>
      isAr ? 'كم طولك؟ (سم)' : 'How tall are you? (cm)';
  String get activityQuestion =>
      isAr ? 'ما مستوى نشاطك؟' : 'What is your training intensity?';
  String get goalQuestion => isAr ? 'ما هدفك؟' : 'What is your goal?';
  String get continueLabel => isAr ? 'متابعة' : 'Continue';
  String get exerciseHelper => isAr
      ? 'التمرين يعني نشاطًا يرفع نبض القلب لمدة 15-30 دقيقة أو أكثر'
      : 'Exercise means 15 to 30+ minutes of elevated heart rate activity';

  String activityDesc(ActivityLevel a) => switch (a) {
    ActivityLevel.sedentary => isAr
        ? 'حياة مكتبية، تمرين قليل أو معدوم'
        : 'Desk life, little or no exercise',
    ActivityLevel.light => isAr
        ? 'تمرين 1 إلى 3 مرات في الأسبوع'
        : 'Exercise 1 to 3 times a week',
    ActivityLevel.moderate => isAr
        ? 'تمرين 4 إلى 5 مرات في الأسبوع'
        : 'Exercise 4 to 5 times a week',
    ActivityLevel.high => isAr
        ? 'تمرين يومي، أو تمرين شاق 3 إلى 6 مرات في الأسبوع'
        : 'Daily exercise, or intense exercise 3 to 6 times a week',
    ActivityLevel.athlete => isAr
        ? 'تدريب يومي شاق جدًا أو عمل بدني'
        : 'Very intense daily training or a physical job',
  };

  // Plain language, not numbers, by design.
  String goalDesc(WeightGoal g) => switch (g) {
    WeightGoal.lose => isAr ? 'عجز يومي معتدل' : 'A moderate daily deficit',
    WeightGoal.loseGently => isAr ? 'عجز يومي خفيف' : 'A light daily deficit',
    WeightGoal.maintain => isAr
        ? 'ثبات على وزنك الحالي'
        : 'Stay at your current weight',
    WeightGoal.gain => isAr ? 'فائض يومي بسيط' : 'A small daily surplus',
  };

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

  String weightGoalName(WeightGoal g) => switch (g) {
    WeightGoal.lose => isAr ? 'إنقاص الوزن' : 'Lose weight',
    WeightGoal.loseGently => isAr ? 'إنقاص تدريجي' : 'Lose gently',
    WeightGoal.maintain => isAr ? 'تثبيت الوزن' : 'Maintain',
    WeightGoal.gain => isAr ? 'زيادة الوزن' : 'Gain weight',
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

  String foodName(FoodItem f) => isAr ? f.nameAr : f.nameEn;
  String servingLabel(FoodItem f) => isAr ? f.servingAr : f.servingEn;

  /// Comma-joined food names for a meal's subtitle line.
  String joinFoods(Iterable<FoodItem> foods) =>
      foods.map(foodName).join(isAr ? '، ' : ', ');
}
