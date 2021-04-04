import 'dart:io';

void play(String soundFile) {
  Process.run('aplay', [soundFile]);
}
