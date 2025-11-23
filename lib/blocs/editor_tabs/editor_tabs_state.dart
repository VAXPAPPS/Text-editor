import 'package:equatable/equatable.dart';

class EditorTabsState extends Equatable {
  final List<String> openFiles;
  final int? activeIndex;

  const EditorTabsState({this.openFiles = const [], this.activeIndex});

  EditorTabsState copyWith({List<String>? openFiles, int? activeIndex}) {
    return EditorTabsState(
      openFiles: openFiles ?? this.openFiles,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  String? get activeFile {
    if (activeIndex != null &&
        activeIndex! >= 0 &&
        activeIndex! < openFiles.length) {
      return openFiles[activeIndex!];
    }
    return null;
  }

  @override
  List<Object?> get props => [openFiles, activeIndex];
}
