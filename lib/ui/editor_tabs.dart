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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: isActive
                      ? const Color.fromARGB(255, 69, 179, 164)
                      : Colors.transparent,
                  alignment: Alignment.center,
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
                        onTap: () {
                          context.read<EditorTabsCubit>().closeFile(path);
                        },
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
