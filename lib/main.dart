import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web, expose the semantics tree immediately so screen readers (and
  // browser-based testing) work without the enable-accessibility tap.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  final state = AppState();
  await state.load();
  // Dev convenience on web: ?lang=ar / ?lang=en overrides the saved locale.
  if (kIsWeb) {
    final lang = Uri.base.queryParameters['lang'] ?? '';
    if (lang == 'ar' || lang == 'en') state.localeCode = lang;
  }
  runApp(CalorieApp(state: state));
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
        themeMode: ThemeMode.system,
        builder: (context, child) => AppScope(state: state, child: child!),
        home: const HomeScreen(),
      ),
    );
  }
}
