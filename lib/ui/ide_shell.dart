import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dart_editor/venom_layout.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../files/file_explorer.dart';
import '../blocs/file_explorer/file_explorer_cubit.dart';
import '../blocs/file_explorer/file_explorer_state.dart';
import '../editor/code_editor.dart';
import '../runner/terminal_panel.dart';
import '../blocs/process/process_bloc.dart';
import '../blocs/process/process_event.dart';
import '../blocs/analysis/analysis_bloc.dart';
import '../blocs/analysis/analysis_event.dart';
import '../blocs/search/search_bloc.dart';
import '../blocs/git/git_bloc.dart';
import '../blocs/git/git_event.dart';
import '../services/git_service.dart';
import 'editor_tabs.dart';
import 'status_bar.dart';
import 'search_panel.dart';
import 'problems_panel.dart';
import 'source_control_panel.dart';

class IDEShell extends StatefulWidget {
  const IDEShell({super.key});

  @override
  State<IDEShell> createState() => _IDEShellState();
}

class _IDEShellState extends State<IDEShell> {
  int _selectedSidebarIndex = 0; // 0: Files, 1: Search, 2: Git
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    // Start LSP
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<AnalysisBloc>().add(AnalysisStart());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SearchBloc()),
        BlocProvider(
          create: (context) {
            final bloc = GitBloc(GitService());
            final fileExplorerState = context.read<FileExplorerCubit>().state;
            if (fileExplorerState is FileExplorerLoaded) {
              bloc.add(GitStarted(fileExplorerState.path));
            }
            return bloc;
          },
        ),
      ],
      child: BlocListener<FileExplorerCubit, FileExplorerState>(
        listener: (context, state) {
          if (state is FileExplorerLoaded) {
            context.read<GitBloc>().add(GitStarted(state.path));
          }
        },
        child: VenomScaffold(
          appBar: AppBar(
            title: const Text('Flutter IDE'),
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () {
                  final projectPath = context
                      .read<FileExplorerCubit>()
                      .state
                      .projectPath;
                  if (projectPath != null) {
                    context.read<ProcessBloc>().add(ProcessRun(projectPath));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No project open')),
                    );
                  }
                },
                tooltip: 'Run',
              ),
              IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.yellow),
                onPressed: () {
                  context.read<ProcessBloc>().add(ProcessHotReload());
                },
                tooltip: 'Hot Reload',
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt, color: Colors.orange),
                onPressed: () {
                  context.read<ProcessBloc>().add(ProcessHotRestart());
                },
                tooltip: 'Hot Restart',
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.red),
                onPressed: () {
                  context.read<ProcessBloc>().add(ProcessStop());
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
                        flex: 0.25,
                        min: 0.1,
                        builder: (context, area) => Row(
                          children: [
                            // Activity Bar
                            Container(
                              width: 48,
                              color: const Color(0xFF252526),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  _buildSidebarIcon(
                                    0,
                                    Icons.folder_open,
                                    'Explorer',
                                  ),
                                  _buildSidebarIcon(1, Icons.search, 'Search'),
                                  _buildSidebarIcon(
                                    2,
                                    Icons.source,
                                    'Source Control',
                                  ),
                                ],
                              ),
                            ),
                            // Sidebar Content
                            if (_isSidebarVisible)
                              Expanded(
                                child: IndexedStack(
                                  index: _selectedSidebarIndex,
                                  children: const [
                                    FileExplorer(),
                                    SearchPanel(),
                                    SourceControlPanel(),
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      Area(
                        flex: 0.75,
                        builder: (context, area) => _buildMainContent(),
                      ),
                    ],
                  ),
                ),
              ),
              const StatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarIcon(int index, IconData icon, String tooltip) {
    final isSelected = _selectedSidebarIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
      tooltip: tooltip,
      onPressed: () {
        setState(() {
          if (_selectedSidebarIndex == index) {
            _isSidebarVisible = !_isSidebarVisible;
          } else {
            _selectedSidebarIndex = index;
            _isSidebarVisible = true;
          }
        });
      },
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
          Area(flex: 0.3, builder: (context, area) => _buildTerminalArea()),
        ],
      ),
    );
  }

  Widget _buildEditorArea() {
    return Container(
      color: const Color.fromARGB(0, 30, 30, 30),
      child: Column(
        children: [
          const EditorTabs(),
          const Expanded(child: CodeEditor()),
        ],
      ),
    );
  }

  Widget _buildTerminalArea() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 35,
            color: const Color(0xFF2D2D2D),
            child: const TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'TERMINAL', height: 35),
                Tab(text: 'PROBLEMS', height: 35),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [TerminalPanel(), ProblemsPanel()]),
          ),
        ],
      ),
    );
  }
}
