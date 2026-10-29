import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/ad_service.dart';
import 'services/fx.dart';
import 'services/progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final progress = await Progress.load();
  Fx.instance.attach(progress);
  runApp(ArrowdriftApp(progress: progress));

  // Start ads (consent -> SDK init) after the first frame so launch stays fast.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService.instance.init();
  });
}
