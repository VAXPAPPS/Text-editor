import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchStarted>(_onSearchStarted);
    on<SearchCleared>(_onSearchCleared);
    on<SearchReplaceAll>(_onReplaceAll);
  }

  Future<void> _onSearchStarted(
    SearchStarted event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(const SearchLoaded([], ''));
      return;
    }

    emit(SearchLoading());

    try {
      final results = await _searchInDirectory(
        Directory(event.projectPath),
        event.query,
      );
      emit(SearchLoaded(results, event.query));
    } catch (e) {
      emit(SearchError('Search failed: $e'));
    }
  }

  Future<void> _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchInitial());
  }

  Future<void> _onReplaceAll(
    SearchReplaceAll event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) return;

    emit(SearchLoading());

    try {
      // 1. Find all files containing the query
      final results = await _searchInDirectory(
        Directory(event.projectPath),
        event.query,
      );

      // 2. Group by file
      final filesToUpdate = <String>{};
      for (var result in results) {
        filesToUpdate.add(result.filePath);
      }

      // 3. Perform replacement in each file
      for (var filePath in filesToUpdate) {
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final newContent = content.replaceAll(event.query, event.replacement);
          if (content != newContent) {
            await file.writeAsString(newContent);
          }
        }
      }

      // 4. Re-run search to confirm
      final newResults = await _searchInDirectory(
        Directory(event.projectPath),
        event.query,
      );

      emit(SearchLoaded(newResults, event.query));
    } catch (e) {
      emit(SearchError('Replace failed: $e'));
    }
  }

  Future<List<String>> _loadGitIgnore(Directory projectDir) async {
    final gitIgnoreFile = File(p.join(projectDir.path, '.gitignore'));
    final patterns = <String>[
      // Default ignores
      '.git',
      '.dart_tool',
      '.idea',
      'build',
      'node_modules',
      'ios/Pods',
      'android/.gradle',
      'linux/flutter',
      'windows/flutter',
      'macos/Flutter',
    ];

    if (await gitIgnoreFile.exists()) {
      try {
        final lines = await gitIgnoreFile.readAsLines();
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          // Simple glob to regex conversion or direct matching
          // For this POC, we'll store the raw pattern and do simple checks
          // A full gitignore parser is complex, we'll handle basic cases
          patterns.add(
            line.replaceAll('/', ''),
          ); // Remove leading/trailing slashes for simpler matching
        }
      } catch (e) {
        // Ignore read errors
      }
    }
    return patterns;
  }

  Future<List<SearchResult>> _searchInDirectory(
    Directory dir,
    String query,
  ) async {
    if (!await dir.exists()) return [];

    final projectDir = Directory(
      dir.path,
    ); // Assuming dir is project root for now
    final ignorePatterns = await _loadGitIgnore(projectDir);

    final results = <SearchResult>[];
    // Use stream to process files
    final files = dir.list(recursive: true, followLinks: false);

    await for (final entity in files) {
      if (entity is File) {
        if (_shouldIgnore(entity.path, projectDir.path, ignorePatterns)) {
          continue;
        }

        try {
          // Read file line by line to avoid loading huge files
          final lines = await entity.readAsLines();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.toLowerCase().contains(query.toLowerCase())) {
              results.add(
                SearchResult(
                  filePath: entity.path,
                  lineNumber: i + 1,
                  lineContent: line.trim(),
                  index: i,
                ),
              );
            }
          }
        } catch (e) {
          // Ignore read errors (binary files etc)
        }
      }
    }
    return results;
  }

  bool _shouldIgnore(String path, String projectRoot, List<String> patterns) {
    final relativePath = p.relative(path, from: projectRoot);
    final parts = p.split(relativePath);
    final basename = p.basename(path);

    // Always ignore hidden files/dirs (except .gitignore itself if we were checking it, but we are checking files)
    if (basename.startsWith('.') && basename != '.gitignore') return true;
    if (parts.any((part) => part.startsWith('.') && part != '.')) return true;

    // Check against patterns
    for (var pattern in patterns) {
      // Very basic matching: if any part of the path matches the pattern
      if (parts.contains(pattern)) return true;

      // Handle wildcard-like patterns roughly
      if (pattern.startsWith('*')) {
        final suffix = pattern.substring(1);
        if (basename.endsWith(suffix)) return true;
      }
    }

    // Binary/Media files
    if (basename.endsWith('.png') ||
        basename.endsWith('.jpg') ||
        basename.endsWith('.jpeg') ||
        basename.endsWith('.gif') ||
        basename.endsWith('.ico') ||
        basename.endsWith('.pdf')) {
      return true;
    }

    return false;
  }
}
