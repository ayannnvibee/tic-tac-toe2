import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_infinity/app.dart';

void main() {
  testWidgets('Home screen shows the game title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TicTacToeInfinityApp()),
    );

    expect(find.text('Tic Tac Toe Infinity'), findsOneWidget);
  });
}
