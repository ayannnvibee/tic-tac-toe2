import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import '../../state/state.dart';
import '../theme/app_spacing.dart';
import '../widgets/board_view.dart';
import '../widgets/result_overlay.dart';
import '../widgets/score_board.dart';
import '../widgets/tactile.dart';

/// The match: header, scoreboard, board and New Game.
///
/// When a round ends a stroke is drawn across the winning cells, and then the
/// result card appears over the finished board. All game behaviour lives in
/// [GameController]; this screen only owns those two animations and the
/// background music, which plays only while this screen is open, the app is
/// in the foreground, music is switched on and no ad is showing.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  /// How long the stroke across the winning cells takes.
  static const Duration winLineDuration = Duration(milliseconds: 500);

  /// How long the old board takes to hand over to the new one.
  static const Duration boardChangeDuration = Duration(milliseconds: 320);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  /// The tip card is dropped on screens shorter than this to leave the board
  /// as much room as possible.
  static const double _tipMinHeight = 700;

  late final AnimationController _winLine = AnimationController(
    vsync: this,
    duration: GameScreen.winLineDuration,
  );

  /// Whether the result card is up. It follows the win line, so it is false
  /// for a moment after the round has ended.
  bool _cardVisible = false;

  late final MusicService _music = ref.read(musicServiceProvider);
  late final AppLifecycleListener _lifecycle;
  bool _musicPlaying = false;

  @override
  void initState() {
    super.initState();
    // Coming back to a round that already ended: no replay, just the card.
    if (ref.read(gameControllerProvider).pendingResult != null) {
      _winLine.value = 1;
      _cardVisible = true;
    }
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _syncMusic());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMusic());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    if (_musicPlaying) _music.pause();
    _winLine.dispose();
    super.dispose();
  }

  void _syncMusic() {
    if (!mounted) return;
    final state = ref.read(gameControllerProvider);
    final foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final shouldPlay = state.musicEnabled && !state.isShowingAd && foreground;
    if (shouldPlay == _musicPlaying) return;
    _musicPlaying = shouldPlay;
    if (shouldPlay) {
      _music.play();
    } else {
      _music.pause();
    }
  }

  void _onResultChanged(RoundStatus? previous, RoundStatus? next) {
    if (next == null) {
      // The line is left as it is: the old board still shows it while it
      // fades out, and the next round starts it again from zero.
      if (_cardVisible) setState(() => _cardVisible = false);
      return;
    }
    if (previous != null) return;

    final state = ref.read(gameControllerProvider);
    _announce(next, state.session.boardSize);

    final hasLine = state.session.round.winningLine != null;
    if (!hasLine || MediaQuery.disableAnimationsOf(context)) {
      _winLine.value = 1;
      setState(() => _cardVisible = true);
      return;
    }

    final roundId = state.roundId;
    _winLine.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      final now = ref.read(gameControllerProvider);
      // New Game may have been pressed while the line was being drawn.
      if (now.roundId == roundId && now.pendingResult != null) {
        setState(() => _cardVisible = true);
      }
    });
  }

  void _announce(RoundStatus result, int boardSize) {
    final outcome = switch (result) {
      RoundStatus.humanWon => TurnLabels.youWin,
      RoundStatus.computerWon => TurnLabels.computerWins,
      RoundStatus.draw || RoundStatus.inProgress => TurnLabels.draw,
    };
    SemanticsService.sendAnnouncement(
      View.of(context),
      '$outcome. ${ResultOverlay.subtitleFor(result, boardSize)}',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<(bool, bool)>(
      gameControllerProvider.select(
        (state) => (state.musicEnabled, state.isShowingAd),
      ),
      (_, _) => _syncMusic(),
    );
    ref.listen<RoundStatus?>(
      gameControllerProvider.select((state) => state.pendingResult),
      _onResultChanged,
    );

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

    // The cell the computer just played, so a zoomed board can pan to it.
    final lastMove = round.lastMove;
    final computerMove =
        lastMove != null && round.board.cellAt(lastMove) == Player.computer.mark
        ? lastMove
        : null;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget narrow(Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
      child: child,
    );

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMargin,
                ),
                child: Column(
                  children: [
                    narrow(
                      _Header(
                        boardSize: boardSize,
                        winLength: winLength,
                        soundEnabled: state.soundEnabled,
                        musicEnabled: state.musicEnabled,
                        onBack: () => Navigator.of(context).maybePop(),
                        onToggleSound: controller.toggleSound,
                        onToggleMusic: controller.toggleMusic,
                      ),
                    ),
                    narrow(
                      ScoreBoard(
                        humanWins: score.humanWins,
                        computerWins: score.computerWins,
                        turnLabel: turnLabel,
                        tone: tone,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // The board may use the full width, so a large board on a
                    // tablet keeps its 44dp cells without needing to zoom.
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : GameScreen.boardChangeDuration,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: BoardView(
                          // A new round swaps in a new board.
                          key: ValueKey('board-${state.roundId}'),
                          board: round.board,
                          winningLine: round.winningLine,
                          winLineProgress: _winLine,
                          focusCell: computerMove,
                          onCellTap: controller.onCellTapped,
                        ),
                      ),
                    ),
                    if (constraints.maxHeight >= _tipMinHeight) ...[
                      const SizedBox(height: AppSpacing.md),
                      narrow(
                        _TipCard(boardSize: boardSize, winLength: winLength),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    narrow(
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
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
          if (result != null && _cardVisible)
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: ref.watch(adServiceProvider).rewardedReady,
                builder: (context, rewardedReady, _) => ResultOverlay(
                  result: result,
                  boardSize: boardSize,
                  onContinue: controller.continueToNextRound,
                  // Offered only when an ad is ready to play right now.
                  onWatchAd:
                      rewardedReady &&
                          !state.isShowingAd &&
                          GameController.canContinueWithAd(result)
                      ? controller.watchAdToContinue
                      : null,
                ),
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
    required this.musicEnabled,
    required this.onBack,
    required this.onToggleSound,
    required this.onToggleMusic,
  });

  final int boardSize;
  final int winLength;
  final bool soundEnabled;
  final bool musicEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleMusic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // A minimum, not a fixed height, so large text has room to grow.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$boardSize × $boardSize',
                    key: const ValueKey('board-size'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                  Text(
                    'Get $winLength in a row',
                    key: const ValueKey('win-length'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            RoundIconButton(
              key: const ValueKey('game-music-toggle'),
              icon: musicEnabled ? Icons.music_note : Icons.music_off,
              tooltip: musicEnabled ? 'Turn music off' : 'Turn music on',
              iconColor: musicEnabled ? scheme.primary : scheme.outline,
              onPressed: onToggleMusic,
            ),
            const SizedBox(width: AppSpacing.xs),
            RoundIconButton(
              key: const ValueKey('game-sound-toggle'),
              icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
              tooltip: soundEnabled ? 'Turn sound off' : 'Turn sound on',
              iconColor: soundEnabled ? scheme.primary : scheme.outline,
              onPressed: onToggleSound,
            ),
          ],
        ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
