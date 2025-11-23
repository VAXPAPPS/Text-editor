import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import '../blocs/file_explorer/file_explorer_cubit.dart';
import '../blocs/file_explorer/file_explorer_state.dart';
import '../blocs/editor_tabs/editor_tabs_cubit.dart';

class FileExplorer extends StatefulWidget {
  const FileExplorer({super.key});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  Future<void> _openProject(BuildContext context) async {
    final String? directoryPath = await getDirectoryPath();
    if (!mounted) return;
    if (directoryPath != null) {
      context.read<FileExplorerCubit>().openProject(directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FileExplorerCubit, FileExplorerState>(
      builder: (context, state) {
        final projectPath = state.projectPath;

        if (projectPath == null) {
          return Center(
            child: ElevatedButton(
              onPressed: () => _openProject(context),
              child: const Text('Open Project'),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.basename(projectPath),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.folder_open,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () => _openProject(context),
                    tooltip: 'Open Project',
                  ),
                ],
              ),
            ),
            Expanded(child: _FileTree(rootPath: projectPath)),
          ],
        );
      },
    );
  }
}

class _FileTree extends StatefulWidget {
  final String rootPath;
  const _FileTree({required this.rootPath});

  @override
  State<_FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<_FileTree> {
  // Simple expansion state map
  final Map<String, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return _buildDirectory(Directory(widget.rootPath), 0);
  }

  Widget _buildDirectory(Directory dir, int depth) {
    List<FileSystemEntity> entities;
    try {
      entities = dir.listSync()
        ..sort((a, b) {
          // Sort directories first
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          return p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase());
        });
    } catch (e) {
      return const SizedBox();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        final name = p.basename(entity.path);
        final isDir = entity is Directory;
        final isExpanded = _expanded[entity.path] ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (isDir) {
                  setState(() {
                    _expanded[entity.path] = !isExpanded;
                  });
                } else {
                  context.read<EditorTabsCubit>().openFile(entity.path);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(left: 8.0 * depth, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isDir
                          ? (isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right)
                          : Icons.insert_drive_file,
                      size: 16,
                      color: isDir ? Colors.blueGrey : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isDir && isExpanded) _buildDirectory(entity, depth + 1),
          ],
        );
      },
    );
  }
}
