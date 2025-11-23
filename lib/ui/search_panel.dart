import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../blocs/search/search_bloc.dart';
import '../blocs/search/search_event.dart';
import '../blocs/search/search_state.dart';
import '../blocs/file_explorer/file_explorer_cubit.dart';
import '../blocs/editor/editor_cubit.dart';
import '../blocs/editor_tabs/editor_tabs_cubit.dart';

class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final _controller = TextEditingController();
  String _lastQuery = '';

  final _replaceController = TextEditingController();
  bool _showReplace = false;

  @override
  void dispose() {
    _controller.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text;
    _lastQuery = query;
    final projectPath = context.read<FileExplorerCubit>().state.projectPath;

    if (projectPath != null) {
      context.read<SearchBloc>().add(SearchStarted(query, projectPath));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No project open')));
    }
  }

  void _performReplaceAll() {
    final query = _controller.text;
    final replacement = _replaceController.text;
    final projectPath = context.read<FileExplorerCubit>().state.projectPath;

    if (projectPath != null && query.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace All'),
          content: Text('Replace "$query" with "$replacement" in all files?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<SearchBloc>().add(
                  SearchReplaceAll(query, replacement, projectPath),
                );
              },
              child: const Text('Replace', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search in files...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _showReplace ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showReplace = !_showReplace;
                          });
                        },
                        tooltip: 'Toggle Replace',
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _controller.clear();
                          context.read<SearchBloc>().add(SearchCleared());
                        },
                      ),
                    ],
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              if (_showReplace) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replaceController,
                        decoration: InputDecoration(
                          hintText: 'Replace with...',
                          prefixIcon: const Icon(Icons.edit, size: 16),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.done_all, color: Colors.red),
                      onPressed: _performReplaceAll,
                      tooltip: 'Replace All',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SearchError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is SearchLoaded) {
                if (state.results.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                // Group results by file
                final grouped = <String, List<SearchResult>>{};
                for (var result in state.results) {
                  grouped.putIfAbsent(result.filePath, () => []).add(result);
                }

                return ListView.builder(
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final filePath = grouped.keys.elementAt(index);
                    final fileResults = grouped[filePath]!;
                    final fileName = p.basename(filePath);

                    return ExpansionTile(
                      title: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${fileResults.length} matches'),
                      initiallyExpanded: true,
                      children: fileResults.map((result) {
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 8,
                          ),
                          title: RichText(
                            text: _buildHighlightedText(
                              result.lineContent,
                              _lastQuery,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('Line ${result.lineNumber}'),
                          onTap: () async {
                            // Open file and jump to line
                            context.read<EditorTabsCubit>().openFile(
                              result.filePath,
                            );
                            if (context.mounted) {
                              context.read<EditorCubit>().jumpToLine(
                                result.lineNumber,
                              );
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              }
              return const Center(child: Text('Type to search'));
            },
          ),
        ),
      ],
    );
  }

  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }

    final matches = query.allMatches(text.toLowerCase());
    if (matches.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }

    final spans = <TextSpan>[];

    // Simple case-insensitive highlighting
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int startIndex = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(startIndex)));
        break;
      }

      if (index > startIndex) {
        spans.add(TextSpan(text: text.substring(startIndex, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: Colors.purple.withValues(alpha: 0.5),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      startIndex = index + query.length;
    }

    return TextSpan(
      children: spans,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: Colors.white70,
      ),
    );
  }
}
