import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ui/screens/home_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/how_to_play_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/onboarding_screen.dart';

import 'app_harness.dart';

final Finder _next = find.byKey(const ValueKey('onboarding-next'));
final Finder _done = find.byKey(const ValueKey('onboarding-done'));
final Finder _skip = find.byKey(const ValueKey('onboarding-skip'));

void main() {
  testWidgets('first launch: three pages, then Home, and it is remembered', (
    tester,
  ) async {
    final intro = FakeOnboardingStore(seen: false);
    await pumpApp(tester, intro: intro, showIntro: true);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.textContaining('Welcome to'), findsOneWidget);

    await tester.tap(_next);
    await tester.pumpAndSettle();
    expect(find.text('Win to grow the board'), findsOneWidget);

    await tester.tap(_next);
    await tester.pumpAndSettle();
    expect(find.text('Lose or draw?'), findsOneWidget);
    expect(_next, findsNothing);
    expect(find.text("LET'S PLAY"), findsOneWidget);

    await tester.tap(_done);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(intro.seen, isTrue);
    expect(intro.marks, 1);

    // Home is the root now: there is no way back into the intro.
    expect(
      Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('pages can be swiped', (tester) async {
    await pumpApp(tester, showIntro: true);
    await tester.drag(
      find.byKey(const ValueKey('onboarding-pages')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Win to grow the board'), findsOneWidget);
  });

  testWidgets('skip goes straight to Home and is remembered', (tester) async {
    final intro = FakeOnboardingStore(seen: false);
    await pumpApp(tester, intro: intro, showIntro: true);

    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(intro.seen, isTrue);
  });

  testWidgets('later launches open on Home', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the guide can show the intro again and comes back to it', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('how-to-play')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('show-intro')));
    await tester.tap(find.byKey(const ValueKey('show-intro')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(_skip);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HowToPlayScreen), findsOneWidget);
  });

  for (final size in const [smallPhone, tallPhone]) {
    testWidgets('every page fits at 200% text on '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, size: size, showIntro: true);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 2; i++) {
        await tester.tap(_next);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(_done, findsOneWidget);
    });
  }
}
