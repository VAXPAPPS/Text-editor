import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import '../providers.dart';
import '../lsp/analysis_service.dart';

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
      child: Stack(
        children: [
          SingleChildScrollView(
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
          Positioned.fill(
            child: IgnorePointer(
              child: Consumer(
                builder: (context, ref, _) {
                  final diagnostics = ref.watch(diagnosticsProvider);
                  // Simple overlay for POC - just showing count or list at bottom
                  if (diagnostics.isEmpty) return const SizedBox();
                  
                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      color: Colors.black87,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: diagnostics.map((d) => Text(
                          'Ln ${d.line}: ${d.message}',
                          style: TextStyle(
                            color: d.severity == 'Error' ? Colors.red : Colors.yellow,
                            fontSize: 12,
                          ),
                        )).take(5).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
      
      // Notify LSP
      ref.read(analysisServiceProvider).didOpen(path, content);
      
      // Listen for changes
      _controller!.addListener(() {
        final text = _controller!.text;
        ref.read(currentContentProvider.notifier).set(text);
        
        // Notify LSP
        ref.read(analysisServiceProvider).didChange(path, text);
        
        // Update cursor position
        final selection = _controller!.selection;
        if (selection.baseOffset >= 0) {
          final beforeCursor = text.substring(0, selection.baseOffset);
          final line = beforeCursor.split('\n').length;
          final lastNewLine = beforeCursor.lastIndexOf('\n');
          final col = selection.baseOffset - (lastNewLine == -1 ? 0 : lastNewLine + 1) + 1;
          ref.read(cursorPositionProvider.notifier).set(line, col);
        }
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
