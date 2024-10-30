import 'package:flutter/material.dart';

class Chip8Painter extends CustomPainter {
  final List<int> display;
  final int screenWidth;
  final int screenHeight;
  final double pixelSize;

  Chip8Painter(
      this.display, this.screenWidth, this.screenHeight, this.pixelSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.red;

    for (int y = 0; y < screenHeight; y++) {
      for (int x = 0; x < screenWidth; x++) {
        if (display[y * screenWidth + x] == 1) {
          final Rect pixelRect = Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          );
          canvas.drawRect(pixelRect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
