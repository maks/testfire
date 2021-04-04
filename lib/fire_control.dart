import 'package:testfire/fire_midi.dart';

import 'sequencer.dart';

class Transport {
  final Sequencer sequencer;

  Transport(this.sequencer);

  void onMidiEvent(FireDevice device, int type, int id, int value) {
    if (type == CCInputs.buttonDown) {
      switch (id) {
        case CCInputs.play:
          sequencer.on<ControlEvent>(ControlEvent(ControlState.PLAY));
          _allOff(device);
          device.sendMidi(CCInputs.on(CCInputs.play, CCInputs.green3));
          break;
        case CCInputs.record:
          sequencer.on<ControlEvent>(ControlEvent(ControlState.RECORD));
          _allOff(device);
          device.sendMidi(CCInputs.on(CCInputs.record, CCInputs.green3));
          break;
        case CCInputs.stop:
          sequencer.on<ControlEvent>(ControlEvent(ControlState.READY));
          _allOff(device);
          device.sendMidi(CCInputs.on(CCInputs.stop, CCInputs.green3));
          break;
      }
    }
  }

  void _allOff(FireDevice device) {
    device.sendMidi(CCInputs.on(CCInputs.play, CCInputs.off));
    device.sendMidi(CCInputs.on(CCInputs.record, CCInputs.off));
    device.sendMidi(CCInputs.on(CCInputs.stop, CCInputs.off));
  }
}

class TrackController {
  final List<_Track> tracks = List.generate(4, (index) => _Track(index));
  // called each time step changes
  void step(FireDevice device, int step) {
    for (var t in tracks) {
      t.step(device, step);
    }
  }

  void reset() {}
}

class _Track {
  final int row;

  _Track(this.row);

  void step(FireDevice device, int step) {
    int prevStep = (step == 0) ? 15 : step - 1;

    device.colorPad(row, prevStep, 0, 0, 0);
    device.colorPad(row, step, 0, 0, 127);
  }
}
