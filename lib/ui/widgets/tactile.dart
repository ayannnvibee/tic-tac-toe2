import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/game_colors.dart';

/// The soft, warm drop shadow used under raised cards and buttons.
List<BoxShadow> softShadow(BuildContext context, {double strength = 1}) {
  final tint = context.gameColors.shadow;
  return [
    BoxShadow(
      color: tint.withValues(alpha: 0.08 * strength),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03 * strength),
      blurRadius: 4,
      spreadRadius: -1,
      offset: const Offset(0, 2),
    ),
  ];
}

/// A raised white (or dark) card with generous corners.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.lg,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.gameColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softShadow(context),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A recessed strip inside a [SoftCard].
class InsetPanel extends StatelessWidget {
  const InsetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.gutterSm),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.gameColors.inset,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

enum ChunkyButtonStyle { primary, retry }

/// The big call-to-action: a gradient capsule with a solid bottom lip.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.style = ChunkyButtonStyle.primary,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ChunkyButtonStyle style;
  final double height;

  static const double _lip = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final (start, end, lip) = switch (style) {
      ChunkyButtonStyle.primary => (
        colors.ctaStart,
        colors.ctaEnd,
        colors.ctaLip,
      ),
      ChunkyButtonStyle.retry => (
        colors.retryStart,
        colors.retryEnd,
        colors.retryLip,
      ),
    };
    final vertical = style == ChunkyButtonStyle.retry;
    final radius = BorderRadius.circular(AppRadii.lg);
    final text = Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: colors.onCta,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w900,
    );

    return Semantics(
      button: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: softShadow(context, strength: 2.5),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: vertical
                        ? Alignment.topCenter
                        : Alignment.centerLeft,
                    end: vertical
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    colors: [start, end],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: _lip,
                  width: double.infinity,
                  child: ColoredBox(color: lip),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      _lip,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: colors.onCta, size: height * 0.44),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label, style: text, maxLines: 1),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(trailingIcon, color: colors.onCta, size: 24),
                        ],
                      ],
                    ),
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

/// A flat pill button: white for utility actions, or filled when [filled].
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.filled = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? iconColor;

  /// Filled with the brand purple instead of the card colour.
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.gameColors;
    final background = filled ? colors.ctaEnd : colors.card;
    final foreground = filled ? colors.onCta : theme.colorScheme.onSurface;
    final radius = BorderRadius.circular(AppRadii.pill);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: softShadow(context, strength: 1.5),
      ),
      child: Material(
        color: background,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: iconColor ?? foreground),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: foreground,
                      letterSpacing: filled ? 0.8 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 44dp circular icon button, as in the design's top bar.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainer,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: iconColor ?? scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// A small rounded label, optionally with a leading icon.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconColor,
    this.large = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  /// Defaults to [foreground].
  final Color? iconColor;

  /// Uses the 13px label style instead of the 11px one.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = (large ? text.labelMedium : text.labelSmall)!.copyWith(
      color: foreground,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: large ? 16 : 14, color: iconColor ?? foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A coloured disc holding an icon, used for avatars and list bullets.
class IconDisc extends StatelessWidget {
  const IconDisc({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 40,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.55, color: foreground),
    );
  }
}
