import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen celebratory overlay shown when the user gains a level.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.title,
    required this.avatarEmoji,
    required this.onDismiss,
  });

  final int newLevel;
  final String title;
  final String avatarEmoji;
  final VoidCallback onDismiss;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _burst;
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _burst.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _burst,
                builder: (c, _) => CustomPaint(
                  size: const Size(400, 400),
                  painter: _RayPainter(progress: _burst.value),
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _bounce,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.avatarEmoji, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 12),
                      Text(
                        'Lv ${widget.newLevel} · ${widget.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '한 주를 성실히 완수했어요!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '(탭하여 닫기)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RayPainter extends CustomPainter {
  _RayPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6 * (1 - progress))
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final maxLen = size.shortestSide * 0.5 * progress;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + progress * math.pi;
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * maxLen;
      canvas.drawLine(center, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
