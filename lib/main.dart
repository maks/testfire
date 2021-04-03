import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:oled_font_57/oled_font_57.dart' as font57;

import 'fire_midi.dart';
import 'oled_painter.dart';

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

  final MonoCanvas oledBitmap = MonoCanvas(128, 64);

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
  }

  void disconnectDevice() {
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
    sendSysexBitmap(_midiCommand, oledBitmap.data);
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
    // oledBitmap.drawLine(5, 5, 50, 50, true);
    final font = Font(
      monospace: font57.monospace,
      width: font57.width,
      height: font57.height,
      fontData: font57.fontData,
      lookup: font57.lookup,
    );
    oledBitmap.writeString(font, 1, 'hello fire', true, true, 1);
    oledBitmap.setCursor(0, 10);
    oledBitmap.writeString(font, 2, 'Large Font', true, true, 1);
    oledBitmap.setCursor(0, 27);
    oledBitmap.writeString(font, 3, 'ABCD', true, true, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 128,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: CustomPaint(
                  painter: OLEDPainter(oledBitmap.data),
                ),
              ),
            ),
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
