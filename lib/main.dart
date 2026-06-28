import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio_service.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'state/game_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AudioService.instance.init();
  runApp(const BubblePopApp());
}

class BubblePopApp extends StatefulWidget {
  const BubblePopApp({super.key});

  @override
  State<BubblePopApp> createState() => _BubblePopAppState();
}

class _BubblePopAppState extends State<BubblePopApp> {
  final GameState _state = GameState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      state: _state,
      child: MaterialApp(
        title: 'Bubble Pop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.2,
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
