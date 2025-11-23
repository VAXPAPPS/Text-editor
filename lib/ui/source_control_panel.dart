import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../blocs/git/git_bloc.dart';
import '../blocs/git/git_event.dart';
import '../blocs/git/git_state.dart';
import '../services/git_service.dart';

class SourceControlPanel extends StatefulWidget {
  const SourceControlPanel({super.key});

  @override
  State<SourceControlPanel> createState() => _SourceControlPanelState();
}

class _SourceControlPanelState extends State<SourceControlPanel> {
  final _commitController = TextEditingController();

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GitBloc, GitState>(
      builder: (context, state) {
        if (state is GitLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GitError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<GitBloc>().add(GitRefresh());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is GitLoaded) {
          final staged = state.changedFiles.where((f) => f.isStaged).toList();
          final changes = state.changedFiles.where((f) => !f.isStaged).toList();

          return Column(
            children: [
              // Commit Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _commitController,
                      decoration: const InputDecoration(
                        hintText: 'Message (Ctrl+Enter to commit)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                      onSubmitted: (_) => _commit(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: staged.isEmpty ? null : _commit,
                        icon: const Icon(Icons.check),
                        label: const Text('Commit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Changes List
              Expanded(
                child: ListView(
                  children: [
                    if (staged.isNotEmpty) ...[
                      _buildSectionHeader('Staged Changes', staged.length),
                      ...staged.map((f) => _buildFileTile(f, true)),
                    ],
                    if (changes.isNotEmpty) ...[
                      _buildSectionHeader('Changes', changes.length),
                      ...changes.map((f) => _buildFileTile(f, false)),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('No git repository'));
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(GitFileStatus file, bool isStaged) {
    return ListTile(
      dense: true,
      leading: _buildStatusIcon(file),
      title: Text(p.basename(file.path)),
      subtitle: Text(
        p.dirname(file.path),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isStaged ? Icons.remove : Icons.add, size: 16),
            onPressed: () {
              if (isStaged) {
                context.read<GitBloc>().add(GitUnstageFile(file.path));
              } else {
                context.read<GitBloc>().add(GitStageFile(file.path));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(GitFileStatus file) {
    // Simplified status logic
    if (file.isUntracked) {
      return const Text(
        'U',
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      );
    }
    if (file.isModified) {
      return const Text(
        'M',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      );
    }
    return const Text(
      '?',
      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
    );
  }

  void _commit() {
    final message = _commitController.text;
    if (message.isNotEmpty) {
      context.read<GitBloc>().add(GitCommit(message));
      _commitController.clear();
    }
  }
}
