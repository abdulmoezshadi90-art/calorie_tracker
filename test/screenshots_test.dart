// Generates real rendered screenshots of the app (test/goldens/*.png).
// Run: flutter test --update-goldens test/screenshots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calorie_tracker/app_state.dart';
import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models.dart';

Future<void> _loadFonts(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

const _sdkFonts = r'C:\dev\flutter\bin\cache\artifacts\material_fonts';
const _winFonts = r'C:\Windows\Fonts';

/// Pumps the app on an iPhone-sized surface with a representative day logged.
Future<AppState> _pumpWithSampleData(
  WidgetTester tester, {
  String locale = 'en',
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  // Pinned clock: goldens must not change as real days pass (a Wednesday
  // mid-morning, so the week strip and greeting are stable).
  final state = AppState(clock: () => DateTime(2026, 7, 15, 9, 30));
  await state.load();
  state.localeCode = locale;
  state.userName = locale == 'ar' ? 'مها' : 'Maha';
  // A sample day: breakfast, lunch and a snack logged; dinner still open.
  state.addEntry(state.selectedDate, 'boiled_eggs', 1, MealType.breakfast);
  state.addEntry(state.selectedDate, 'khubz', 1, MealType.breakfast);
  state.addEntry(state.selectedDate, 'rice_chicken', 1, MealType.lunch);
  state.addEntry(state.selectedDate, 'kalee_cheese', 2, MealType.snack);
  await tester.pumpWidget(CalorieApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUpAll(() async {
    await _loadFonts('Roboto', [
      '$_sdkFonts\\roboto-regular.ttf',
      '$_sdkFonts\\roboto-medium.ttf',
      '$_sdkFonts\\roboto-bold.ttf',
      '$_sdkFonts\\roboto-black.ttf',
    ]);
    await _loadFonts('MaterialIcons', [
      '$_sdkFonts\\materialicons-regular.otf',
    ]);
    // Windows fonts as glyph fallback for Arabic text and emoji.
    await _loadFonts('SegoeUI', [
      '$_winFonts\\segoeui.ttf',
      '$_winFonts\\segoeuib.ttf',
    ]);
    await _loadFonts('SegoeUIEmoji', ['$_winFonts\\seguiemj.ttf']);
  });

  testWidgets('home — light, English', (tester) async {
    await _pumpWithSampleData(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_light_en.png'),
    );
  });

  testWidgets('home — light, Arabic RTL', (tester) async {
    await _pumpWithSampleData(tester, locale: 'ar');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_light_ar.png'),
    );
  });

  testWidgets('home — dark, English', (tester) async {
    await _pumpWithSampleData(tester, brightness: Brightness.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_dark_en.png'),
    );
  });

  testWidgets('home — dark, Arabic RTL', (tester) async {
    await _pumpWithSampleData(
      tester,
      locale: 'ar',
      brightness: Brightness.dark,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_dark_ar.png'),
    );
  });

  testWidgets('search — Arabic query', (tester) async {
    await _pumpWithSampleData(tester, locale: 'ar');
    // Dinner is the only unlogged meal, so its row carries the only meal "+".
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'كالي');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/search_ar.png'),
    );
  });

  testWidgets('history with 7-day chart — English', (tester) async {
    final state = await _pumpWithSampleData(tester);
    // A couple of past days so the chart and list have content.
    state.addEntry(DateTime(2026, 7, 13), 'kalee_cheese', 2, MealType.snack);
    for (var i = 0; i < 5; i++) {
      state.addEntry(DateTime(2026, 7, 14), 'bazin', 1, MealType.lunch);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/history_en.png'),
    );
  });

  testWidgets('add-food sheet — English', (tester) async {
    await _pumpWithSampleData(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'kalee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalee Chips — Cheese'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_en.png'),
    );
  });
}
