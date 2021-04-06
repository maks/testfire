import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';

abstract class ControllerDevice {}

class PadColor {
  final int r;
  final int g;
  final int b;

  PadColor(this.r, this.g, this.b);

  factory PadColor.off() => PadColor(0, 0, 0);
}

class FireDevice implements ControllerDevice {
  MidiCommand _midiCommand = MidiCommand();

  MidiDevice? _connectedDevice;

  int _unhandledCount = 0;

  StreamSubscription<String>? _setupSubscription;
  StreamSubscription<MidiPacket>? _dataSubscription;

  final Function(MidiPacket) onMidiData;

  static const _aBitMutate = [
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

  FireDevice(this.onMidiData) {
    connectDevice();
  }

  void connectDevice() {
    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) {
      print("setup changed $data");

      switch (data) {
        case "deviceFound":
          print('found: $data');
          break;
        case "deviceOpened":
          print('device opened: $data');
          break;
        case "deviceConnected":
          print('device connected: $data');
          // clear fire for action
          sendAllOff();
          print('clear fire');
          break;
        default:
          print("Unhandled setup change: $data");
          if (_unhandledCount++ > 5) {
            _unhandledCount = 0;
            disconnectDevice();
          }
          break;
      }
    });

    _dataSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      print('midi data:${packet.data}');
      onMidiData(packet);
    });

    _listDevices();
  }

  void disconnectDevice() {
    _disconnect();
    _dataSubscription?.cancel();
    _setupSubscription?.cancel();
  }

  void _listDevices() async {
    final devices = await _midiCommand.devices;

    if (devices != null) {
      for (var d in devices) {
        print('MIDI DEVICE: [${d.id}] "${d.name}" ${d.inputPorts}');

        if (d.name == 'FL STUDIO FIRE') {
          print('connect to device: ${d.id} ${d.name}');
          _midiCommand.connectToDevice(d);
          _connectedDevice = d;
        }
      }
    } else {
      print('NULL devices');
    }
  }

  void sendAllOff() {
    print('sending all OFF to:');
    _midiCommand.sendData(Uint8List.fromList([0xB0, 0x7F, 0]));
  }

  void sendAllOn() {
    print('sending all ON to:');
    _midiCommand.sendData(Uint8List.fromList([0xB0, 0x7F, 1]));
  }

  void sendBitmap(List<bool> bitmap) async {
    _sendSysexBitmap(_midiCommand, bitmap);
  }

  void colorPad(int padRow, int padColumn, PadColor color) {
    final Uint8List sysexHeader = Uint8List.fromList([
      0xF0, // System Exclusive
      0x47, // Akai Manufacturer ID
      0x7F, // The All-Call address
      0x43, // “Fire” product
      0x65, // Write LED cmd
      0x00, // mesg length - high byte
      0x04, // mesg length - low byte
    ]);
    final Uint8List sysexFooter = Uint8List.fromList([
      0xF7, // End of Exclusive
    ]);

    final Uint8List ledData = Uint8List.fromList([
      (padRow * 16 + padColumn),
      color.r,
      color.g,
      color.b,
    ]);

    final b = BytesBuilder();
    b.add(sysexHeader);
    b.add(ledData);
    b.add(sysexFooter);

    final midiData = b.toBytes();

    _midiCommand.sendData(Uint8List.fromList(midiData));
  }

  void allPadsColor(PadColor color) {
    final Uint8List sysexHeader = Uint8List.fromList([
      0xF0, // System Exclusive
      0x47, // Akai Manufacturer ID
      0x7F, // The All-Call address
      0x43, // “Fire” product
      0x65, // Write LED cmd
      0x02, // mesg length - high byte
      0x00, // mesg length - low byte
    ]);
    final Uint8List sysexFooter = Uint8List.fromList([
      0xF7, // End of Exclusive
    ]);

    final b = BytesBuilder();
    b.add(sysexHeader);

    for (int idx = 0; idx < 64; idx++) {
      final Uint8List ledData = Uint8List.fromList([
        idx,
        color.r,
        color.g,
        color.b,
      ]);
      b.add(ledData);
    }

    b.add(sysexFooter);

    final midiData = b.toBytes();
    _midiCommand.sendData(Uint8List.fromList(midiData));
  }

  void sendMidi(Uint8List ccData) {
    _midiCommand.sendData(Uint8List.fromList(ccData));
  }

  void _disconnect() {
    final d = _connectedDevice;
    if (d != null) {
      _midiCommand.disconnectDevice(d);
      print('DISCONNECTED ${d.id} ${d.name}');
    }
  }

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

  void _sendSysexBitmap(MidiCommand midiCmd, List<bool> boolMap) {
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

  /// debug: write out bytes sent in sysex cmd to a sysex file
  // ignore: unused_element
  void _debugSysexToFile(Uint8List midiData) {
    File testout = File('testfire1.sysex');
    testout.writeAsBytes(midiData);
  }
}

