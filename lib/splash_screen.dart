import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_state.dart';
import 'onboarding_screen.dart';
import 'theme.dart';

/// Shown for every cold launch, `home:`'s actual content (see main.dart).
/// The real app data is already loaded by the time this builds (main.dart
/// awaits `AppState.load()` before `runApp`), so there is nothing to wait
/// on here, [splashDuration] is a deliberately artificial minimum so the
/// brand moment in [SplashScreen] is actually visible before handing off
/// to onboarding or the app shell.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  /// Mutable so `test/flutter_test_config.dart` can zero it out for the
  /// whole suite — every test that pumps `CalorieApp` goes through this
  /// screen, and the real 1200ms cost real wall-clock time across
  /// hundreds of test cases even though it's fake-clock time underneath.
  @visibleForTesting
  static Duration splashDuration = const Duration(milliseconds: 1200);

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(AppStartup.splashDuration, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _showSplash
          ? const SplashScreen(key: ValueKey('splash'))
          : (state.onboardingDone
                ? const AppShell(key: ValueKey('shell'))
                : const OnboardingScreen(key: ValueKey('onboarding'))),
    );
  }
}

/// Logo pop, name fade/slide in below it, three loading dots settle in
/// last and keep pulsing until [AppStartup] swaps this out. Colors and
/// background match the native splash screen exactly (same pageBg tokens
/// flutter_native_splash uses) so there is no visible seam between the
/// platform splash and this one taking over.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward();

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    // Overshoots past 1.0 then settles — the "pop" — via a two-piece
    // sequence rather than a single elastic curve, so the settle reads as
    // controlled instead of jittery.
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        weight: 60,
        tween: Tween(
          begin: 0.55,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      TweenSequenceItem(
        weight: 40,
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.linear),
      ),
    );

    _nameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.68, curve: Curves.easeOut),
    );
    _nameSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.68, curve: Curves.easeOut),
          ),
        );

    _loadingOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _logoSize = 132.0;
  static const _nameGap = 18.0;
  static const _nameHeight = 40.0; // fontSize 30, bold — approx line height
  static const _dotsGap = 32.0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The logo is pinned to the true screen center via its own Center,
    // independent of the name/dots below it — Column(mainAxisAlignment:
    // center) centered the whole group instead, which reserves layout
    // space for the name and dots even while they're still at opacity 0,
    // so the logo sat visibly shifted upward for the first stretch of the
    // animation, before there was anything else on screen to explain why.
    final centerY = MediaQuery.sizeOf(context).height / 2;

    return Scaffold(
      backgroundColor: c.pageBg,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(
                  isDark
                      ? 'assets/branding/splash_mark_dark.png'
                      : 'assets/branding/splash_mark.png',
                  width: _logoSize,
                  height: _logoSize,
                ),
              ),
            ),
          ),
          Positioned(
            top: centerY + _logoSize / 2 + _nameGap,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _nameOpacity,
                child: SlideTransition(
                  position: _nameSlide,
                  // Forced LTR regardless of the app's own locale/RTL
                  // state — without it, Arabic mode's RTL paragraph
                  // direction flips the bidi algorithm's visual order
                  // (Zibda ends up on the right, زبدة on the left), the
                  // opposite of the fixed English-left/Arabic-right
                  // lockup used everywhere else this wordmark appears
                  // (README, store listing).
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'Zibda · زبدة',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: c.inkStrong,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: centerY + _logoSize / 2 + _nameGap + _nameHeight + _dotsGap,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _loadingOpacity,
                child: const _LoadingDots(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots pulsing in sequence, gold to match the icon's own accent —
/// ties the loading motif back to the logo rather than a generic spinner.
/// Runs on its own repeating controller, independent of the one-shot
/// entrance animation above, so it keeps pulsing for as long as the splash
/// stays on screen.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Dot(color: c.gold, t: _controller.value, phase: i * 0.2),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.t, required this.phase});
  final Color color;
  final double t;
  final double phase;

  @override
  Widget build(BuildContext context) {
    // Each dot runs the same up-down cycle, offset by [phase], so they
    // pulse in a left-to-right wave instead of all together.
    final local = (t + phase) % 1.0;
    final scale = 0.5 + 0.5 * (1 - (2 * local - 1).abs());
    return Opacity(
      opacity: 0.4 + 0.6 * scale,
      child: Transform.scale(
        scale: 0.7 + 0.3 * scale,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
