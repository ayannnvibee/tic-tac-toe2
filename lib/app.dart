import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

class TicTacToeInfinityApp extends StatelessWidget {
  const TicTacToeInfinityApp({super.key});

  static const String title = 'Tic Tac Toe Infinity';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: AppTheme.light,
      initialRoute: HomeScreen.routeName,
      routes: <String, WidgetBuilder>{
        HomeScreen.routeName: (BuildContext context) => const HomeScreen(),
      },
    );
  }
}
