import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:testfire/fire_midi.dart';
import 'package:testfire/sequencer.dart';

import 'fire_control.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeqFire',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'SeqFire'),
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
  final MonoCanvas oledBitmap = MonoCanvas(128, 64);
  late final fire = FireDevice(_midiDataListener);
  final sequencer = Sequencer();
  late final transport = Transport(sequencer, _onStop);
  late final tracks = TrackController(sequencer);

  void _midiDataListener(MidiPacket packet) {
    transport.onMidiEvent(fire, packet.data[0], packet.data[1], packet.data[2]);
    tracks.onMidiEvent(fire, packet.data[0], packet.data[1], packet.data[2]);
  }

  void _onStop() => tracks.reset(fire);

  @override
  void initState() {
    super.initState();
    sequencer.listen((signal) {
      //print('seq: $signal [${sequencer.step}]');

      if (sequencer.state != ControlState.READY) {
        tracks.step(fire, sequencer.step);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    fire.disconnectDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextButton(
              onPressed: fire.sendAllOff,
              child: Text('ALL OFF'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fire.disconnectDevice();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
