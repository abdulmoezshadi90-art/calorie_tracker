import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';

Future<AppState> _pumpSettings(WidgetTester tester, {String locale = 'en'}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final state = AppState();
  await state.load();
  state.localeCode = locale;
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('settings renders RTL at 375x812 without overflow', (
    tester,
  ) async {
    await _pumpSettings(tester, locale: 'ar');

    expect(tester.takeException(), isNull);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('الأهداف اليومية'), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);
    expect(find.text('إخلاء مسؤولية'), findsOneWidget);

    final context = tester.element(find.text('الإعدادات'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('goals editor rejects zero', (tester) async {
    final state = await _pumpSettings(tester);

    await tester.tap(find.text('Daily goals'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(state.goals.kcal, 2000); // unchanged
  });

  testWidgets('feedback item falls back to copying the email address', (
    tester,
  ) async {
    await _pumpSettings(tester);

    // Simulate a device with no mail app: channel answers false.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('ly.app.calorie_tracker/mail'),
      (call) async => false,
    );
    // Capture the clipboard write the fallback performs.
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );

    expect(find.text('Send feedback'), findsOneWidget);
    await tester.ensureVisible(find.text('Send feedback'));
    await tester.tap(find.text('Send feedback'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // No mail channel in tests → clipboard fallback with confirmation.
    final clipboard = platformCalls.where(
      (c) => c.method == 'Clipboard.setData',
    );
    expect(clipboard, hasLength(1));
    expect(
      (clipboard.single.arguments as Map)['text'],
      'abdulmoezshadi.90@gmail.com',
    );
    expect(find.textContaining('Email address copied'), findsOneWidget);
  });

  testWidgets('goals editor rejects empty input', (tester) async {
    final state = await _pumpSettings(tester);

    await tester.tap(find.text('Daily goals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid number'), findsOneWidget);
    expect(state.goals.kcal, 2000);
  });

  testWidgets('goals editor caps input at 5 digits (huge numbers)', (
    tester,
  ) async {
    final state = await _pumpSettings(tester);

    await tester.tap(find.text('Daily goals'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Calories'),
      '1234567',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(state.goals.kcal, 12345); // LengthLimitingTextInputFormatter(5)
  });

  testWidgets('valid goal edit updates the home calorie bar live', (
    tester,
  ) async {
    final state = await _pumpSettings(tester);

    await tester.tap(find.text('Daily goals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '1800');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Goals saved'), findsOneWidget);
    expect(state.goals.kcal, 1800);

    // Back on home: the calorie card reflects the new goal with no restart.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('of 1,800 kcal'), findsOneWidget);
    expect(find.text('1,800 kcal left today'), findsOneWidget);
  });

  testWidgets('Eastern Arabic input ٢٠٠٠ stores 2000 (hard requirement 1)', (
    tester,
  ) async {
    final state = await _pumpSettings(tester, locale: 'ar');

    await tester.tap(find.text('الأهداف اليومية'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'سعرات حرارية'),
      '٢٥٠٠',
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(state.goals.kcal, 2500);
  });

  testWidgets('below-floor value asks for gentle confirm, then saves', (
    tester,
  ) async {
    final state = await _pumpSettings(tester);

    await tester.tap(find.text('Daily goals'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Calories'), '1000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Gentle confirm dialog, not a hard block.
    expect(
      find.text('This value is lower than typical. Continue anyway?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(state.goals.kcal, 1000);
  });
}
