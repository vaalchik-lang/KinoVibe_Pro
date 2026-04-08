// main.dart — KinoVibe v3.0

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const KinoVibeApp());
}

class KinoVibeApp extends StatelessWidget {
  const KinoVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KinoVibe',
      debugShowCheckedModeBanner: false,
      theme: KinoTheme.dark,
      home: const HomeScreen(),
    );
  }
}
