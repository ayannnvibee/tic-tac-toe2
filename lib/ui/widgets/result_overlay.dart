import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import 'mark_view.dart';
import 'mini_grid.dart';
import 'tactile.dart';

/// The card shown over the finished board when a round ends.
///
/// It has exactly one action, [onContinue], labelled for what happens next:
/// a bigger board after a human win, the same board after a computer win, or
/// a full restart after a draw.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.result,
    required this.boardSize,
    required this.onContinue,
    this.onWatchAd,
  });

  /// How the round ended; never [RoundStatus.inProgress].
  final RoundStatus result;

  /// The size of the board the round was played on.
  final int boardSize;

  final VoidCallback onContinue;

  /// Offers a rewarded ad under the main button when set: after a loss it
  /// undoes the losing moves, after a draw it keeps the level.
  final VoidCallback? onWatchAd;

  static const String secondChanceLabel = 'Watch ad: second chance';
  static const String keepLevelLabel = 'Watch ad: keep your level';

  static const String nextLevelLabel = 'NEXT LEVEL';
  static const String retryLevelLabel = 'RETRY LEVEL';
  static const String restartLabel = 'RESTART';

  /// One line saying what the button will do, shown under the title.
  static String subtitleFor(RoundStatus result, int boardSize) =>
      switch (result) {
        RoundStatus.humanWon =>
          'Next level: ${boardSize + 1} × ${boardSize + 1}',
        RoundStatus.computerWon => 'Try $boardSize × $boardSize again',
        RoundStatus.draw || RoundStatus.inProgress =>
          'Back to $initialBoardSize × $initialBoardSize',
      };

  static const Duration entranceDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final subtitle = subtitleFor(result, boardSize);

    final card = DecoratedBox(
      key: const ValueKey('result-card'),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1065).withValues(alpha: 0.14),
            blurRadius: 36,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _WithAdButton(
          onWatchAd: onWatchAd,
          label: result == RoundStatus.draw
              ? keepLevelLabel
              : secondChanceLabel,
          child: switch (result) {
            RoundStatus.humanWon => _HumanWin(
              boardSize: boardSize,
              subtitle: subtitle,
              onContinue: onContinue,
            ),
            RoundStatus.computerWon => _ComputerWin(
              boardSize: boardSize,
              subtitle: subtitle,
              onContinue: onContinue,
            ),
            RoundStatus.draw || RoundStatus.inProgress => _Draw(
              subtitle: subtitle,
              onContinue: onContinue,
            ),
          },
        ),
      ),
    );

    // The scrim fades in while the card fades and settles into place. With
    // reduce motion on, both simply appear.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : entranceDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: colors.scrim.withValues(alpha: colors.scrim.a * t),
          ),
          Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)),
              child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
            ),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _grid(int size) => '$size×$size';

/// The card's content, with the rewarded ad button under it when offered.
class _WithAdButton extends StatelessWidget {
  const _WithAdButton({
    required this.onWatchAd,
    required this.label,
    required this.child,
  });

