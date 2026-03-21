import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../blocs/editor_tabs/editor_tabs_cubit.dart';
import '../blocs/editor_tabs/editor_tabs_state.dart';

class EditorTabs extends StatelessWidget {
  const EditorTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorTabsCubit, EditorTabsState>(
      builder: (context, state) {
        final openFiles = state.openFiles;
        final activeIndex = state.activeIndex;

        if (openFiles.isEmpty) {
          return Container(
            color: const Color.fromARGB(0, 30, 30, 30),
            child: const Center(
              child: Text(
                'No files open',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          height: 35,
          color: const Color.fromARGB(0, 37, 37, 38),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openFiles.length,
            itemBuilder: (context, index) {
              final path = openFiles[index];
              final isActive = index == activeIndex;
              final fileName = p.basename(path);

              return InkWell(
                onTap: () {
                  context.read<EditorTabsCubit>().setActiveIndex(index);
                },
                child: _EditorTab(
                  isActive: isActive,
                  fileName: fileName,
                  onClose: () {
                    context.read<EditorTabsCubit>().closeFile(path);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EditorTab extends StatelessWidget {
  final bool isActive;
  final String fileName;
  final VoidCallback onClose;

  const _EditorTab({
    required this.isActive,
    required this.fileName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromARGB(120, 55, 55, 58)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4A4A4A)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              fileName,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
