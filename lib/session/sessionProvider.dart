import 'package:riverpod/riverpod.dart';

import 'session.dart';

class SessionStateNotifier extends StateNotifier<Session> {
  SessionStateNotifier() : super(Session.init());

  void incrementBpm() {
    state = state.copyWith(bpm: state.bpm + 1);
  }

  void decrementBpm() {
    state = state.copyWith(bpm: state.bpm - 1);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionStateNotifier, Session>((ref) {
  return SessionStateNotifier();
});
