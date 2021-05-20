import 'dart:async';
import 'package:testfire/session/sessionCubit.dart';

import 'drum_sampler.dart';
import 'session/session.dart';

enum ControlState { READY, PLAY, PAUSE, RECORD }

class Event {
  const Event();
}

class TickEvent extends Event {}

class ControlEvent extends Event {
  const ControlEvent(this.state);
  final ControlState state;
}

class PadEvent extends Event {
  const PadEvent(this.sample);
  final DRUM_SAMPLE sample;
}

class EditEvent extends Event {
  const EditEvent(this.sample, this.position);
  final DRUM_SAMPLE sample;
  final int position;
}

class Signal {}

/// 4 track sequencer
/// initially based on: https://github.com/kenreilly/flutter-drum-machine-demo
class Sequencer {
  // Each steps per pattern
  static const int stepsPerPattern = 16;
  // number of tracks sequenced
  static const int tracks = 4;
  static const int patternsPerTrack = 4;
  static const int timeSignature = 4;

  StreamSubscription<Session>? sessionSubscription;

  Sequencer(SessionCubit sessionCubit) {
    sessionSubscription = sessionCubit.stream.listen((session) {
      if (_state != ControlState.READY) {
        synchronize();
      }
      _signal.add(Signal());
      _lastBpm = session.bpm;
    });
  }

  // Engine control current state
  ControlState _state = ControlState.READY;
  get state => _state;

  int _lastBpm = 0;

  // Beats per minute
  int get bpm => _lastBpm;

  // Timer tick duration
  Duration get _tick =>
      Duration(milliseconds: (60000 / bpm / timeSignature).round());

  // Generates a new blank track data structure
  static Map<DRUM_SAMPLE, List<bool>> get _blanktape =>
      Map.fromIterable(DRUM_SAMPLE.values,
          key: (k) => k,
          value: (v) => List.generate(stepsPerPattern, (i) => false));

  // Track note on/off data
  Map<DRUM_SAMPLE, List<bool>> _trackdata = _blanktape;
  Map<DRUM_SAMPLE, List<bool>> get trackdata => _trackdata;

  // Outbound signal driver - allows widgets to listen for signals from audio engine
  StreamController<Signal> _signal = StreamController<Signal>.broadcast();

  Future<void> close() async {
    await sessionSubscription?.cancel();
    await _signal.close(); // Not used but required by SDK
  }

  StreamSubscription<Signal> listen(Function(Signal) onData) =>
      _signal.stream.listen(onData);

  // temp single track step
  int step = 0;

  Stopwatch _watch = Stopwatch();
  Timer? _timer;

  // Incoming event handler
  void on<T extends Event>(Event event) {
    switch (T) {
      case PadEvent:
        if (state == ControlState.RECORD) {
          return processInput(event as PadEvent);
        }
        DrumSampler.playFile((event as PadEvent).sample);
        return;

      case TickEvent:
        if (state == ControlState.READY || state == ControlState.PAUSE) {
          return;
        }
        return next();

      case EditEvent:
        return edit(event as EditEvent);

      case ControlEvent:
        return control(event as ControlEvent);
    }
  }

  // Controller state change handler
  control(ControlEvent event) {
    switch (event.state) {
      case ControlState.PLAY:
      case ControlState.RECORD:
        if (state == ControlState.READY) {
          start();
        }
        break;
      case ControlState.PAUSE:
        pause();
        break;
      case ControlState.READY:
      default:
        reset();
    }

    _state = event.state;
    _signal.add(Signal());
  }

  // Note block edit event handler
  void edit(EditEvent event) {
    trackdata[event.sample]?[event.position] =
        !trackdata[event.sample]![event.position];
    if (trackdata[event.sample]![event.position]) {
      DrumSampler.playFile(event.sample);
      print(
          'samp on:${event.position} - ${trackdata[event.sample]?[event.position]}');
    }
    _signal.add(Signal());
  }

  // Quantize input using the stopwatch
  void processInput(PadEvent event) {
    int position = (_watch.elapsedMilliseconds < 900)
        ? step
        : (step != (stepsPerPattern - 1))
            ? step + 1
            : 0;
    edit(EditEvent(event.sample, position));
  }

  // Reset the engine
  void reset() {
    step = 0;
    _watch.reset();
    _timer?.cancel();
  }

  // Start the sequencer
  void start() {
    _watch.start();
    _timer = Timer.periodic(_tick, (t) => on<TickEvent>(TickEvent()));
  }

  void pause() {
    _watch.stop();
  }

  // Process the next step
  void next() {
    step = (step == (stepsPerPattern - 1)) ? 0 : step + 1;
    _watch.reset();

    trackdata.forEach((DRUM_SAMPLE sample, List<bool> track) {
      if (track[step]) {
        DrumSampler.playFile(sample);
      }
    });

    _watch.start();
    _signal.add(Signal());
  }

  void synchronize() {
    _watch.stop();
    _timer?.cancel();

    _watch.start();
    _timer = Timer.periodic(_tick, (t) => on<TickEvent>(TickEvent()));
  }
}
