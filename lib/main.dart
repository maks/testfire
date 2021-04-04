import 'package:flutter/material.dart';
import 'package:monochrome_draw/monochrome_draw.dart';
import 'package:oled_font_57/oled_font_57.dart' as font57;
import 'package:testfire/fire_midi.dart';

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
  final MonoCanvas oledBitmap = MonoCanvas(128, 64);

  final fire = FireDevice();
  int ledCounter = 0;
  bool toggle = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    fire.disconnectDevice();
  }

  @override
  void reassemble() {
    super.reassemble();
    // need to disconnect from device when hot reloading otherwise midi conn wwill cuase it to hang
    fire.disconnectDevice();
    Future.delayed(Duration(seconds: 2)).then((_) => fire.connectDevice());
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: fire.sendAllOff,
              child: Text('ALL OFF'),
            ),
            TextButton(
              onPressed: fire.sendAllOn,
              child: Text('ALL ON'),
            ),
            TextButton(
              onPressed: () => fire.sendBitmap(oledBitmap.data),
              child: Text('BITMAP'),
            ),
            TextButton(
              onPressed: () {
                oledBitmap.clear();
                fire.sendBitmap(oledBitmap.data);
              },
              child: Text('OLED OFF'),
            ),
            TextButton(
              onPressed: () => fire.colorPad(0, 0, 127, 0, 0),
              child: Text('PAD COLOR'),
            ),
            TextButton(
              onPressed: () => fire.sendMidi(ControlBankLED.on(channel: true)),
              child: Text('Channel'),
            ),
            TextButton(
              onPressed: () => fire.sendMidi(ControlBankLED.on(mixer: true)),
              child: Text('MIXER'),
            ),
            TextButton(
              onPressed: () => fire.sendMidi(
                  ControlBankLED.on(channel: true, mixer: true, user2: true)),
              child: Text('Ch,Mx,U2'),
            ),
            TextButton(
              onPressed: () => fire.sendMidi(ControlBankLED.on()),
              child: Text('Bank LED OFF'),
            ),
            TextButton(
              onPressed: () {
                toggle
                    ? fire.sendMidi(IndicatorLED.off((ledCounter)))
                    : fire.sendMidi(IndicatorLED.green((ledCounter)));
                if (ledCounter == 3) {
                  toggle = !toggle;
                }
                ledCounter = ledCounter < 3 ? ledCounter + 1 : 0;
              },
              child: Text('LED On'),
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
