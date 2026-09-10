import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/api_client.dart';
import 'screens/shell.dart';
import 'state/contest_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final contest = ContestController(api: ApiClient());
  try {
    await contest.load();
  } catch (_) {
    contest.ready = true;
  }
  runApp(ConcoursApp(controller: contest));
}

class ConcoursApp extends StatelessWidget {
  const ConcoursApp({super.key, required this.controller});

  final ContestController controller;

  @override
  Widget build(BuildContext context) {
    return ContestScope(
      controller: controller,
      child: MaterialApp(
        title: 'Jury Concours',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}
