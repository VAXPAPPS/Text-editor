import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:texteditor/venom_layout.dart';
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
import 'interactive_terminal.dart';

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
                              width: 50,
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  _buildSidebarIcon(
                                    0,
                                    Icons.folder_open,
                                    'Explorer',
                                    [
                                      Colors.transparent,
                                      Colors.cyanAccent,
                                      Colors.blueAccent,
                                      Colors.cyanAccent,
                                    ],
                                  ),
                                  _buildSidebarIcon(1, Icons.search, 'Search', [
                                    Colors.transparent,
                                    Colors.greenAccent,
                                    Colors.lightGreenAccent,
                                    Colors.greenAccent,
                                  ]),
                                  _buildSidebarIcon(
                                    2,
                                    Icons.account_tree,
                                    'Source Control',
                                    [
                                      Colors.transparent,
                                      Colors.orangeAccent,
                                      Colors.deepOrangeAccent,
                                      Colors.orangeAccent,
                                    ],
                                  ),
                                  const Spacer(),
                                  _buildSidebarIcon(
                                    3,
                                    Icons.settings,
                                    'Settings',
                                    [
                                      Colors.transparent,
                                      Colors.purpleAccent,
                                      Colors.deepPurpleAccent,
                                      Colors.purpleAccent,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Sidebar Content
                            if (_isSidebarVisible)
                              Expanded(
                                child: _NeonSidebarWrapper(
                                  child: IndexedStack(
                                    index: _selectedSidebarIndex,
                                    children: const [
                                      FileExplorer(),
                                      SearchPanel(),
                                      SourceControlPanel(),
                                      Center(child: Text('Settings')),
                                    ],
                                  ),
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

  Widget _buildSidebarIcon(
    int index,
    IconData icon,
    String tooltip,
    List<Color> colors,
  ) {
    final isSelected = _selectedSidebarIndex == index;

    // If selected, show NeonActionBtn with full opacity
    // If not selected, maybe show a dimmed version or just the icon?
    // User asked for "neon effect to appear on them", implying they should all have it?
    // Or maybe only the selected one? "appear on them" suggests all.
    // But usually you only highlight the active one.
    // Let's make the selected one have the neon ring, and unselected ones just be icons.
    // OR, if the user wants them all to have the effect, maybe on hover?
    // Given "appear on them but with different colors", I'll apply it to all but maybe
    // only animate or show the ring when selected/hovered?
    // The NeonActionBtn always animates.
    // Let's use NeonActionBtn for all, but maybe dim the icon if not selected.

    return NeonActionBtn(
      onTap: () {
        setState(() {
          if (_selectedSidebarIndex == index) {
            _isSidebarVisible = !_isSidebarVisible;
          } else {
            _selectedSidebarIndex = index;
            _isSidebarVisible = true;
          }
        });
      },
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey.withValues(alpha: 0.5),
        size: 24,
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
    return const _NeonTerminalArea();
  }
}

class _NeonTerminalArea extends StatelessWidget {
  const _NeonTerminalArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3F3F46)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                height: 35,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(61, 45, 45, 45),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: 'TERMINAL', height: 35),
                    Tab(text: 'DEBUG', height: 35),
                    Tab(text: 'PROBLEMS', height: 35),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    InteractiveTerminal(),
                    TerminalPanel(),
                    ProblemsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeonSidebarWrapper extends StatelessWidget {
  final Widget child;

  const _NeonSidebarWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3F3F46)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
