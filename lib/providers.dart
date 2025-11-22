import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Project Path
class ProjectPathNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? path) => state = path;
}
final projectPathProvider = NotifierProvider<ProjectPathNotifier, String?>(ProjectPathNotifier.new);

// Open Files List
class OpenFilesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  
  void add(String path) {
    if (!state.contains(path)) {
      state = [...state, path];
    }
  }
  
  void remove(String path) {
    state = state.where((p) => p != path).toList();
  }
}
final openFilesProvider = NotifierProvider<OpenFilesNotifier, List<String>>(OpenFilesNotifier.new);

// Active File Index
class ActiveIndexNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  
  void set(int? index) => state = index;
}
final activeIndexProvider = NotifierProvider<ActiveIndexNotifier, int?>(ActiveIndexNotifier.new);

// Computed Active File
final activeFileProvider = Provider<String?>((ref) {
  final files = ref.watch(openFilesProvider);
  final index = ref.watch(activeIndexProvider);
  if (index != null && index >= 0 && index < files.length) {
    return files[index];
  }
  return null;
});

// Current Content (mapped by file path)
// We'll keep a simple map for now, or just rely on the editor to load/save.
// For simplicity in this phase, let's keep the single currentContentProvider 
// but make sure it updates when the active file changes.
class CurrentContentNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String content) => state = content;
}
final currentContentProvider = NotifierProvider<CurrentContentNotifier, String>(CurrentContentNotifier.new);

// Cursor Position
class CursorPosition {
  final int line;
  final int col;
  const CursorPosition(this.line, this.col);
}

class CursorPositionNotifier extends Notifier<CursorPosition> {
  @override
  CursorPosition build() => const CursorPosition(1, 1);
  void set(int line, int col) => state = CursorPosition(line, col);
}
final cursorPositionProvider = NotifierProvider<CursorPositionNotifier, CursorPosition>(CursorPositionNotifier.new);

// List of files in the current project
final projectFilesProvider = FutureProvider<List<FileSystemEntity>>((ref) async {
  final path = ref.watch(projectPathProvider);
  if (path == null) return [];
  
  final dir = Directory(path);
  if (!await dir.exists()) return [];
  
  return dir.list(recursive: true).toList();
});
