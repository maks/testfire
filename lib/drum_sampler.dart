import 'package:testfire/player.dart';

enum DRUM_SAMPLE { KICK, SNARE, HAT, TOM1, TOM2, CRASH }

abstract class DrumSampler {
  static String _ext = '.wav';
  static String _wavPath = '/home/maks/temp/drums/';

  static Map<DRUM_SAMPLE, String> samples = const {
    DRUM_SAMPLE.KICK: 'kick',
    DRUM_SAMPLE.SNARE: 'snare',
    DRUM_SAMPLE.HAT: 'hat',
    DRUM_SAMPLE.TOM1: 'tom1',
    DRUM_SAMPLE.TOM2: 'tom2',
    DRUM_SAMPLE.CRASH: 'crash',
  };

  static void playFile(DRUM_SAMPLE sample) =>
      play(_wavPath + samples[sample]! + _ext);
}
