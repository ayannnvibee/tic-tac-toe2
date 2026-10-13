import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import 'mark_view.dart';
import 'tactile.dart';

/// Which side the turn banner is talking about, for its colour.
enum TurnTone { human, computer, result }

/// The versus banner: the human's and the computer's win counters either
/// side of a "VS" badge, with the turn status underneath.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.humanWins,
    required this.computerWins,
    required this.turnLabel,
    required this.tone,
  });

  final int humanWins;
  final int computerWins;
  final String turnLabel;
  final TurnTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.gameColors;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PlayerPanel(
                      key: const ValueKey('panel-human'),
                      name: 'YOU',
                      wins: humanWins,
                      winsKey: const ValueKey('score-human'),
                      mark: Mark.x,
                      icon: Icons.face,
                      active: tone == TurnTone.human,
                      nameColor: colors.xMark,
                      wash: colors.xWash,
                      badge: colors.xBadge,
                      onBadge: colors.onXBadge,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _PlayerPanel(
                      key: const ValueKey('panel-computer'),
                      name: 'COMPUTER',
                      wins: computerWins,
                      winsKey: const ValueKey('score-computer'),
                      mark: Mark.o,
                      icon: Icons.smart_toy,
                      active: tone == TurnTone.computer,
                      nameColor: colors.oMark,
                      wash: colors.oWash,
                      badge: colors.oBadge,
                      onBadge: colors.onOBadge,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  boxShadow: softShadow(context),
                ),
                child: Text(
                  'VS',
                  style: text.labelSmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _TurnBanner(label: turnLabel, tone: tone),
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    super.key,
    required this.name,
    required this.wins,
    required this.winsKey,
    required this.mark,
    required this.icon,
    required this.active,
    required this.nameColor,
    required this.wash,
    required this.badge,
    required this.onBadge,
    required this.alignEnd,
  });

  final String name;
  final int wins;
  final Key winsKey;
  final Mark mark;
  final IconData icon;
  final bool active;
  final Color nameColor;
  final Color wash;
  final Color badge;
  final Color onBadge;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.gameColors;

    final avatar = SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconDisc(
            icon: icon,
            background: badge,
            foreground: onBadge,
            size: 44,
          ),
          Positioned(
            bottom: -2,
            right: alignEnd ? null : -2,
            left: alignEnd ? -2 : null,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                boxShadow: softShadow(context),
              ),
              child: MarkView(mark: mark, size: 14),
            ),
          ),
        ],
      ),
    );

    final details = Expanded(
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: text.labelMedium!.copyWith(
                color: nameColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text('$wins', key: winsKey, style: text.headlineMedium),
        ],
      ),
    );

    return Semantics(
      label: '$name: $wins ${wins == 1 ? 'win' : 'wins'}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? wash : colors.inset,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: alignEnd
                ? [details, const SizedBox(width: AppSpacing.sm), avatar]
                : [avatar, const SizedBox(width: AppSpacing.sm), details],
          ),
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.label, required this.tone});

  final String label;
  final TurnTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, dot) = switch (tone) {
      TurnTone.human => (
        scheme.secondaryFixed,
        scheme.onSecondaryFixed,
        scheme.secondary,
      ),
      TurnTone.computer => (
        scheme.tertiaryFixed,
        scheme.onTertiaryFixed,
        scheme.tertiary,
      ),
      TurnTone.result => (
        scheme.primaryFixed,
        scheme.onPrimaryFixed,
        scheme.primary,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  key: const ValueKey('turn-label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: foreground, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
