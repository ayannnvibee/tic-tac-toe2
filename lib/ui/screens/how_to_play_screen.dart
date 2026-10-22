import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../state/state.dart';
import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';
import '../widgets/mark_view.dart';
import '../widgets/mini_grid.dart';
import '../widgets/tactile.dart';
import 'legal_screen.dart';
import 'onboarding_screen.dart';

/// The rules, and the sound and haptics switches, on two tabs.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  static const String routeName = '/how-to-play';

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

enum _Tab { rules, controls }

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  _Tab _tab = _Tab.rules;

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
                    height: 64,
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: AppSpacing.gutterSm),
                        IconDisc(
                          icon: Icons.menu_book,
                          background: scheme.primaryFixed,
                          foreground: scheme.onPrimaryFixed,
                          size: 28,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Game Guide',
                            style: theme.textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TabBar(
                    selected: _tab,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _tab == _Tab.rules
                          ? const _RulesPanel()
                          : const _ControlsPanel(),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('show-intro'),
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(OnboardingScreen.routeName),
                    icon: const Icon(Icons.slideshow),
                    label: const Text('Show intro again'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: ChunkyButton(
                      key: const ValueKey('guide-done'),
                      label: 'GOT IT',
                      icon: Icons.play_circle,
                      onPressed: () => Navigator.of(context).maybePop(),
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

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelected});

  final _Tab selected;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                key: const ValueKey('tab-rules'),
                label: 'How to Play',
                icon: Icons.sports_esports,
                selected: selected == _Tab.rules,
                onTap: () => onSelected(_Tab.rules),
              ),
            ),
            Expanded(
              child: _TabButton(
                key: const ValueKey('tab-controls'),
                label: 'Game Controls',
                icon: Icons.tune,
                selected: selected == _Tab.controls,
                onTap: () => onSelected(_Tab.controls),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(AppRadii.pill);

    return Semantics(
      button: true,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected ? softShadow(context) : null,
        ),
        child: Material(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The overline and title at the top of a guide card.
class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.overline, required this.title, this.icon});

  final String overline;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline.toUpperCase(),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        if (icon != null)
          IconDisc(
            icon: icon!,
            background: scheme.primaryFixed,
            foreground: scheme.primary,
          ),
      ],
    );
  }
}

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.gameColors;
    final muted = theme.textTheme.bodySmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Column(
      children: [
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            children: [
              const _CardHeading(
                overline: 'Core mechanics',
                title: 'You vs Computer',
                icon: Icons.groups,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PlayerPill(
                      mark: Mark.x,
                      who: 'You',
                      what: 'Blue Cross',
                      wash: colors.xWash,
                      color: colors.xMark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PlayerPill(
                      mark: Mark.o,
                      who: 'Computer',
                      what: 'Orange Ring',
                      wash: colors.oWash,
                      color: colors.oMark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutterSm),
              Text(
                'You go first. Take turns marking one empty cell each.',
                style: muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeading(
                overline: 'Infinity growth',
                title: 'Board Evolution',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Beat the computer to grow the board.', style: muted),
              const SizedBox(height: AppSpacing.gutterSm),
              const _StepRow(
                gridSize: 3,
                title: '3×3 and 4×4',
                target: 'Get 3',
                body: 'You need 3 in a row.',
                trailing: Icons.arrow_forward,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _StepRow(
                gridSize: 5,
                title: '5×5 board',
                target: 'Get 4',
                body: 'You need 4 in a row.',
                trailing: Icons.arrow_forward,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _StepRow(
                gridSize: 6,
                title: '6×6 and larger',
                target: 'Get 5',
                body: 'You need 5 in a row, however big it gets.',
                trailing: Icons.all_inclusive,
              ),
              const SizedBox(height: AppSpacing.gutterSm),
              Text(
                'A row can run across, down or diagonally, anywhere on '
                'the board.',
                style: muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.balance, size: 20, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Round Results',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutterSm),
              _OutcomeRow(
                icon: Icons.emoji_events,
                background: colors.xBadge,
                foreground: colors.onXBadge,
                title: 'You win',
                body: 'The board grows by one for the next round.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _OutcomeRow(
                icon: Icons.replay,
                background: colors.oBadge,
                foreground: colors.onOBadge,
                title: 'Computer wins',
                body: 'You replay the same board size.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _OutcomeRow(
                icon: Icons.refresh,
                background: scheme.surfaceContainerHighest,
                foreground: scheme.onSurfaceVariant,
                title: 'Draw or New Game',
                body: 'You start over at 3×3 with the score at 0–0.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({
    required this.mark,
    required this.who,
    required this.what,
    required this.wash,
    required this.color,
  });

  final Mark mark;
  final String who;
  final String what;
  final Color wash;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutterSm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.gameColors.card,
                shape: BoxShape.circle,
                boxShadow: softShadow(context),
              ),
              child: MarkView(mark: mark, size: 26),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall!.copyWith(color: color),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      what,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall,
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

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.gridSize,
    required this.title,
    required this.target,
    required this.body,
    required this.trailing,
  });

  final int gridSize;
  final String title;
  final String target;
  final String body;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InsetPanel(
      child: Row(
        children: [
          MiniGrid(
            size: gridSize,
            dimension: 48,
            background: scheme.surface,
            cellColor: scheme.surfaceContainerHighest,
            accentColor: context.gameColors.xMark,
          ),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleSmall),
                    ),
                    Text(
                      target,
                      style: theme.textTheme.labelSmall!.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  body,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(trailing, size: 20, color: scheme.primary),
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InsetPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconDisc(
            icon: icon,
            background: background,
            foreground: foreground,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                Text(
                  body,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsPanel extends ConsumerWidget {
  const _ControlsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(
      gameControllerProvider.select((state) => state.soundEnabled),
    );
    final hapticsEnabled = ref.watch(
      gameControllerProvider.select((state) => state.hapticsEnabled),
    );
    final controller = ref.read(gameControllerProvider.notifier);

    final sound = SoftCard(
      padding: const EdgeInsets.all(AppSpacing.margin),
      child: Column(
        children: [
          const _CardHeading(
            overline: 'Gameplay experience',
            title: 'Sound & Haptics',
          ),
          const SizedBox(height: AppSpacing.md),
          _SwitchRow(
            switchKey: const ValueKey('switch-sound'),
            icon: Icons.volume_up,
            title: 'Sound Effects',
            subtitle: 'Pops, clicks and fanfare',
            value: soundEnabled,
            onChanged: (_) => controller.toggleSound(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchRow(
            switchKey: const ValueKey('switch-haptics'),
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'A short buzz when you tap',
            value: hapticsEnabled,
            onChanged: (_) => controller.toggleHaptics(),
          ),
        ],
      ),
    );

    return Column(
      children: [
        sound,
        const SizedBox(height: AppSpacing.md),
        SoftCard(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            children: [
              const _CardHeading(overline: 'Your data', title: 'Legal'),
              const SizedBox(height: AppSpacing.md),
              _LinkRow(
                rowKey: const ValueKey('settings-privacy'),
                icon: Icons.privacy_tip_outlined,
                title: LegalDocument.privacyPolicy.title,
                subtitle: 'What the game and its ads use',
                onTap: () =>
                    LegalScreen.open(context, LegalDocument.privacyPolicy),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LinkRow(
                rowKey: const ValueKey('settings-terms'),
                icon: Icons.description_outlined,
                title: LegalDocument.termsOfUse.title,
                subtitle: 'The rules for using the game',
                onTap: () =>
                    LegalScreen.open(context, LegalDocument.termsOfUse),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable row that opens a document.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: rowKey,
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: InsetPanel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconDisc(
                icon: icon,
                background: scheme.primaryFixed,
                foreground: scheme.onPrimaryFixed,
              ),
              const SizedBox(width: AppSpacing.gutterSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelLarge),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InsetPanel(
      padding: const EdgeInsets.all(14),
      child: MergeSemantics(
        child: Row(
          children: [
            IconDisc(
              icon: icon,
              background: scheme.primaryFixed,
              foreground: scheme.onPrimaryFixed,
            ),
            const SizedBox(width: AppSpacing.gutterSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelLarge),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(key: switchKey, value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
