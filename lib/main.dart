import 'dart:async';
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
  int _counter = 0;
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
        print('d:$d');
      }
    });
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
