import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../providers.dart';

class EditorTabs extends ConsumerWidget {
  const EditorTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openFiles = ref.watch(openFilesProvider);
    final activeIndex = ref.watch(activeIndexProvider);

    if (openFiles.isEmpty) {
      return Container(
        color: const Color.fromARGB(0, 30, 30, 30),
        child: const Center(
          child: Text('No files open', style: TextStyle(color: Colors.grey)),
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
              ref.read(activeIndexProvider.notifier).set(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: isActive ? const Color.fromARGB(255, 69, 179, 164) : Colors.transparent,
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
                      ref.read(openFilesProvider.notifier).remove(path);
                      // Adjust active index if needed
                      if (isActive) {
                        ref.read(activeIndexProvider.notifier).set(null);
                      } else if (activeIndex != null && index < activeIndex) {
                        ref.read(activeIndexProvider.notifier).set(activeIndex - 1);
                      }
                    },
                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
