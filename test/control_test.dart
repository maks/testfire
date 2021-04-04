import 'package:flutter_test/flutter_test.dart';

import 'package:testfire/fire_midi.dart';

void main() {
  test('padinput from midi correctly parses id', () {
    final p = PadInput.fromMidi(55);
    expect(p.row, 0);
    expect(p.column, 1);

    final p2 = PadInput.fromMidi(69);
    expect(p2.row, 0);
    expect(p2.column, 15);

    final p3 = PadInput.fromMidi(70);
    expect(p3.row, 1);
    expect(p3.column, 0);
  });
}
