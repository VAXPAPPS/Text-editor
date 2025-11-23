import 'package:flutter_bloc/flutter_bloc.dart';
import 'editor_tabs_state.dart';

class EditorTabsCubit extends Cubit<EditorTabsState> {
  EditorTabsCubit() : super(const EditorTabsState());

  void openFile(String path) {
    final currentIndex = state.openFiles.indexOf(path);
    if (currentIndex != -1) {
      emit(state.copyWith(activeIndex: currentIndex));
    } else {
      final newFiles = List<String>.from(state.openFiles)..add(path);
      emit(
        state.copyWith(openFiles: newFiles, activeIndex: newFiles.length - 1),
      );
    }
  }

  void closeFile(String path) {
    final indexToRemove = state.openFiles.indexOf(path);
    if (indexToRemove == -1) return;

    final newFiles = List<String>.from(state.openFiles)
      ..removeAt(indexToRemove);

    int? newIndex = state.activeIndex;
    if (newFiles.isEmpty) {
      newIndex = null;
    } else if (state.activeIndex == indexToRemove) {
      newIndex = indexToRemove >= newFiles.length
          ? newFiles.length - 1
          : indexToRemove;
    } else if (state.activeIndex! > indexToRemove) {
      newIndex = state.activeIndex! - 1;
    }

    emit(state.copyWith(openFiles: newFiles, activeIndex: newIndex));
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < state.openFiles.length) {
      emit(state.copyWith(activeIndex: index));
    }
  }
}
