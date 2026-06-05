import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/strings.dart';
import '../services/routine_service.dart';
import '../theme/app_theme.dart';

/// 7 anchor points (Mon..Sun) along the winding stone path on `levelup.png`.
const List<Offset> kLevelupPathFraction = [
  Offset(0.50, 0.90), // Mon — base
  Offset(0.40, 0.78), // Tue
  Offset(0.58, 0.66), // Wed
  Offset(0.42, 0.54), // Thu
  Offset(0.55, 0.40), // Fri
  Offset(0.48, 0.26), // Sat
  Offset(0.50, 0.12), // Sun — summit
];

/// Stats mountain. Renders the supplied `levelup.png` as the backdrop and
/// places blinking day markers along the 7-step winding path.
class MountainClimb extends StatefulWidget {
  const MountainClimb({
    super.key,
    required this.progress,
    required this.dayStatuses,
    required this.locale,
  });

  final double progress; // 0..1 — actual weekly completion ratio
  final List<DayStatus> dayStatuses;
  final AppLocale locale;

  @override
  State<MountainClimb> createState() => _MountainClimbState();
}

class _MountainClimbState extends State<MountainClimb> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return AspectRatio(
          aspectRatio: 985 / 1597,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LayoutBuilder(
              builder: (c, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final climbPath = _buildClimbPoints(w, h);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Painted mountain backdrop supplied by the user.
                    Image.asset(
                      'assets/scenery/levelup.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      isAntiAlias: true,
                    ),
                    // Trail: gold for completed portion, dashed for remaining.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _TrailPainter(points: climbPath, progress: value),
                      ),
                    ),
                    // Blinking day markers along the path.
                    ..._buildFlagWidgets(climbPath),
                    // Summit trophy when the week is fully completed.
                    if (value >= 1.0)
                      Positioned(
                        left: climbPath.last.dx - 16,
                        top: climbPath.last.dy - 50,
                        child: Icon(
                          Icons.emoji_events,
                          color: AppColors.accentDeep,
                          size: 32,
                        ),
                      ),
                    // Progress badge — actual weekly completion %.
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(value * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static List<Offset> _buildClimbPoints(double w, double h) {
    return kLevelupPathFraction.map((f) => Offset(f.dx * w, f.dy * h)).toList();
  }

  List<Widget> _buildFlagWidgets(List<Offset> path) {
    final now = DateTime.now();
    final n = math.min(widget.dayStatuses.length, path.length);
    final widgets = <Widget>[];
    for (var i = 0; i < n; i++) {
      final s = widget.dayStatuses[i];
      final isToday = s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;

      Color color;
      bool blink;
      if (s.isHoliday) {
        color = const Color(0xFFCFCFCF);
        blink = false;
      } else if (isToday) {
        color = Colors.red;
        blink = true;
      } else if (s.isSuccess) {
        color = AppColors.success;
        blink = true;
      } else if (s.isFailure) {
        color = Colors.black87;
        blink = false;
      } else if (s.isPast) {
        color = AppColors.subtle;
        blink = false;
      } else {
        // Future day
        color = Colors.white.withValues(alpha: 0.65);
        blink = false;
      }

      widgets.add(Positioned(
        left: path[i].dx - 9,
        top: path[i].dy - 26,
        child: _FlagMark(
          color: color,
          label: DateFormat('E', widget.locale.intlLocale).format(s.date),
          blink: blink,
        ),
      ));
    }
    return widgets;
  }
}

/// Paints the trail connecting all 7 day anchors: solid gold up to the current
/// progress, dashed white for what's still ahead.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points, required this.progress});
  final List<Offset> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    final target = total * progress.clamp(0.0, 1.0);

    final pastPaint = Paint()
      ..color = const Color(0xFFFFC04A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pastShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final futurePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double traveled = 0;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final seg = (b - a).distance;
      final segEnd = traveled + seg;

      if (segEnd <= target) {
        canvas.drawLine(a, b, pastShadow);
        canvas.drawLine(a, b, pastPaint);
      } else if (traveled >= target) {
        _drawDashed(canvas, a, b, futurePaint);
      } else {
        final local = (target - traveled) / seg;
        final split = Offset.lerp(a, b, local)!;
        canvas.drawLine(a, split, pastShadow);
        canvas.drawLine(a, split, pastPaint);
        _drawDashed(canvas, split, b, futurePaint);
      }
      traveled = segEnd;
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    if (length == 0) return;
    const dashLen = 7.0;
    const gapLen = 5.0;
    final ux = (b.dx - a.dx) / length;
    final uy = (b.dy - a.dy) / length;
    double drawn = 0;
    while (drawn < length) {
      final endDist = math.min(drawn + dashLen, length);
      canvas.drawLine(
        Offset(a.dx + ux * drawn, a.dy + uy * drawn),
        Offset(a.dx + ux * endDist, a.dy + uy * endDist),
        paint,
      );
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.progress != progress || old.points != points;
}

/// Blinking day marker placed at each waypoint on the climb path.
/// - blink: true → pulsing opacity animation
/// - blink: false → static display
class _FlagMark extends StatefulWidget {
  const _FlagMark({required this.color, required this.label, this.blink = false});
  final Color color;
  final String label;
  final bool blink;

  @override
  State<_FlagMark> createState() => _FlagMarkState();
}

class _FlagMarkState extends State<_FlagMark> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.blink) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_FlagMark old) {
    super.didUpdateWidget(old);
    if (widget.blink && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.blink && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );

    if (!widget.blink) return content;
    return FadeTransition(opacity: _opacity, child: content);
  }
}
