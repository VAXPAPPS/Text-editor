import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
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
                child: _NeonTab(
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

class _NeonTab extends StatefulWidget {
  final bool isActive;
  final String fileName;
  final VoidCallback onClose;

  const _NeonTab({
    required this.isActive,
    required this.fileName,
    required this.onClose,
  });

  @override
  State<_NeonTab> createState() => _NeonTabState();
}

class _NeonTabState extends State<_NeonTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Neon border for active tab
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(120, 35),
                  painter: _TabNeonPainter(
                    rotation: _controller.value * 2 * math.pi,
                  ),
                );
              },
            ),
          // Tab content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  widget.fileName,
                  style: TextStyle(
                    color: widget.isActive ? Colors.white : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onClose,
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabNeonPainter extends CustomPainter {
  final double rotation;

  _TabNeonPainter({this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

    // Gradient colors for the tab - now with rotation
    paint.shader = SweepGradient(
      center: Alignment.center,
      colors: const [
        Colors.transparent,
        Color.fromARGB(255, 69, 179, 164),
        Color.fromARGB(255, 100, 200, 180),
        Color.fromARGB(255, 69, 179, 164),
      ],
      stops: const [0.0, 0.5, 0.75, 1.0],
      transform: GradientRotation(rotation),
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _TabNeonPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
