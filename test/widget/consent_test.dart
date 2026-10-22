import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/ui/screens/consent_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/home_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/legal_screen.dart';
import 'package:tic_tac_toe_infinity/ui/screens/onboarding_screen.dart';

import 'app_harness.dart';

final Finder _accept = find.byKey(const ValueKey('consent-accept'));
final Finder _checkbox = find.byKey(const ValueKey('consent-checkbox'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch: consent, then the intro, then Home', (
    tester,
  ) async {
    final store = FakeOnboardingStore(seen: false, legalVersion: 0);
    await pumpApp(tester, intro: store, showConsent: true, showIntro: true);

    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.text('Before you play'), findsOneWidget);

    // Agreeing is required: the button does nothing until the box is ticked.
    await _tap(tester, _accept);
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(store.legalVersion, 0);

    await _tap(tester, _checkbox);
    await _tap(tester, _accept);
    expect(store.legalVersion, LegalInfo.version);
    expect(find.byType(ConsentScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('onboarding-skip')));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('consent after an update skips the intro already seen', (
    tester,
  ) async {
    final store = FakeOnboardingStore(seen: true, legalVersion: 0);
    await pumpApp(tester, intro: store, showConsent: true);

    await _tap(tester, _checkbox);
    await _tap(tester, _accept);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('the consent screen opens both documents and comes back', (
    tester,
  ) async {
    await pumpApp(tester, showConsent: true);

    await _tap(tester, find.byKey(const ValueKey('consent-privacy')));
    expect(find.byType(LegalScreen), findsOneWidget);
    expect(textOf(tester, 'legal-title'), 'Privacy Policy');
    expect(find.text('Advertising'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ConsentScreen), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('consent-terms')));
    expect(textOf(tester, 'legal-title'), 'Terms of Use');
    expect(find.text('No warranty'), findsOneWidget);
  });

  testWidgets('later launches skip consent', (tester) async {
    await pumpApp(tester);
    expect(find.byType(ConsentScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Settings has the Privacy Policy and Terms of Use', (
    tester,
  ) async {
    await pumpApp(tester);
    await _tap(tester, find.byKey(const ValueKey('how-to-play')));
    await _tap(tester, find.byKey(const ValueKey('tab-controls')));

    await _tap(tester, find.byKey(const ValueKey('settings-privacy')));
    expect(textOf(tester, 'legal-title'), 'Privacy Policy');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('settings-terms')));
    expect(textOf(tester, 'legal-title'), 'Terms of Use');
  });

  for (final size in const [smallPhone, tallPhone]) {
    testWidgets('consent and documents fit at 200% text on '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, size: size, showConsent: true);
      expect(tester.takeException(), isNull);
      expect(_accept, findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('consent-privacy')));
      expect(tester.takeException(), isNull);
    });
  }
}
