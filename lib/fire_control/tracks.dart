import '../drum_sampler.dart';
import '../fire_midi.dart';
import '../sequencer.dart';

class TrackController {
  final Sequencer sequencer;

  TrackController(this.sequencer);

  final List<_Track> tracks =
      List.generate(Sequencer.tracks, (index) => _Track(index));

  // called each time step changes
  void step(FireDevice device, int step) {
    for (var t in tracks) {
      final sample = DrumSampler.samples.keys.toList()[t.row];

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
      final sample = DrumSampler.samples.keys.toList()[pad.row];

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
