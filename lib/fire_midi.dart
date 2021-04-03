import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';

const _aBitMutate = [
  [13, 19, 25, 31, 37, 43, 49],
  [0, 20, 26, 32, 38, 44, 50],
  [1, 7, 27, 33, 39, 45, 51],
  [2, 8, 14, 34, 40, 46, 52],
  [3, 9, 15, 21, 41, 47, 53],
  [4, 10, 16, 22, 28, 48, 54],
  [5, 11, 17, 23, 29, 35, 55],
  [6, 12, 18, 24, 30, 36, 42],
];

Uint8List _aOLEDBitmap = Uint8List(1175);

/// Plot pixel on bitmap.
/// X - X coordinate of pixel (0..127).
/// Y - Y coordinate of pixel (0..63).
/// C - Color, 0=black, nonzero=white.
/// ref: https://blog.segger.com/decoding-the-akai-fire-part-3/
void _plotPixel(int X, int Y, int C) {
  int remapBit;
  //
  if (X < 128 && Y < 64) {
    //
    // Unwind 128x64 arrangement into a 1024x8 arrangement of pixels.
    //
    X += 128 * (Y ~/ 8);
    Y %= 8;

    //
    // Remap by tiling 7x8 block of translated pixels.
    //
    remapBit = _aBitMutate[Y][X % 7];
    if (C > 0) {
      _aOLEDBitmap[4 + X ~/ 7 * 8 + remapBit ~/ 7] |= 1 << (remapBit % 7);
    } else {
      _aOLEDBitmap[4 + X ~/ 7 * 8 + remapBit ~/ 7] &= ~(1 << (remapBit % 7));
    }
  }
}

void sendSysexBitmap(MidiCommand midiCmd, List<bool> boolMap) {
  final bitmap = _aOLEDBitmap;
  // these need to go after the bitmap length high/low bytes
  // but need to be included in the payload length, hence we just
  // put them at the start of the sent "bitmap" payload
  _aOLEDBitmap[0] = 0x00;
  _aOLEDBitmap[1] = 0x07;
  _aOLEDBitmap[2] = 0x00;
  _aOLEDBitmap[3] = 0x7f;

  // Clear the screen
  int x = 0;
  int y = 0;
  for (x = 0; x < 128; ++x) {
    for (y = 0; y < 64; ++y) {
      _plotPixel(x, y, 0);
    }
  }

  x = 0;
  y = 0;
  for (x = 0; x < 128; ++x) {
    for (y = 0; y < 64; ++y) {
      final pxl = boolMap[x + (y * 128)] ? 1 : 0;
      _plotPixel(x, y, pxl);
    }
  }

  Uint8List length = Uint8List.fromList([bitmap.length]);

  final Uint8List sysexHeader = Uint8List.fromList([
    0xF0, // System Exclusive
    0x47, // Akai Manufacturer ID
    0x7F, // The All-Call address
    0x43, // “Fire” product
    0x0E, // “Write OLED” command
    //(length[0] >> 7), // Payload length high
    0x09,
    (length[0] & 0x7F), // Payload length low
  ]);

  final Uint8List sysexFooter = Uint8List.fromList([
    0xF7, // End of Exclusive
  ]);

  final b = BytesBuilder();
  b.add(sysexHeader);
  b.add(bitmap);
  b.add(sysexFooter);

  final midiData = b.toBytes();

  midiCmd.sendData(Uint8List.fromList(midiData));
}

//debug: write out bytes sent in sysex cmd to a sysex file
void _debugSysexToFile(Uint8List midiData) {
  File testout = File('testfire1.sysex');
  testout.writeAsBytes(midiData);
}
