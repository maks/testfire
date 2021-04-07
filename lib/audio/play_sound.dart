import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'alsa_generated_bindings.dart' as a;

final alsa = a.ALSA(DynamicLibrary.open("libasound.so.2"));

main(List<String> args) {
  print('play: ${args[0]}');

  final Pointer<Pointer<a.snd_pcm_>> pcm = calloc<Pointer<a.snd_pcm_>>();

  // https://github.com/dart-lang/ffigen/issues/72#issuecomment-672060509
  Pointer<Int8> name = 'default'.toNativeUtf8().cast<Int8>();
  final stream = 0;
  final mode = 0;
  final openResult = alsa.snd_pcm_open(pcm, name, stream, mode);
}
