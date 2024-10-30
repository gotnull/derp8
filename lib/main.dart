import 'package:derp8/screen.dart';
import 'package:derp8/chip8.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Set the minimum window size before running the app
  await setWindowSize();

  // Set the window title
  windowManager.setTitle('DERP-8');

  runApp(const Derp8());
}

Future<void> setWindowSize() async {
  await windowManager.setMinimumSize(const Size(1300, 900));
  await windowManager.setSize(const Size(1300, 900));
}

class Derp8 extends StatelessWidget {
  const Derp8({super.key});

  @override
  Widget build(BuildContext context) {
    final chip8 = Chip8(); // Initialize Chip8 instance

    return MaterialApp(
      title: 'DERP-8',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Chip8Screen(chip8), // Pass chip8.display to Chip8Screen
      debugShowCheckedModeBanner: false,
    );
  }
}
