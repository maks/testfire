import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<String>? _setupSubscription;
  StreamSubscription<MidiPacket>? _dataSubscription;
  MidiCommand _midiCommand = MidiCommand();

  MidiDevice? connectedDevice;

  @override
  void initState() {
    super.initState();

    _listDevices();

    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) {
      print("setup changed $data");

      switch (data) {
        case "deviceFound":
          print('found: $data');
          setState(() {});
          break;
        // case "deviceOpened":
        //   break;
        default:
          print("Unhandled setup change: $data");
          break;
      }
    });

    _dataSubscription = _midiCommand.onMidiDataReceived?.listen((packet) {
      print("MIDI data: $packet");
      for (var d in packet.data) {
        print('midi data:$d');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    disconnect();
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
          connectedDevice = d;
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

  void sendTestBitmap() async {
    sendSysexBitmap(_midiCommand, _aOLEDBitmap);
  }

  void sendCheckersOLED() async {
    final f = File('../sysex/MIDI_FIRE_Sysex_CheckerBitmap.syx');
    print('ex: ${await f.exists()}');
    final midiData = await f.readAsBytes();

    _midiCommand.sendData(Uint8List.fromList(midiData));
  }

  void sendOffOLED() async {
    final f = File('../sysex/MIDI_FIRE_Sysex_AllBlackBitmap.syx');
    print('ex: ${await f.exists()}');
    final midiData = await f.readAsBytes();

    _midiCommand.sendData(Uint8List.fromList(midiData));
  }

  void disconnect() {
    final d = connectedDevice;
    if (d != null) {
      _midiCommand.disconnectDevice(d);
      print('DISCONNECTED ${d.id} ${d.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: sendAllOff,
              child: Text('ALL OFF'),
            ),
            TextButton(
              onPressed: sendAllOn,
              child: Text('ALL ON'),
            ),
            TextButton(
              onPressed: sendTestBitmap,
              child: Text('BITMAP'),
            ),
            TextButton(
              onPressed: sendCheckersOLED,
              child: Text('Checkers'),
            ),
            TextButton(
              onPressed: sendOffOLED,
              child: Text('OLED OFF'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          disconnect();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

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

void sendSysexBitmap(MidiCommand midiCmd, Uint8List bitmap) {
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
      if (y < 13 || y > 28) {
        _plotPixel(x, y, 1);
      }
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

  File testout = File('testfire1.sysex');
  testout.writeAsBytes(midiData);

  midiCmd.sendData(Uint8List.fromList(midiData));
}
