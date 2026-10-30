import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Gorev Zamanlayici ile Windows acilisinda baslatildiysa pencereyi gostermeden tepside basla.
  final autostarted = args.contains('--autostart');
  const options = WindowOptions(
    size: Size(400, 720),
    minimumSize: Size(380, 600),
    center: true,
    title: 'phevy',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: C.surface,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    if (!autostarted) {
      await windowManager.show();
      await windowManager.focus();
    }
  });

  final app = AppController();
  await app.init();
  runApp(PhevyApp(app: app));
}
