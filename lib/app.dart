import 'package:flutter/material.dart';

import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/how_to_play_screen.dart';
import 'ui/theme/app_theme.dart';

class TicTacToeInfinityApp extends StatelessWidget {
  const TicTacToeInfinityApp({super.key, this.themeMode = ThemeMode.system});

  static const String title = 'Tic Tac Toe Infinity';

  /// Follows the device setting unless a test pins it.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: HomeScreen.routeName,
      routes: <String, WidgetBuilder>{
        HomeScreen.routeName: (BuildContext context) => const HomeScreen(),
        HowToPlayScreen.routeName: (BuildContext context) =>
            const HowToPlayScreen(),
        GameScreen.routeName: (BuildContext context) => const GameScreen(),
      },
    );
  }
}
