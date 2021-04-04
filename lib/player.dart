import 'dart:io';

void play(String soundFile) {
  print('play:$soundFile');
  Process.run('aplay', [soundFile]);
}
