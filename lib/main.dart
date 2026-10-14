import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The design is portrait-only. The Android manifest and the iOS Info.plist
  // say the same, so the app never starts sideways either.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Nunito Sans is bundled under the SIL Open Font License, which asks for
  // the licence to travel with the font.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['Nunito Sans'], license);
  });

  runApp(const ProviderScope(child: TicTacToeInfinityApp()));
}
