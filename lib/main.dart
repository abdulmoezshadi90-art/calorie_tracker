import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web, expose the semantics tree immediately so screen readers (and
  // browser-based testing) work without the enable-accessibility tap.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  // Demo convenience on web: ?fresh=1 wipes saved state so a shared link
  // always starts at first-run onboarding (browser storage persists
  // across demo deploys otherwise).
  if (kIsWeb && Uri.base.queryParameters.containsKey('fresh')) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  final state = AppState();
  // Loading state, cold launch: the native splash stays up until this
  // await completes, so the first rendered frame already has the real
  // logs/goals/locale/profile — never a flash of defaults. This is the
  // only launch "loading" the app has, by design (local-only storage).
  await state.load();
  // Dev convenience on web: ?lang=ar / ?lang=en overrides the saved locale.
  if (kIsWeb) {
    final lang = Uri.base.queryParameters['lang'] ?? '';
    if (lang == 'ar' || lang == 'en') state.localeCode = lang;
  }
  runApp(CalorieApp(state: state));
}

/// On wide viewports (desktop web) the app keeps its phone layout: content
/// is centered at phone width on a deep-green backdrop instead of
/// stretching. Sits inside the MaterialApp builder so navigation, sheets
/// and dialogs are all framed too. Phone-sized windows are untouched.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  static const _phoneWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 500) return child;
        final c = AppColors.of(context);
        return ColoredBox(
          color: c.headerBottom,
          child: Center(
            child: Container(
              width: _phoneWidth,
              margin: const EdgeInsets.symmetric(vertical: 24),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class CalorieApp extends StatelessWidget {
  const CalorieApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => state.l.appTitle,
        debugShowCheckedModeBanner: false,
        locale: Locale(state.localeCode),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: state.themeMode,
        builder: (context, child) =>
            AppScope(state: state, child: _PhoneFrame(child: child!)),
        home: const AppStartup(),
      ),
    );
  }
}
