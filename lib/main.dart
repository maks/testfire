import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:testfire/fire_control/screen.dart';
import 'package:testfire/fire_midi.dart';
import 'package:testfire/sequencer.dart';
import 'package:testfire/session/session_cubit.dart';

import 'fire_control/menu.dart';
import 'fire_control/tracks.dart';
import 'fire_control/transport.dart';
import 'session/session.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Sequence',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Fire Sequence'),
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
  //TODO: initialise session from storage
  final SessionCubit sessionCubit = SessionCubit(Session.init());

  final MonoCanvas oledBitmap = MonoCanvas(128, 64);
  late final fire = FireDevice(_midiDataListener);
  late final sequencer = Sequencer(sessionCubit);
  late final transport = Transport(sequencer, _onStop);
  late final tracks = TrackController(sequencer);
  late final menu = MainMenu(_onMenuUpdate, sessionCubit: sessionCubit);
  late final Screen screen;

  void _midiDataListener(MidiPacket packet) {
    transport.onMidiEvent(fire, packet.data[0], packet.data[1], packet.data[2]);
    tracks.onMidiEvent(fire, packet.data[0], packet.data[1], packet.data[2]);
    menu.onMidiEvent(fire, packet.data[0], packet.data[1], packet.data[2]);
  }

  void _onStop() => tracks.reset(fire);

  void _onMenuUpdate() => screen.redraw();

  void _paintToOLED(List<bool> data) => fire.sendBitmap(data);

  @override
  void initState() {
    super.initState();
    sequencer.listen((signal) {
      if (sequencer.state != ControlState.READY) {
        tracks.step(fire, sequencer.step);
      }
    });
    Future<void>.delayed(Duration(milliseconds: 500))
        .then<void>((_) => screen = Screen(_paintToOLED, menu));
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
