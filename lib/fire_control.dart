import 'package:testfire/drum_sampler.dart';
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
  final Sequencer sequencer;

  TrackController(this.sequencer);

  final List<_Track> tracks =
      List.generate(Sequencer.tracks, (index) => _Track(index));
  // called each time step changes
  void step(FireDevice device, int step) {
    for (var t in tracks) {
      t.step(device, step);
    }
  }

  void onMidiEvent(FireDevice device, int type, int id, int value) {
    if (PadInput.isPadDown(type, id, value)) {
      final pi = PadInput.fromMidi(id);
      final sample = Sampler.samples.keys.toList()[pi.row];
      sequencer.on<EditEvent>(EditEvent(sample, pi.column));

      final padState = sequencer.trackdata[sample]?[pi.row] ?? false;
      padState
          ? device.colorPad(pi.row, pi.column, 10, 10, 100)
          : device.colorPad(pi.row, pi.column, 0, 0, 0);
      //print('PAD: $pi');
    }
  }

  void reset() {
    //TODO
  }
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
