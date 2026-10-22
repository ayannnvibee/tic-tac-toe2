import 'package:flutter/material.dart';

import 'ui/screens/consent_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/how_to_play_screen.dart';
import 'ui/screens/legal_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

class TicTacToeInfinityApp extends StatelessWidget {
  const TicTacToeInfinityApp({
    super.key,
    this.themeMode = ThemeMode.system,
    this.showConsent = false,
    this.showIntro = false,
  });

  static const String title = 'Tic Tac Toe Infinity';

  /// Follows the device setting unless a test pins it.
  final ThemeMode themeMode;

  /// Opens on the consent screen: on the very first launch, and again when
  /// the Privacy Policy or Terms of Use change. It leads on to the intro.
  final bool showConsent;

  /// Opens on the intro instead of Home: only on the very first launch.
  final bool showIntro;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: showConsent
          ? ConsentScreen.routeName
          : (showIntro ? OnboardingScreen.routeName : HomeScreen.routeName),
      routes: <String, WidgetBuilder>{
        HomeScreen.routeName: (BuildContext context) => const HomeScreen(),
        HowToPlayScreen.routeName: (BuildContext context) =>
            const HowToPlayScreen(),
        GameScreen.routeName: (BuildContext context) => const GameScreen(),
        OnboardingScreen.routeName: (BuildContext context) =>
            const OnboardingScreen(),
        ConsentScreen.routeName: (BuildContext context) =>
            const ConsentScreen(),
        LegalScreen.routeName: (BuildContext context) => LegalScreen(
          document:
              ModalRoute.of(context)!.settings.arguments as LegalDocument? ??
              LegalDocument.privacyPolicy,
        ),
      },
    );
  }
}
