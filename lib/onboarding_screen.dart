import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'theme.dart';

/// Three pages, all skippable: language first (it gates everything), a
/// logging intro with the disclaimer, then goal setup reusing the goals
/// editor sheet. Defaults carry a skipped onboarding.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(AppState state) {
    state.completeOnboarding();
    // When replayed from settings this sits on the nav stack; on first
    // launch it is the home and the flag swap replaces it.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(
                  onPressed: () => _finish(state),
                  child: Text(l.skip, style: TextStyle(color: c.muted)),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _LanguagePage(onNext: _next),
                  _IntroPage(onNext: _next),
                  _GoalsPage(onDone: () => _finish(state)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? c.accent : c.macroTrack,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);

    Widget langButton(String code, String label) {
      final selected = state.localeCode == code;
      return OutlinedButton(
        onPressed: () => state.setLocale(code),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: selected ? c.chipBg : null,
          foregroundColor: c.ink,
          side: BorderSide(color: selected ? c.accent : c.divider, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    return _PageShell(
      children: [
        Text(
          state.l.chooseLanguage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.inkStrong,
          ),
        ),
        const SizedBox(height: 28),
        langButton('ar', 'العربية'),
        const SizedBox(height: 12),
        langButton('en', 'English'),
        const SizedBox(height: 28),
        _PrimaryButton(label: state.l.next, onPressed: onNext),
      ],
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;

    return _PageShell(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final meal in MealType.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.mealTint[meal],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meal.icon, color: c.mealIconColor, size: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l.introTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.inkStrong,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.introBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
        ),
        const SizedBox(height: 20),
        Text(
          l.disclaimerBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, height: 1.5, color: c.muted),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(label: l.next, onPressed: onNext),
      ],
    );
  }
}

class _GoalsPage extends StatelessWidget {
  const _GoalsPage({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = AppColors.of(context);
    final l = state.l;
    final g = state.goals;

    return _PageShell(
      children: [
        Text(
          l.onboardGoalsTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.inkStrong,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.onboardGoalsBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: c.ink),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => showGoalsEditor(context, state),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: c.ink,
            side: BorderSide(color: c.divider, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            '${l.dailyGoals} · ${fmtInt(g.kcal)} ${l.kcal}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(label: l.getStarted, onPressed: onDone),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
