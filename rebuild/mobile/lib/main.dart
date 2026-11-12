import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.restore();
  runApp(const AmiTrackApp());
}

class AmiTrackApp extends StatelessWidget {
  const AmiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1020);
    const surface = Color(0xFF151D32);
    return MaterialApp(
      title: 'Ami-Track',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C8CFF),
          brightness: Brightness.dark,
          surface: surface,
        ),
        cardTheme: const CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        dividerColor: Colors.white12,
      ),
      home: const HomeShell(),
    );
  }
}
