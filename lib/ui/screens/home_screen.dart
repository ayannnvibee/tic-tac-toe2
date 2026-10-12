import 'package:flutter/material.dart';

import '../../app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          TicTacToeInfinityApp.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
