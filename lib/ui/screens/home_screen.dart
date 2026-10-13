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
import 'game_screen.dart';
import 'how_to_play_screen.dart';

/// The landing screen: branding, a picture of how the board grows, and the
/// way into the game.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  static const double _compactBelow = 780;
  static const double _growthCardFrom = 700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(
      gameControllerProvider.select((state) => state.soundEnabled),
    );
    final boardSize = ref.watch(boardSizeProvider);
    final winLength = ref.watch(winLengthProvider);
    final scheme = Theme.of(context).colorScheme;

    // Play must stay on screen without scrolling, so short phones get a
    // smaller logo and the shortest ones lose the growth card.
    final height = MediaQuery.sizeOf(context).height;
    final compact = height < _compactBelow;
    final showGrowthCard = height >= _growthCardFrom;
    final gap = compact ? AppSpacing.gutterSm : AppSpacing.margin;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _Confetti()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.sm,
                  AppSpacing.screenMargin,
                  AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _SoundToggle(
                          enabled: soundEnabled,
                          onPressed: ref
                              .read(gameControllerProvider.notifier)
                              .toggleSound,
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                      _Hero(logoSize: compact ? 84 : 112),
                      SizedBox(height: gap),
                      if (showGrowthCard) ...[
                        const _GrowthCard(),
                        SizedBox(height: gap),
                      ],
                      PillChip(
                        key: const ValueKey('home-board-chip'),
                        icon: Icons.circle,
                        iconColor: context.gameColors.xBadge,
                        label:
                            '$boardSize×$boardSize Board • '
                            'Get $winLength in a row',
                        background: scheme.surfaceContainerHigh,
                        foreground: scheme.onSurface,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: ChunkyButton(
                          key: const ValueKey('play'),
                          label: 'PLAY NOW',
                          icon: Icons.play_circle,
                          height: 64,
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(GameScreen.routeName),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: PillButton(
                          key: const ValueKey('how-to-play'),
                          label: 'How to Play',
                          icon: Icons.help_outline,
                          iconColor: scheme.secondary,
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(HowToPlayScreen.routeName),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundToggle extends StatelessWidget {
  const _SoundToggle({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadii.pill);

    return Semantics(
      button: true,
      toggled: enabled,
      label: 'Sound effects',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: softShadow(context, strength: 1.5),
        ),
        child: Material(
          key: const ValueKey('home-sound-toggle'),
          color: context.gameColors.card,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      enabled ? Icons.volume_up : Icons.volume_off,
                      size: 20,
                      color: enabled ? scheme.primary : scheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ExcludeSemantics(
                      child: Text(
                        enabled ? 'SFX ON' : 'MUTED',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.logoSize});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.gameColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          label: 'Tic Tac Toe Infinity',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'TIC TAC TOE',
                  maxLines: 1,
                  style: theme.textTheme.displaySmall!.copyWith(height: 1),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Transform.rotate(
                angle: -0.0175,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.ctaStart, colors.ctaEnd, colors.xBadge],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: softShadow(context, strength: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.margin,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'INFINITY',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: colors.onCta,
                        letterSpacing: 9,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        PillChip(
          icon: Icons.sync,
          label: 'Win. Expand. Repeat.',
          background: scheme.primaryFixed,
          foreground: scheme.onPrimaryFixedVariant,
          large: true,
        ),
      ],
    );
  }
}

/// The "Endless Growth" card: 3x3, then 4x4, then 5x5.
class _GrowthCard extends StatelessWidget {
  const _GrowthCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget arrow() => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Icon(Icons.arrow_forward, size: 18, color: scheme.outlineVariant),
    );

    return SoftCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.dynamic_feed, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Endless Growth',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              PillChip(
                label: 'Evolution',
                background: scheme.primaryFixed.withValues(alpha: 0.6),
                foreground: scheme.onPrimaryFixedVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutterSm),
          InsetPanel(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.gutterSm,
            ),
            child: Row(
              children: [
                const Expanded(child: _Stage(size: 3, label: '3×3 Grid')),
                arrow(),
                const Expanded(
                  child: _Stage(size: 4, label: '4×4 Epic', featured: true),
                ),
                arrow(),
                const Expanded(child: _Stage(size: 5, label: '5×5 Master')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutterSm),
          Text(
            'Every round you win unlocks a wider arena!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.size,
    required this.label,
    this.featured = false,
  });

  final int size;
  final String label;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniGrid(
          size: size,
          dimension: featured ? 52 : 48,
          background: featured ? scheme.primaryFixed : context.gameColors.card,
          cellColor: featured
              ? context.gameColors.card
              : scheme.surfaceContainerHighest,
          accentColor: featured
              ? scheme.primaryContainer
              : scheme.secondaryFixedDim,
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: theme.textTheme.labelSmall!.copyWith(
              color: featured ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: featured ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// The pale floating shapes behind the hero. Purely decorative.
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget token(Mark mark, Color background, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: MarkView(mark: mark, size: 22),
      ),
    );

    return ExcludeSemantics(
      child: IgnorePointer(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 112,
                left: -12,
                child: token(
                  Mark.x,
                  scheme.secondaryFixed.withValues(alpha: 0.5),
                  -0.21,
                ),
              ),
              Positioned(
                top: 80,
                right: 16,
                child: token(
                  Mark.o,
                  scheme.tertiaryFixed.withValues(alpha: 0.6),
                  0.21,
                ),
              ),
              Positioned(
                top: 288,
                right: 20,
                child: Icon(
                  Icons.star,
                  size: 24,
                  color: scheme.tertiaryFixedDim.withValues(alpha: 0.7),
                ),
              ),
              Positioned(
                top: 176,
                left: 96,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primaryFixedDim,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
