import 'package:flutter/material.dart';
import 'dart:io';
import 'package:multi_split_view/multi_split_view.dart';
import '../files/file_explorer.dart';
import '../editor/code_editor.dart';
import '../runner/terminal_panel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../runner/process_service.dart';

import '../providers.dart';

class IDEShell extends ConsumerStatefulWidget {
  const IDEShell({super.key});

  @override
  ConsumerState<IDEShell> createState() => _IDEShellState();
}

class _IDEShellState extends ConsumerState<IDEShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter IDE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              final path = ref.read(activeFileProvider);
              final content = ref.read(currentContentProvider);
              if (path != null) {
                await File(path).writeAsString(content);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved!'), duration: Duration(milliseconds: 500)),
                  );
                }
              }
            },
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () => ref.read(processServiceProvider).runFlutterApp(),
            tooltip: 'Run',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.yellow),
            onPressed: () => ref.read(processServiceProvider).hotReload(),
            tooltip: 'Hot Reload',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () => ref.read(processServiceProvider).hotRestart(),
            tooltip: 'Hot Restart',
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: () => ref.read(processServiceProvider).stop(),
            tooltip: 'Stop',
          ),
        ],
      ),
      body: MultiSplitView(
        axis: Axis.horizontal,
        controller: MultiSplitViewController(
          areas: [
            Area(
              flex: 0.2,
              min: 0.1,
              builder: (context, area) => const FileExplorer(),
            ),
            Area(
              flex: 0.8,
              builder: (context, area) => _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return MultiSplitView(
      axis: Axis.vertical,
      controller: MultiSplitViewController(
        areas: [
          Area(
            flex: 0.7,
            min: 0.2,
            builder: (context, area) => _buildEditorArea(),
          ),
          Area(
            flex: 0.3,
            builder: (context, area) => _buildTerminalArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorArea() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const CodeEditor(),
    );
  }

  Widget _buildTerminalArea() {
    return const TerminalPanel();
  }
}
