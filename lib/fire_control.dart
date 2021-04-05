import 'package:testfire/drum_sampler.dart';
import 'package:testfire/fire_midi.dart';

import 'sequencer.dart';

class Transport {
  final Sequencer sequencer;
  final Function() onStop;

  Transport(this.sequencer, this.onStop);

  void onMidiEvent(FireDevice device, int type, int id, int value) {
    if (type == CCInputs.buttonDown) {
      switch (id) {
        case CCInputs.play:
          _allOff(device);
          if (sequencer.state == ControlState.PLAY) {
            sequencer.on<ControlEvent>(ControlEvent(ControlState.PAUSE));
            device.sendMidi(CCInputs.on(CCInputs.play, CCInputs.yellow3));
          } else {
            sequencer.on<ControlEvent>(ControlEvent(ControlState.PLAY));
            device.sendMidi(CCInputs.on(CCInputs.play, CCInputs.green3));
          }
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
          sequencer.reset();
          onStop();
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
      final sample = Sampler.samples.keys.toList()[t.row];

      final prevStep = (step == 0) ? (Sequencer.stepsPerPattern - 1) : step - 1;
      final prevPadState = sequencer.trackdata[sample]?[prevStep] ?? false;
      final prevColor = t.step(prevPadState);
      device.colorPad(t.row, prevStep, prevColor);

      final padColor = tracks[t.row].beatStep();
      device.colorPad(t.row, step, padColor);
    }
  }

  void onMidiEvent(FireDevice device, int type, int id, int value) {
    if (PadInput.isPadDown(type, id, value)) {
      final pad = PadInput.fromMidi(id);
      final sample = Sampler.samples.keys.toList()[pad.row];

      sequencer.on<EditEvent>(EditEvent(sample, pad.column));

      final padState = sequencer.trackdata[sample]?[pad.row] ?? false;
      final padColor = tracks[pad.row].step(padState);
      device.colorPad(pad.row, pad.column, padColor);
    }
  }

  void reset(FireDevice device) {
    sequencer.reset();
    _clearAllPads(device);
  }

  void _clearAllPads(FireDevice device) {
    print('clear PADs');
    device.allPadsColor(PadColor.off());
  }
}

class _Track {
  final int row;
  _Track(this.row);

  PadColor step(bool padState) =>
      padState ? PadColor(0, 0, 127) : PadColor.off();

  PadColor beatStep() => PadColor(50, 50, 100);
}
