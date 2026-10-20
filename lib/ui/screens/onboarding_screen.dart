import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../state/state.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/mark_view.dart';
import '../widgets/mini_grid.dart';
import '../widgets/tactile.dart';
import 'home_screen.dart';

/// The three-page intro shown on the very first launch, and again from the
/// guide. Finishing or skipping it marks it as seen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const String routeName = '/intro';

  static const Duration pageDuration = Duration(milliseconds: 320);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;

  static const int _pageCount = 3;

  bool get _isLast => _page == _pageCount - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingStoreProvider).markIntroSeen();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    // Opened from the guide: go back to it. First launch: on to Home.
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(HomeScreen.routeName);
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(_page + 1);
    } else {
      _pages.nextPage(
        duration: OnboardingScreen.pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: TextButton(
                          key: const ValueKey('onboarding-skip'),
                          onPressed: _isLast ? null : _finish,
                          child: Text(
                            'SKIP',
                            style: theme.textTheme.labelLarge!.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      key: const ValueKey('onboarding-pages'),
                      controller: _pages,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: const [
                        _IntroPage(
                          art: _WelcomeArt(),
                          title: 'Welcome to\nTic Tac Toe Infinity',
                          body:
                              'You are X, the computer is O, and you always '
                              'make the first move.',
                        ),
                        _IntroPage(
                          art: _GrowArt(),
                          title: 'Win to grow the board',
                          body:
                              'Every win unlocks a bigger board: 3×3, 4×4, '
                              '5×5 and on and on. Get 3 in a row on 3×3 and '
                              '4×4, 4 on 5×5, and 5 from 6×6 up.',
                        ),
                        _IntroPage(
                          art: _OutcomeArt(),
                          title: 'Lose or draw?',
                          body:
                              'Lose and you replay the same size. A draw '
                              'starts over at 3×3. Watch a short ad for a '
                              'second chance or to keep your level.',
                        ),
                      ],
                    ),
                  ),
                  _Dots(count: _pageCount, current: _page),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ChunkyButton(
                      key: ValueKey(
                        _isLast ? 'onboarding-done' : 'onboarding-next',
                      ),
                      label: _isLast ? "LET'S PLAY" : 'NEXT',
                      icon: _isLast ? Icons.play_circle : null,
                      trailingIcon: _isLast ? null : Icons.arrow_forward,
                      onPressed: _next,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.art,
    required this.title,
    required this.body,
  });

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              art,
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) => const AppLogo(size: 160);
}

class _GrowArt extends StatelessWidget {
  const _GrowArt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget grid(int size, double dimension, {bool highlighted = false}) =>
        SoftCard(
          radius: AppRadii.md,
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: MiniGrid(
            size: size,
            dimension: dimension,
            background: scheme.surfaceContainer,
            cellColor: scheme.surfaceDim,
            accentColor: highlighted
                ? scheme.secondaryFixedDim
                : scheme.primaryFixedDim,
            accentAntiDiagonal: highlighted,
          ),
        );
    final arrow = Icon(Icons.arrow_forward, color: scheme.primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        grid(3, 44),
        const SizedBox(width: AppSpacing.xs),
        arrow,
        const SizedBox(width: AppSpacing.xs),
        grid(4, 58),
        const SizedBox(width: AppSpacing.xs),
        arrow,
        const SizedBox(width: AppSpacing.xs),
        grid(5, 72, highlighted: true),
      ],
    );
  }
}

class _OutcomeArt extends StatelessWidget {
  const _OutcomeArt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.gameColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconDisc(
          icon: Icons.replay,
          background: scheme.tertiaryFixed,
          foreground: scheme.onTertiaryFixedVariant,
          size: 64,
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 112,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryFixed.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarkView(mark: Mark.x, size: 36),
              SizedBox(width: AppSpacing.xs),
              MarkView(mark: Mark.o, size: 36),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconDisc(
          icon: Icons.ondemand_video,
          background: colors.ctaStart,
          foreground: colors.onCta,
          size: 64,
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${current + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
        ],
      ),
    );
  }
}