  final VoidCallback? onWatchAd;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onWatchAd = this.onWatchAd;
    if (onWatchAd == null) return child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: PillButton(
            key: const ValueKey('result-watch-ad'),
            label: label,
            icon: Icons.ondemand_video,
            onPressed: onWatchAd,
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.title, required this.subtitle, this.color});

  final String title;
  final String subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            key: const ValueKey('result-title'),
            maxLines: 1,
            style:
                (color == null
                        ? theme.textTheme.headlineLarge
                        : theme.textTheme.displaySmall)!
                    .copyWith(color: color),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          key: const ValueKey('result-subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HumanWin extends StatelessWidget {
  const _HumanWin({
    required this.boardSize,
    required this.subtitle,
    required this.onContinue,
  });

  final int boardSize;
  final String subtitle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.gameColors;
    final next = boardSize + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.trophyStart, colors.trophyEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primaryFixed,
                blurRadius: 16,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Icon(Icons.emoji_events, size: 50, color: colors.onTrophy),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        _Headline(title: 'YOU WIN!', subtitle: subtitle, color: scheme.primary),
        const SizedBox(height: AppSpacing.md),
        InsetPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GridNode(
                    size: boardSize,
                    label: _grid(boardSize),
                    highlighted: false,
                  ),
                  // Shrinks rather than overflows when the text is very large.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PillChip(
                            label: 'UNLOCKED',
                            background: colors.ctaStart,
                            foreground: colors.onCta,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _GridNode(size: next, label: _grid(next), highlighted: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                radius: AppRadii.md,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    IconDisc(
                      icon: Icons.grid_4x4,
                      background: scheme.secondaryFixed,
                      foreground: scheme.onSecondaryFixed,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next board: ${_grid(next)}',
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(
                            'Get ${winLengthFor(next)} in a row to win',
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ChunkyButton(
            key: const ValueKey('result-continue'),
            label: ResultOverlay.nextLevelLabel,
            trailingIcon: Icons.arrow_forward,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _GridNode extends StatelessWidget {
  const _GridNode({
    required this.size,
    required this.label,
    required this.highlighted,
  });

  final int size;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted ? scheme.primaryFixed : context.gameColors.card,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: softShadow(context),
          ),
          child: MiniGrid(
            // Very large boards are drawn as 8x8 so the cells stay visible.
            size: size.clamp(3, 8),
            dimension: 42,
            background: scheme.surfaceContainer,
            cellColor: scheme.surfaceDim,
            accentColor: highlighted
                ? scheme.secondaryFixedDim
                : scheme.primaryFixedDim,
            accentAntiDiagonal: highlighted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall!.copyWith(
            color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: highlighted ? FontWeight.w900 : null,
          ),
        ),
      ],
    );
  }
}

class _ComputerWin extends StatelessWidget {
  const _ComputerWin({
    required this.boardSize,
    required this.subtitle,
    required this.onContinue,
  });

  final int boardSize;
  final String subtitle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.tertiaryFixedDim.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconDisc(
            icon: Icons.smart_toy,
            background: scheme.tertiaryFixed,
            foreground: scheme.onTertiaryFixedVariant,
            size: 64,
          ),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        _Headline(title: 'COMPUTER WINS!', subtitle: subtitle),
        const SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.tertiaryFixed.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutterSm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_view,
                      size: 18,
                      color: context.gameColors.oMark,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Current board: ${_grid(boardSize)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                PillChip(
                  icon: Icons.check_circle,
                  label:
                      'Board stays at ${_grid(boardSize)} • No progress lost!',
                  background: context.gameColors.card,
                  foreground: scheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ChunkyButton(
            key: const ValueKey('result-continue'),
            label: ResultOverlay.retryLevelLabel,
            icon: Icons.replay,
            style: ChunkyButtonStyle.retry,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

class _Draw extends StatelessWidget {
  const _Draw({required this.subtitle, required this.onContinue});

  final String subtitle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryFixed.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarkView(mark: Mark.x, size: 44),
              SizedBox(width: AppSpacing.xs),
              MarkView(mark: Mark.o, size: 44),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutterSm),
        PillChip(
          label: 'STALEMATE SHOWDOWN',
          background: scheme.primaryFixed,
          foreground: scheme.onPrimaryFixed,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Headline(title: "IT'S A DRAW!", subtitle: subtitle),
        const SizedBox(height: AppSpacing.md),
        InsetPanel(
          color: scheme.surfaceContainer,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniGrid(
                size: 3,
                dimension: 44,
                background: scheme.primaryFixed,
                cellColor: scheme.primaryFixedDim,
                accentColor: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restart_alt,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'BOARD RESET RULE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A draw resets the board to 3×3 and the score to 0–0.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ChunkyButton(
            key: const ValueKey('result-continue'),
            label: ResultOverlay.restartLabel,
            icon: Icons.play_arrow,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}
