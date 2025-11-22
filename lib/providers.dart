import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Project Path
class ProjectPathNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? path) => state = path;
}
final projectPathProvider = NotifierProvider<ProjectPathNotifier, String?>(ProjectPathNotifier.new);

// Active File
class ActiveFileNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? path) => state = path;
}
final activeFileProvider = NotifierProvider<ActiveFileNotifier, String?>(ActiveFileNotifier.new);

// Current Content
class CurrentContentNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String content) => state = content;
}
final currentContentProvider = NotifierProvider<CurrentContentNotifier, String>(CurrentContentNotifier.new);

// List of files in the current project
final projectFilesProvider = FutureProvider<List<FileSystemEntity>>((ref) async {
  final path = ref.watch(projectPathProvider);
  if (path == null) return [];
  
  final dir = Directory(path);
  if (!await dir.exists()) return [];
  
  return dir.list(recursive: true).toList();
});
