import 'package:flutter/material.dart';
import 'package:flutter_dart_editor/venom_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../files/file_explorer.dart';
import '../editor/code_editor.dart';
import '../runner/terminal_panel.dart';
import '../runner/process_service.dart';
import 'editor_tabs.dart';
import 'status_bar.dart';
import '../lsp/analysis_service.dart';

class IDEShell extends ConsumerStatefulWidget {
  const IDEShell({super.key});

  @override
  ConsumerState<IDEShell> createState() => _IDEShellState();
}

class _IDEShellState extends ConsumerState<IDEShell> {
  @override
  void initState() {
    super.initState();
    // Start LSP
    Future.delayed(Duration.zero, () {
      ref.read(analysisServiceProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return VenomScaffold(
      appBar: AppBar(
        title: const Text('Flutter IDE'),
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () {
              ref.read(processServiceProvider).runFlutterApp();
            },
            tooltip: 'Run',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.yellow),
            onPressed: () {
              ref.read(processServiceProvider).hotReload();
            },
            tooltip: 'Hot Reload',
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orange),
            onPressed: () {
              ref.read(processServiceProvider).hotRestart();
            },
            tooltip: 'Hot Restart',
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: () {
              ref.read(processServiceProvider).stop();
            },
            tooltip: 'Stop',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MultiSplitView(
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
          ),
          const StatusBar(),
        ],
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
      color: const Color.fromARGB(0, 0, 0, 0),
      child: Column(
        children: [
          const EditorTabs(),
          const Expanded(child: CodeEditor()),
        ],
      ),
    );
  }

  Widget _buildTerminalArea() {
    return const TerminalPanel();
  }
}
