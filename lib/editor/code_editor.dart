import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import '../providers.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  CodeController? _controller;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(activeFileProvider);

    if (activeFile == null) {
      return const Center(
        child: Text('No file open', style: TextStyle(color: Colors.grey)),
      );
    }

    // If file changed, load new content
    if (activeFile != _currentFilePath) {
      _currentFilePath = activeFile;
      _loadContent(activeFile);
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            showLineNumbers: true,
            textStyle: TextStyle(color: Colors.grey, fontSize: 12),
            width: 50,
            margin: 5,
          ),
        ),
      ),
    );
  }

  Future<void> _loadContent(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      
      setState(() {
        _controller = CodeController(
          text: content,
          language: dart,
        );
      });
      
      // Initialize content provider
      ref.read(currentContentProvider.notifier).set(content);
      
      // Listen for changes
      _controller!.addListener(() {
        ref.read(currentContentProvider.notifier).set(_controller!.text);
      });
    } catch (e) {
      // Handle error (e.g. binary file)
      setState(() {
        _controller = CodeController(
          text: '// Error reading file: $e',
          language: dart,
        );
      });
    }
  }
}