class SmokeDevice implements ControllerDevice {}

class IndicatorLED {
  // Midi Controller IDs on the Fire
  static const _rectLEDControllerID = [0x28, 0x29, 0x2A, 0x2B];

  static const _rectLEDValues = [
    0x0, // Off
    0x01, // Pale Red
    0x02, // Pale Green
    0x03, // Bright Red
    0x04, // Bright Green
  ];

  // index: 0-4
  static Uint8List red(int index, {bool pale = false}) {
    return Uint8List.fromList([
      0xB0, // midi control change code
      _rectLEDControllerID[index],
      pale ? _rectLEDValues[1] : _rectLEDValues[3],
    ]);
  }

  static Uint8List green(int index, {bool pale = false}) {
    return Uint8List.fromList([
      0xB0, // midi control change code
      _rectLEDControllerID[index],
      pale ? _rectLEDValues[2] : _rectLEDValues[4],
    ]);
  }

  static Uint8List off(int index) {
    return Uint8List.fromList([
      0xB0, // midi control change code
      _rectLEDControllerID[index],
      _rectLEDValues[0],
    ]);
  }
}

class ControlBankLED {
  static Uint8List off() {
    return Uint8List.fromList([
      0xB0, // midi control change code
      0x1B,
      0,
    ]);
  }

  static Uint8List on({
    bool channel = false,
    bool mixer = false,
    bool user1 = false,
    bool user2 = false,
  }) {
    final value = Uint8List(1);
    value[0] = 0x10;

    if (channel) {
      value[0] = value[0] | 0x01;
    }
    if (mixer) {
      value[0] = value[0] | 0x02;
    }
    if (user1) {
      value[0] = value[0] | 0x04;
    }
    if (user2) {
      value[0] = value[0] | 0x08;
    }

    return Uint8List.fromList([
      0xB0, // midi control change code
      0x1B,
      value[0],
    ]);
  }
}

class CCInputs {
  static const buttonDown = 144;
  static const buttonUp = 128;
  static const dialRotate = 176;

  static const rotateLeft = 127;
  static const rotateRight = 1;

  static const volume = 16;
  static const pan = 17;
  static const filter = 18;
  static const resonance = 19;

  static const selectDown = 25;
  static const bankSelect = 26;

  static const patternUp = 31;
  static const patternDown = 32;
  static const browser = 33;
  static const gridLeft = 34;
  static const gridRight = 35;

  static const muteButton1 = 36;
  static const muteButton2 = 37;
  static const muteButton3 = 38;
  static const muteButton4 = 39;

  static const step = 44;
  static const note = 45;
  static const drum = 46;
  static const perform = 47;
  static const shift = 48;
  static const alt = 49;
  static const pattern = 50;

  static const play = 51;
  static const stop = 52;
  static const record = 53;

  static const select = 118;

  // All
  static const off = 0;

  // Red Only
  // pattern up/down, browser, grid left/right
  static const paleRed = 1;
  static const red = 2;

  // Green only
  // mute 1,2,3,4
  static const paleGreen = 1;
  static const green = 2;

  // Yellow only
  // alt, stop
  static const paleYellow = 1;
  static const yellow = 2;

  // Yellow-Red
  // step, note, drum, perform, shift, record
  static const paleYellow2 = 1;
  static const paleRed2 = 2;
  static const yellow2 = 3;
  static const red2 = 4;

  // Yellow-Green
  // pattern, play
  static const paleGreen3 = 1;
  static const paleYellow3 = 2;
  static const green3 = 3;
  static const yellow3 = 4;

  static Uint8List on(int id, int value) {
    return Uint8List.fromList([
      0xB0, // midi control change code
      id,
      value,
    ]);
  }
}

class PadInput {
  static const noteDown = 144;
  static const noteUp = 128;

  static const baseId = 54;
  static const endId = 117;

  static const padsPerRow = 16;

  static bool isPadDown(int cmd, int id, int value) =>
      (cmd == noteDown) && (id >= baseId) && (id <= endId);

  final row;
  final column;

  PadInput(this.row, this.column);

  factory PadInput.fromMidi(int id) {
    final offset = id - 54;
    if (offset > 63) {
      throw Exception('invalid pad id: $id');
    }
    return PadInput(offset ~/ padsPerRow, offset % padsPerRow);
  }

  String toString() => 'PadInput $row:$column';
}
