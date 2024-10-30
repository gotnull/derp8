import 'dart:async';
import 'package:flutter/material.dart';
import 'chip8.dart';
import 'lcd.dart';

class Chip8Screen extends StatefulWidget {
  final Chip8 chip8;

  const Chip8Screen(this.chip8, {super.key});

  @override
  Chip8ScreenState createState() => Chip8ScreenState();
}

class Chip8ScreenState extends State<Chip8Screen> {
  final int screenWidth = 64;
  final int screenHeight = 32;
  final double pixelSize = 5.0;
  bool isRomLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _testPattern() async {
    for (int y = 0; y < screenHeight; y++) {
      for (int x = 0; x < screenWidth; x++) {
        widget.chip8.display[y * screenWidth + x] =
            ((x % 2 == 0) && (y % 2 == 0)) ? 1 : 0;
      }
    }
    setState(() {
      isRomLoaded = true;
    });
  }

  Future<void> _startEmulation() async {
    // Emulation loop that runs at ~60Hz
    while (isRomLoaded && mounted) {
      setState(() {
        widget.chip8.emulateCycle();
      });
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<void> _loadRomAndStartEmulation() async {
    await widget.chip8.loadRom(); // Load the ROM

    if (mounted) {
      setState(() {
        isRomLoaded = true;
      });
      _startEmulation(); // Start the emulation loop
    }
  }

  @override
  void dispose() {
    isRomLoaded = false; // Stop emulation loop
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DERP-8 Emulator"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _testPattern,
              child: const Text("Test Display Pattern"),
            ),
            ElevatedButton(
              onPressed: _loadRomAndStartEmulation,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text("Load ROM"),
              ),
            ),
            const SizedBox(height: 20),
            if (isRomLoaded)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: screenWidth * pixelSize,
                  height: screenHeight * pixelSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: CustomPaint(
                    painter: Chip8Painter(
                      widget.chip8.display,
                      screenWidth,
                      screenHeight,
                      pixelSize,
                    ),
                  ),
                ),
              )
            else
              const Text("Please load a ROM to start the emulator"),
          ],
        ),
      ),
    );
  }
}
