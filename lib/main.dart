import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'state/game_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ArrowEscapeApp());
}

class ArrowEscapeApp extends StatefulWidget {
  const ArrowEscapeApp({super.key});

  @override
  State<ArrowEscapeApp> createState() => _ArrowEscapeAppState();
}

class _ArrowEscapeAppState extends State<ArrowEscapeApp> {
  final GameState _state = GameState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GameScope rebuilds dependents whenever GameState notifies.
    return GameScope(
      state: _state,
      child: MaterialApp(
        title: 'Arrow Escape',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        // Clamp the OS text-scale so very large/small accessibility settings
        // still honour the user's preference without shattering layouts.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
