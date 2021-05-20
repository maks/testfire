import 'package:bloc/bloc.dart';

import 'session.dart';

class SessionCubit extends Cubit<Session> {
  SessionCubit(Session initialState) : super(initialState);

  void incrementBpm() => emit(state.copyWith(bpm: state.bpm + 1));

  void decrementBpm() => emit(state.copyWith(bpm: state.bpm - 1));
}
