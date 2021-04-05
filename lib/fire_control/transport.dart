import '../fire_midi.dart';
import '../sequencer.dart';

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
