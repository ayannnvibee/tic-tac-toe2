import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/app.dart';
import 'package:tic_tac_toe_infinity/domain/domain.dart';
import 'package:tic_tac_toe_infinity/state/state.dart';

import '../state/fake_ai.dart';

export '../state/fake_ai.dart';

/// A typical phone in portrait, in logical pixels.
const Size phoneSize = Size(390, 844);

/// Pumps the whole app with a scripted computer and no move delay.
Future<FakeAi> pumpApp(
  WidgetTester tester, {
  Size size = phoneSize,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  final ai = FakeAi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiMoveFunctionProvider.overrideWithValue(ai.call),
        aiMoveDelayProvider.overrideWithValue(Duration.zero),
        aiSeedRandomProvider.overrideWithValue(Random(1)),
      ],
      child: TicTacToeInfinityApp(themeMode: themeMode),
    ),
  );
  await tester.pumpAndSettle();
  return ai;
}

Finder cell(int row, int col) => find.byKey(ValueKey('cell-$row-$col'));
Finder xAt(int row, int col) => find.byKey(ValueKey('mark-x-$row-$col'));
Finder oAt(int row, int col) => find.byKey(ValueKey('mark-o-$row-$col'));

/// Every cell on the board, whatever its size.
Finder get allCells => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith('cell-');
});

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

extension AppActions on WidgetTester {
  Future<void> openGame() async {
    await tap(find.byKey(const ValueKey('play')));
    await pumpAndSettle();
  }

  /// Taps each cell in turn, letting the computer reply after each one.
  Future<void> tapCells(List<Position> cells) async {
    for (final position in cells) {
      await tap(cell(position.row, position.col));
      await pumpAndSettle();
    }
  }

  /// Plays a scripted round: the human taps [taps], the computer answers
  /// with [replies].
  Future<void> playRound(
    FakeAi ai,
    List<Position> taps,
    List<Position> replies,
  ) async {
    ai.script.addAll(replies);
    await tapCells(taps);
  }
}
