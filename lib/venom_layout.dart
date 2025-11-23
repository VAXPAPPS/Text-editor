import 'dart:math' as math;
import 'dart:ui'; // مهم للـ ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

import 'blocs/process/process_bloc.dart';
import 'blocs/process/process_event.dart';
import 'blocs/analysis/analysis_bloc.dart';
import 'blocs/analysis/analysis_event.dart';
import 'blocs/file_explorer/file_explorer_cubit.dart';

// 1. هذا هو الـ Layout الرئيسي الذي ستستخدمه في تطبيقك
class VenomScaffold extends StatefulWidget {
  final Widget body; // محتوى الصفحة (الإعدادات)
  final String title;

  const VenomScaffold({
    super.key,
    required this.body,
    this.title = "Venom IDE",
    required AppBar appBar,
  });

  @override
  State<VenomScaffold> createState() => _VenomScaffoldState();
}

class _VenomScaffoldState extends State<VenomScaffold> {
  // متغير الحالة للتحكم في الضبابية
  bool _isCinematicBlurActive = false;

  void _setBlur(bool active) {
    if (_isCinematicBlurActive != active) {
      setState(() {
        _isCinematicBlurActive = active;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(100, 0, 0, 0),

      body: Stack(
        children: [
          // --- الطبقة 1: محتوى التطبيق ---
          // نستخدم TweenAnimationBuilder لتحريك قيمة الـ Blur بنعومة
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: _isCinematicBlurActive
                  ? 10.0
                  : 0.0, // قوة البلور (10 قوية وجميلة)
            ),
            duration: const Duration(milliseconds: 300), // سرعة الأنيميشن
            curve: Curves.easeOutCubic, // منحنى حركة ناعم
            builder: (context, blurValue, child) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurValue,
                  sigmaY: blurValue,
                ),
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 40), // نترك مساحة للـ Appbar
              child: widget.body,
            ),
          ),

          // --- الطبقة 2: شريط العنوان (فوق الكل) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VenomAppbar(
              title: widget.title,
              // تمرير دالة للتحكم في البلور عند لمس الأزرار
              onHoverEnter: () => _setBlur(true),
              onHoverExit: () => _setBlur(false),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. شريط العنوان المعدل (يرسل إشارات الهوفر)
class VenomAppbar extends StatefulWidget {
  final String title;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  const VenomAppbar({
    super.key,
    required this.title,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  @override
  State<VenomAppbar> createState() => _VenomAppbarState();
}

class _VenomAppbarState extends State<VenomAppbar> {
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        await windowManager.startDragging();
        if (!context.mounted) return;
      },
      child: Container(
        height: 40,
        alignment: Alignment.centerRight,
        // خلفية نصف شفافة للشريط نفسه
        // color: const Color.fromARGB(100, 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            NeonActionBtn(
              child: const Icon(Icons.play_arrow, color: Colors.green),
              onTap: () {
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
              // tooltip: 'Run',
            ),
            NeonActionBtn(
              child: const Icon(Icons.flash_on, color: Colors.yellow),
              onTap: () {
                context.read<ProcessBloc>().add(ProcessHotReload());
              },
              // tooltip: 'Hot Reload',
            ),
            NeonActionBtn(
              child: const Icon(Icons.restart_alt, color: Colors.orange),
              onTap: () {
                context.read<ProcessBloc>().add(ProcessHotRestart());
              },
              // tooltip: 'Hot Restart',
            ),
            NeonActionBtn(
              child: const Icon(Icons.stop, color: Colors.red),
              onTap: () {
                context.read<ProcessBloc>().add(ProcessStop());
              },
              // tooltip: 'Stop',
            ),
            const SizedBox(width: 10),
            const Spacer(),

            // مجموعة الأزرار
            // نستخدم MouseRegion واحد كبير حول الأزرار الثلاثة
            // لضمان استمرار البلور عند التنقل بين زر وآخر
            MouseRegion(
              onEnter: (_) => widget.onHoverEnter(),
              onExit: (_) => widget.onHoverExit(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VenomWindowButton(
                    color: const Color(0xFFFFBD2E),
                    icon: Icons.remove,
                    onPressed: () => windowManager.minimize(),
                  ),

                  const SizedBox(width: 8),
                  VenomWindowButton(
                    color: const Color(0xFF28C840),
                    icon: Icons.check_box_outline_blank_rounded,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  VenomWindowButton(
                    color: const Color(0xFFFF5F57),
                    icon: Icons.close,
                    onPressed: () => windowManager.close(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. زر النافذة (نفس الذي صممناه سابقاً مع تحسينات طفيفة)
class VenomWindowButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const VenomWindowButton({
    super.key,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<VenomWindowButton> createState() => _VenomWindowButtonState();
}

class _VenomWindowButtonState extends State<VenomWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.8),
                      blurRadius: 10, // زيادة التوهج قليلاً
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Icon(
                widget.icon,
                size: 10,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





class NeonActionBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const NeonActionBtn({super.key, required this.onTap, required this.child});

  @override
  State<NeonActionBtn> createState() => _NeonActionBtnState();
}

class _NeonActionBtnState extends State<NeonActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // تحكم في سرعة الدوران من هنا (ثانيتين للدورة الكاملة)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // تكرار لا نهائي
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 50, // حجم الزر
        height: 50,
        color: Colors.transparent, // ضروري ليعمل اللمس
        child: Stack(
          alignment: Alignment.center,
          children: [
            // طبقة الحلقة النيون الدوارة
            RotationTransition(
              turns: _controller,
              child: CustomPaint(
                size: const Size(50, 50),
                painter: _NeonRingPainter(),
              ),
            ),
            // الأيقونة في المنتصف
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 3) - 3; // نصف القطر

    // إعداد فرشاة النيون
    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              3.0 // سماكة الحلقة
          ..strokeCap = StrokeCap.round
          // تأثير التوهج (Neon Glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    // التدرج اللوني (Venom Colors)
    // التدرج يبدأ شفافاً ثم سيان ثم بنفسجي ليعطي تأثير الذيل
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    paint.shader = const SweepGradient(
      colors: [
        Colors.transparent,
        Colors.cyanAccent,
        Colors.purpleAccent,
        Colors.cyanAccent, // تكرار اللون لغلق الحلقة بجمالية
      ],
      stops: [0.0, 0.5, 0.75, 1.0],
    ).createShader(rect);

    // رسم الحلقة
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}