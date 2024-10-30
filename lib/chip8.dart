import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Chip8 {
  static const int memorySize = 4096;
  static const int programStart = 0x200;
  static const int numRegisters = 16;
  static const int stackSize = 16;
  static const int screenWidth = 64;
  static const int screenHeight = 32;

  final List<int> memory = List.filled(memorySize, 0);
  final List<int> v = List.filled(numRegisters, 0); // Registers V0 to VF
  int i = 0; // Index register
  int pc = programStart; // Program counter
  final List<int> stack = List.filled(stackSize, 0);
  int sp = 0; // Stack pointer
  final List<int> display = List.filled(screenWidth * screenHeight, 0);
  int delayTimer = 0;
  int soundTimer = 0;
  bool isRomLoaded = false;

  final List<bool> keys = List.filled(16, false);

  Chip8() {
    loadFonts();
  }

  Future<void> loadDebugRom(String path) async {
    // Try loading the asset
    ByteData romData = await rootBundle.load(path);

    // If successful, proceed with loading ROM
    Uint8List romBytes = romData.buffer.asUint8List();

    for (int i = 0; i < romBytes.length; i++) {
      memory[programStart + i] = romBytes[i];
    }

    if (romBytes.length + programStart > memory.length) {
      throw Exception("ROM size exceeds available memory.");
    }

    for (int i = 0; i < romBytes.length; i++) {
      memory[programStart + i] = romBytes[i];
    }

    if (kDebugMode) {
      print("ROM loaded successfully!");
    }
  }

  Future<void> loadRom() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose ROM',
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      Uint8List romBytes = result.files.single.bytes!;

      if (romBytes.length + programStart > memory.length) {
        throw Exception("ROM size exceeds available memory.");
      }

      for (int i = 0; i < romBytes.length; i++) {
        memory[programStart + i] = romBytes[i];
      }

      if (kDebugMode) {
        print("ROM loaded successfully!");
      }
    }
  }

  void reset() {
    memory.fillRange(0, memory.length, 0);
    v.fillRange(0, v.length, 0);
    i = 0;
    pc = programStart;
    stack.fillRange(0, stack.length, 0);
    sp = 0;
    display.fillRange(0, display.length, 0);
    delayTimer = 0;
    soundTimer = 0;
    isRomLoaded = false;
  }

  FutureOr<void> loadFonts() async {
    // Load font data into memory (usually from 0x050 to 0x09F)
    const fonts = [
      // Each font sprite is 5 bytes
      0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
      0x20, 0x60, 0x20, 0x20, 0x70, // 1
      0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
      0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
      // Add all font sprites for 0-F
    ];
    for (var i = 0; i < fonts.length; i++) {
      memory[0x050 + i] = fonts[i];
    }
  }

  void loadProgram(List<int> program) {
    for (int i = 0; i < program.length; i++) {
      memory[programStart + i] = program[i];
    }
  }

  void emulateCycle() {
    int opcode = (memory[pc] << 8) | memory[pc + 1];

    // print("Executing instruction: 0x${opcode.toRadixString(16)}");

    switch (opcode & 0xF000) {
      case 0x0000:
        switch (opcode & 0x00FF) {
          case 0x00E0:
            display.fillRange(0, display.length, 0);
            pc += 2;
            break;
          case 0x00EE:
            sp--;
            pc = stack[sp];
            pc += 2;
            break;
          default:
            pc += 2;
        }
        break;

      case 0x1000:
        pc = opcode & 0x0FFF;
        break;

      case 0x2000:
        stack[sp] = pc;
        sp++;
        pc = opcode & 0x0FFF;
        break;

      case 0x3000:
        if (v[(opcode & 0x0F00) >> 8] == (opcode & 0x00FF)) {
          pc += 4;
        } else {
          pc += 2;
        }
        break;

      case 0x4000:
        if (v[(opcode & 0x0F00) >> 8] != (opcode & 0x00FF)) {
          pc += 4;
        } else {
          pc += 2;
        }
        break;

      case 0x5000:
        if (v[(opcode & 0x0F00) >> 8] == v[(opcode & 0x00F0) >> 4]) {
          pc += 4;
        } else {
          pc += 2;
        }
        break;

      case 0x6000:
        v[(opcode & 0x0F00) >> 8] = opcode & 0x00FF;
        pc += 2;
        break;

      case 0x7000:
        v[(opcode & 0x0F00) >> 8] =
            (v[(opcode & 0x0F00) >> 8] + (opcode & 0x00FF)) & 0xFF;
        pc += 2;
        break;

      case 0x8000:
        int x = (opcode & 0x0F00) >> 8;
        int y = (opcode & 0x00F0) >> 4;
        switch (opcode & 0x000F) {
          case 0x0:
            v[x] = v[y];
            break;
          case 0x1:
            v[x] |= v[y];
            break;
          case 0x2:
            v[x] &= v[y];
            break;
          case 0x3:
            v[x] ^= v[y];
            break;
          case 0x4:
            v[0xF] = (v[x] + v[y]) > 0xFF ? 1 : 0;
            v[x] = (v[x] + v[y]) & 0xFF;
            break;
          case 0x5:
            v[0xF] = v[x] > v[y] ? 1 : 0;
            v[x] = (v[x] - v[y]) & 0xFF;
            break;
          case 0x6:
            v[0xF] = v[x] & 0x1;
            v[x] >>= 1;
            break;
          case 0x7:
            v[0xF] = v[y] > v[x] ? 1 : 0;
            v[x] = (v[y] - v[x]) & 0xFF;
            break;
          case 0xE:
            v[0xF] = (v[x] & 0x80) >> 7;
            v[x] = (v[x] << 1) & 0xFF;
            break;
        }
        pc += 2;
        break;

      case 0x9000:
        if (v[(opcode & 0x0F00) >> 8] != v[(opcode & 0x00F0) >> 4]) {
          pc += 4;
        } else {
          pc += 2;
        }
        break;

      case 0xA000:
        i = opcode & 0x0FFF;
        pc += 2;
        break;

      case 0xB000:
        pc = (opcode & 0x0FFF) + v[0];
        break;

      case 0xC000:
        v[(opcode & 0x0F00) >> 8] = (Random().nextInt(256)) & (opcode & 0x00FF);
        pc += 2;
        break;

      case 0xD000:
        int x = v[(opcode & 0x0F00) >> 8];
        int y = v[(opcode & 0x00F0) >> 4];
        int height = opcode & 0x000F;
        v[0xF] = 0;
        for (int yLine = 0; yLine < height; yLine++) {
          int pixel = memory[i + yLine];
          for (int xLine = 0; xLine < 8; xLine++) {
            if ((pixel & (0x80 >> xLine)) != 0) {
              int index = ((y + yLine) % screenHeight) * screenWidth +
                  ((x + xLine) % screenWidth);
              if (display[index] == 1) v[0xF] = 1;
              display[index] ^= 1;

              // Debug output for each pixel
              // print("Drawing pixel at ($x, $y): ${display[index]}");
            }
          }
        }
        pc += 2;
        break;

      case 0xE000:
        int x = (opcode & 0x0F00) >> 8;
        if ((opcode & 0x00FF) == 0x9E) {
          if (keys[v[x]]) {
            pc += 4;
          } else {
            pc += 2;
          }
        } else if ((opcode & 0x00FF) == 0xA1) {
          if (!keys[v[x]]) {
            pc += 4;
          } else {
            pc += 2;
          }
        }
        break;

      case 0xF000:
        int x = (opcode & 0x0F00) >> 8;
        switch (opcode & 0x00FF) {
          case 0x07:
            v[x] = delayTimer;
            break;
          case 0x0A:
            bool keyPressDetected = false;
            for (int i = 0; i < 16; i++) {
              if (keys[i]) {
                v[x] = i;
                keyPressDetected = true;
                break;
              }
            }
            if (!keyPressDetected) return;
            break;
          case 0x15:
            delayTimer = v[x];
            break;
          case 0x18:
            soundTimer = v[x];
            break;
          case 0x1E:
            i = (i + v[x]) & 0xFFFF;
            break;
          case 0x29:
            i = v[x] * 5;
            break;
          case 0x33:
            memory[i] = v[x] ~/ 100;
            memory[i + 1] = (v[x] ~/ 10) % 10;
            memory[i + 2] = v[x] % 10;
            break;
          case 0x55:
            for (int j = 0; j <= x; j++) {
              memory[i + j] = v[j];
            }
            break;
          case 0x65:
            for (int j = 0; j <= x; j++) {
              v[j] = memory[i + j];
            }
            break;
        }
        pc += 2;
        break;

      default:
        throw Exception("Unknown opcode: $opcode");
    }

    if (delayTimer > 0) delayTimer--;
    if (soundTimer > 0) soundTimer--;
  }
}
