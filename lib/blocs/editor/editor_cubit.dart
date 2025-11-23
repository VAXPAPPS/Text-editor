import 'package:flutter_bloc/flutter_bloc.dart';
import 'editor_state.dart';

class EditorCubit extends Cubit<EditorState> {
  EditorCubit() : super(const EditorState());

  void setContent(String content) {
    emit(state.copyWith(content: content));
  }

  void updateCursorPosition(int line, int col) {
    emit(state.copyWith(cursorLine: line, cursorCol: col));
  }

  void jumpToLine(int line) {
    emit(state.copyWith(jumpToLine: line));
  }
}
