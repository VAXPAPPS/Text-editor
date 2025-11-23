import 'package:equatable/equatable.dart';

class EditorState extends Equatable {
  final String content;
  final int cursorLine;
  final int cursorCol;
  final int? jumpToLine;

  const EditorState({
    this.content = '',
    this.cursorLine = 1,
    this.cursorCol = 1,
    this.jumpToLine,
  });

  EditorState copyWith({
    String? content,
    int? cursorLine,
    int? cursorCol,
    int? jumpToLine,
  }) {
    return EditorState(
      content: content ?? this.content,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      jumpToLine:
          jumpToLine, // Always update if provided, or null to reset? Actually we want to trigger on change.
    );
  }

  @override
  List<Object?> get props => [content, cursorLine, cursorCol, jumpToLine];
}
