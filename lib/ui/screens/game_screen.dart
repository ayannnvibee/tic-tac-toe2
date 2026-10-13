import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../state/state.dart';
import '../theme/app_spacing.dart';
import '../widgets/board_view.dart';
import '../widgets/result_overlay.dart';
import '../widgets/score_board.dart';
import '../widgets/tactile.dart';

/// The match: header, scoreboard, board and New Game, with the round result
/// shown over the finished board. All behaviour lives in [GameController].
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  /// The tip card is dropped on screens shorter than this to leave the board
  /// as much room as possible.
  static const double _tipMinHeight = 700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final boardSize = ref.watch(boardSizeProvider);
    final winLength = ref.watch(winLengthProvider);
    final score = ref.watch(scoreProvider);
    final turnLabel = ref.watch(turnLabelProvider);

    final round = state.session.round;
    final result = state.pendingResult;
    final tone = result != null
        ? TurnTone.result
        : (state.isAiThinking || round.currentTurn == Player.computer
              ? TurnTone.computer
              : TurnTone.human);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: Column(
                      children: [
                        _Header(
                          boardSize: boardSize,
                          winLength: winLength,
                          soundEnabled: state.soundEnabled,
                          onBack: () => Navigator.of(context).maybePop(),
                          onToggleSound: controller.toggleSound,
                        ),
                        ScoreBoard(
                          humanWins: score.humanWins,
                          computerWins: score.computerWins,
                          turnLabel: turnLabel,
                          tone: tone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: BoardView(
                            board: round.board,
                            winningLine: round.winningLine,
                            onCellTap: controller.onCellTapped,
                          ),
                        ),
                        if (constraints.maxHeight >= _tipMinHeight) ...[
                          const SizedBox(height: AppSpacing.md),
                          _TipCard(boardSize: boardSize, winLength: winLength),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: PillButton(
                            key: const ValueKey('new-game'),
                            label: 'NEW GAME',
                            icon: Icons.refresh,
                            filled: true,
                            onPressed: controller.newGame,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (result != null)
            Positioned.fill(
              child: ResultOverlay(
                result: result,
                boardSize: boardSize,
                onContinue: controller.continueToNextRound,
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.boardSize,
    required this.winLength,
    required this.soundEnabled,
    required this.onBack,
    required this.onToggleSound,
  });

  final int boardSize;
  final int winLength;
  final bool soundEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Back to home',
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$boardSize × $boardSize',
                  key: const ValueKey('board-size'),
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  'Get $winLength in a row',
                  key: const ValueKey('win-length'),
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          RoundIconButton(
            key: const ValueKey('game-sound-toggle'),
            icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
            tooltip: soundEnabled ? 'Turn sound off' : 'Turn sound on',
            iconColor: soundEnabled ? scheme.primary : scheme.outline,
            onPressed: onToggleSound,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.boardSize, required this.winLength});

  final int boardSize;
  final int winLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final next = boardSize + 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryFixed.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            IconDisc(
              icon: Icons.lightbulb_outline,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get $winLength in a row to unlock the $next×$next board!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'A draw starts over at 3×3',
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
    );
  }
}
