import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest;

import '../models/character_def.dart';
import 'web_image_view.dart'
    if (dart.library.io) 'web_image_view_stub.dart';

/// Renders a chibi-style character (head + body + simple outfit) based on a
/// [CharacterDef]. Supports three modes: portrait, fullBody, climbing.
/// If a PNG asset exists in `assets/characters/...` it is used; otherwise
/// a CustomPainter fallback is rendered.
enum CharacterRenderMode { portrait, fullBody, climbing }

/// Cache of which asset paths exist (populated lazily from AssetManifest).
class _AssetExistCache {
  static Set<String>? _paths;
  static Future<bool> exists(BuildContext ctx, String path) async {
    _paths ??= (await AssetManifest.loadFromAssetBundle(DefaultAssetBundle.of(ctx)))
        .listAssets()
        .toSet();
    return _paths!.contains(path);
  }
}

class CharacterArt extends StatelessWidget {
  const CharacterArt({
    super.key,
    required this.def,
    this.mode = CharacterRenderMode.fullBody,
    this.size,
    this.bobbing = false,
    this.flipHorizontal = false,
  });

  final CharacterDef def;
  final CharacterRenderMode mode;
  /// If null, the widget fills the parent (caller controls the box).
  final double? size;
  final bool bobbing; // gentle idle animation
  final bool flipHorizontal;

  /// Fallback chain: climbing → fullBody → painter; portrait → fullBody → painter.
  List<String> get _fallbackChain {
    switch (mode) {
      case CharacterRenderMode.portrait:
        return [def.portraitAsset, def.fullBodyAsset];
      case CharacterRenderMode.fullBody:
        return [def.fullBodyAsset];
      case CharacterRenderMode.climbing:
        return [def.climbingAsset, def.fullBodyAsset];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget art = _ImageOrPainter(
      def: def,
      mode: mode,
      candidates: _fallbackChain,
      flip: flipHorizontal,
    );
    if (size != null) {
      art = SizedBox(width: size, height: size, child: art);
    }
    if (!bobbing) return art;
    return _Bobber(child: art);
  }
}

/// Tries each path in [candidates] via AssetManifest; if none exists, falls
/// back to the CustomPainter version.
class _ImageOrPainter extends StatefulWidget {
  const _ImageOrPainter({
    required this.def,
    required this.mode,
    required this.candidates,
    required this.flip,
  });
  final CharacterDef def;
  final CharacterRenderMode mode;
  final List<String> candidates;
  final bool flip;

  @override
  State<_ImageOrPainter> createState() => _ImageOrPainterState();
}

class _ImageOrPainterState extends State<_ImageOrPainter> {
  String? _resolved;
  List<String>? _resolvedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _ImageOrPainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameList(oldWidget.candidates, widget.candidates)) {
      _resolve();
    }
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _resolve() {
    final candidates = widget.candidates;
    if (_resolvedFor != null && _sameList(_resolvedFor!, candidates)) return;
    _resolvedFor = candidates;
    () async {
      for (final p in candidates) {
        if (await _AssetExistCache.exists(context, p)) {
          if (!mounted) return;
          if (!_sameList(_resolvedFor ?? const [], candidates)) return;
          setState(() => _resolved = p);
          return;
        }
      }
      if (mounted && _sameList(_resolvedFor ?? const [], candidates)) {
        setState(() => _resolved = null);
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved != null) {
      // On Flutter web, use a native <img> tag for crisp browser-native
      // downsampling. On other platforms fall back to Image.asset.
      Widget img = kIsWeb
          ? WebImageView(key: ValueKey('web-img-${_resolved!}'), assetPath: _resolved!)
          : Image.asset(
              _resolved!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => CustomPaint(
                painter: _CharacterPainter(def: widget.def, mode: widget.mode),
              ),
            );
      if (widget.flip) {
        img = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
          child: img,
        );
      }
      return img;
    }
    // Either still resolving (show painter as instant preview) or no asset.
    return CustomPaint(
      painter: _CharacterPainter(def: widget.def, mode: widget.mode),
    );
  }
}

class _Bobber extends StatefulWidget {
  const _Bobber({required this.child});
  final Widget child;
  @override
  State<_Bobber> createState() => _BobberState();
}

class _BobberState extends State<_Bobber> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final dy = Curves.easeInOut.transform(_c.value) * 4 - 2;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter({required this.def, required this.mode});
  final CharacterDef def;
  final CharacterRenderMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (mode == CharacterRenderMode.portrait) {
      _paintPortrait(canvas, w, h);
    } else {
      _paintFullBody(canvas, w, h);
    }
  }

  void _paintFullBody(Canvas canvas, double w, double h) {
    // Layout: head occupies top ~38% (chibi proportions)
    final headRadius = w * 0.18;
    final headCenter = Offset(w * 0.5, h * 0.30);
    final bodyTop = h * 0.46;
    final bodyBottom = h * 0.78;
    final legTop = bodyBottom;
    final legBottom = h * 0.96;

    // Shadow on ground
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, legBottom + 4), width: w * 0.42, height: 8),
      shadowPaint,
    );

    // Legs
    final legPaint = Paint()..color = def.outfitMain.withValues(alpha: 0.9);
    final legW = w * 0.07;
    _drawRoundedRect(canvas, Offset(w * 0.5 - legW - 2, legTop), Size(legW, legBottom - legTop), 4, legPaint);
    _drawRoundedRect(canvas, Offset(w * 0.5 + 2, legTop), Size(legW, legBottom - legTop), 4, legPaint);

    // Boots
    final bootPaint = Paint()..color = const Color(0xFF3A2A1F);
    _drawRoundedRect(canvas, Offset(w * 0.5 - legW - 4, legBottom - 6), Size(legW + 4, 9), 4, bootPaint);
    _drawRoundedRect(canvas, Offset(w * 0.5 + 0, legBottom - 6), Size(legW + 4, 9), 4, bootPaint);

    // Body (tunic / dress)
    final bodyPath = Path();
    final bodyWHalf = w * 0.16;
    bodyPath.moveTo(w * 0.5 - bodyWHalf * 0.7, bodyTop);
    bodyPath.quadraticBezierTo(
        w * 0.5 - bodyWHalf - 4, (bodyTop + bodyBottom) / 2, w * 0.5 - bodyWHalf, bodyBottom);
    bodyPath.lineTo(w * 0.5 + bodyWHalf, bodyBottom);
    bodyPath.quadraticBezierTo(
        w * 0.5 + bodyWHalf + 4, (bodyTop + bodyBottom) / 2, w * 0.5 + bodyWHalf * 0.7, bodyTop);
    bodyPath.close();
    canvas.drawPath(bodyPath, Paint()..color = def.outfitMain);

    // Outfit accent (belt / sash / trim)
    final beltY = (bodyTop + bodyBottom) / 2 + 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, beltY), width: bodyWHalf * 2 + 4, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = def.outfitAccent,
    );

    // Arms (simple ovals along the body sides)
    final armPaint = Paint()..color = def.outfitMain;
    final armW = w * 0.045;
    _drawRoundedRect(canvas, Offset(w * 0.5 - bodyWHalf - armW + 1, bodyTop + 2), Size(armW, (bodyBottom - bodyTop) * 0.85), 4, armPaint);
    _drawRoundedRect(canvas, Offset(w * 0.5 + bodyWHalf - 1, bodyTop + 2), Size(armW, (bodyBottom - bodyTop) * 0.85), 4, armPaint);
    // Hands
    final handPaint = Paint()..color = def.skin;
    canvas.drawCircle(Offset(w * 0.5 - bodyWHalf - armW / 2 + 1, bodyTop + (bodyBottom - bodyTop) * 0.85), armW * 0.7, handPaint);
    canvas.drawCircle(Offset(w * 0.5 + bodyWHalf + armW / 2 - 1, bodyTop + (bodyBottom - bodyTop) * 0.85), armW * 0.7, handPaint);

    // Neck
    final neckPaint = Paint()..color = def.skin;
    _drawRoundedRect(canvas, Offset(w * 0.5 - 5, bodyTop - 6), const Size(10, 8), 3, neckPaint);

    // Head
    _drawHead(canvas, headCenter, headRadius);
  }

  void _paintPortrait(Canvas canvas, double w, double h) {
    final headRadius = w * 0.32;
    final headCenter = Offset(w * 0.5, h * 0.45);

    // Soft aura background circle
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [def.aura.withValues(alpha: 0.6), def.aura.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.5)),
    );

    // Shoulders / collar suggestion
    final shoulderRect = Rect.fromLTWH(0, h * 0.78, w, h * 0.3);
    final shoulderPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.95)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w, h * 0.95)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(shoulderPath, Paint()..color = def.outfitMain);
    // Collar
    canvas.drawRect(
      Rect.fromLTWH(shoulderRect.left, h * 0.78, w, 4),
      Paint()..color = def.outfitAccent,
    );

    _drawHead(canvas, headCenter, headRadius);
  }

  void _drawHead(Canvas canvas, Offset center, double radius) {
    // Skin
    final skinPaint = Paint()..color = def.skin;
    canvas.drawCircle(center, radius, skinPaint);
    // Soft cheek
    final cheek = Paint()..color = const Color(0xFFFFAEC1).withValues(alpha: 0.5);
    canvas.drawCircle(center + Offset(-radius * 0.45, radius * 0.25), radius * 0.18, cheek);
    canvas.drawCircle(center + Offset(radius * 0.45, radius * 0.25), radius * 0.18, cheek);

    // Hair (drawn first as back, then front)
    _drawHair(canvas, center, radius);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF222033);
    final eyeY = center.dy + radius * 0.05;
    final eyeOffsetX = radius * 0.32;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - eyeOffsetX, eyeY), width: radius * 0.18, height: radius * 0.22),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + eyeOffsetX, eyeY), width: radius * 0.18, height: radius * 0.22),
      eyePaint,
    );
    // Eye shine
    final shine = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - eyeOffsetX + radius * 0.04, eyeY - radius * 0.04), radius * 0.04, shine);
    canvas.drawCircle(Offset(center.dx + eyeOffsetX + radius * 0.04, eyeY - radius * 0.04), radius * 0.04, shine);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF8A3F4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(center.dx - radius * 0.15, center.dy + radius * 0.35)
      ..quadraticBezierTo(
        center.dx, center.dy + radius * 0.45,
        center.dx + radius * 0.15, center.dy + radius * 0.35,
      );
    canvas.drawPath(mouthPath, mouthPaint);

    // Accessory
    _drawAccessory(canvas, center, radius);
  }

  void _drawHair(Canvas canvas, Offset c, double r) {
    final hair = Paint()..color = def.hair;
    switch (def.hairStyle) {
      case HairStyle.shortStraight:
        final p = Path()
          ..moveTo(c.dx - r * 1.0, c.dy)
          ..quadraticBezierTo(c.dx - r * 1.1, c.dy - r * 1.2, c.dx, c.dy - r * 1.05)
          ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * 1.2, c.dx + r * 1.0, c.dy)
          ..lineTo(c.dx + r * 0.85, c.dy - r * 0.35)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.55, c.dx - r * 0.85, c.dy - r * 0.35)
          ..close();
        canvas.drawPath(p, hair);
        // fringe
        final fringe = Path()
          ..moveTo(c.dx - r * 0.6, c.dy - r * 0.4)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.05, c.dx + r * 0.6, c.dy - r * 0.4)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.7, c.dx - r * 0.6, c.dy - r * 0.4)
          ..close();
        canvas.drawPath(fringe, hair);
        break;
      case HairStyle.cropped:
        canvas.drawCircle(Offset(c.dx, c.dy - r * 0.55), r * 0.95, hair);
        // shaved sides hint
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r * 1.02),
          math.pi * 1.1, math.pi * 0.8, false,
          Paint()
            ..color = def.hair.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.12,
        );
        break;
      case HairStyle.mediumWavy:
        // Side bangs that frame the face
        final left = Path()
          ..moveTo(c.dx - r, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx - r * 1.25, c.dy + r * 0.4, c.dx - r * 0.75, c.dy + r * 0.7)
          ..quadraticBezierTo(c.dx - r * 0.6, c.dy + r * 0.2, c.dx - r * 0.5, c.dy - r * 0.4)
          ..close();
        canvas.drawPath(left, hair);
        final right = Path()
          ..moveTo(c.dx + r, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx + r * 1.25, c.dy + r * 0.4, c.dx + r * 0.75, c.dy + r * 0.7)
          ..quadraticBezierTo(c.dx + r * 0.6, c.dy + r * 0.2, c.dx + r * 0.5, c.dy - r * 0.4)
          ..close();
        canvas.drawPath(right, hair);
        // top
        final top = Path()
          ..moveTo(c.dx - r, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.4, c.dx + r, c.dy - r * 0.2)
          ..lineTo(c.dx + r * 0.7, c.dy - r * 0.7)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.45, c.dx - r * 0.7, c.dy - r * 0.7)
          ..close();
        canvas.drawPath(top, hair);
        break;
      case HairStyle.longTied:
        // Long tied tail back
        final tail = Path()
          ..moveTo(c.dx - r * 0.2, c.dy + r * 0.3)
          ..lineTo(c.dx - r * 0.35, c.dy + r * 1.5)
          ..lineTo(c.dx + r * 0.35, c.dy + r * 1.5)
          ..lineTo(c.dx + r * 0.2, c.dy + r * 0.3)
          ..close();
        canvas.drawPath(tail, hair);
        // top dome
        final top = Path()
          ..moveTo(c.dx - r, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.25, c.dx + r, c.dy - r * 0.1)
          ..lineTo(c.dx + r * 0.4, c.dy - r * 0.55)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.35, c.dx - r * 0.4, c.dy - r * 0.55)
          ..close();
        canvas.drawPath(top, hair);
        break;
      case HairStyle.longWavy:
        // Long wavy down both sides
        final flow = Path()
          ..moveTo(c.dx - r * 1.05, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx - r * 1.3, c.dy + r * 0.5, c.dx - r * 1.0, c.dy + r * 1.4)
          ..quadraticBezierTo(c.dx - r * 0.7, c.dy + r * 1.5, c.dx - r * 0.4, c.dy + r * 1.3)
          ..lineTo(c.dx + r * 0.4, c.dy + r * 1.3)
          ..quadraticBezierTo(c.dx + r * 0.7, c.dy + r * 1.5, c.dx + r * 1.0, c.dy + r * 1.4)
          ..quadraticBezierTo(c.dx + r * 1.3, c.dy + r * 0.5, c.dx + r * 1.05, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.4, c.dx - r * 1.05, c.dy - r * 0.1)
          ..close();
        canvas.drawPath(flow, hair);
        // sweeping fringe
        final fringe = Path()
          ..moveTo(c.dx - r * 0.85, c.dy - r * 0.45)
          ..quadraticBezierTo(c.dx + r * 0.3, c.dy - r * 0.9, c.dx + r * 0.6, c.dy - r * 0.25)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.5, c.dx - r * 0.85, c.dy - r * 0.45)
          ..close();
        canvas.drawPath(fringe, hair);
        break;
      case HairStyle.ponytail:
        canvas.drawCircle(Offset(c.dx + r * 0.9, c.dy - r * 0.2), r * 0.35, hair);
        final top = Path()
          ..moveTo(c.dx - r, c.dy - r * 0.1)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.25, c.dx + r, c.dy - r * 0.1)
          ..lineTo(c.dx + r * 0.4, c.dy - r * 0.55)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.35, c.dx - r * 0.4, c.dy - r * 0.55)
          ..close();
        canvas.drawPath(top, hair);
        break;
    }
  }

  void _drawAccessory(Canvas canvas, Offset c, double r) {
    switch (def.accessory) {
      case Accessory.none:
        break;
      case Accessory.glasses:
        final paint = Paint()
          ..color = const Color(0xFF222222)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.04;
        final eyeY = c.dy + r * 0.05;
        canvas.drawCircle(Offset(c.dx - r * 0.32, eyeY), r * 0.22, paint);
        canvas.drawCircle(Offset(c.dx + r * 0.32, eyeY), r * 0.22, paint);
        canvas.drawLine(
          Offset(c.dx - r * 0.1, eyeY),
          Offset(c.dx + r * 0.1, eyeY),
          paint,
        );
        break;
      case Accessory.crown:
        final goldPaint = Paint()..color = const Color(0xFFE0B14A);
        final cy = c.dy - r * 0.9;
        final crown = Path()
          ..moveTo(c.dx - r * 0.55, cy)
          ..lineTo(c.dx - r * 0.55, cy - r * 0.15)
          ..lineTo(c.dx - r * 0.3, cy + r * 0.1)
          ..lineTo(c.dx - r * 0.05, cy - r * 0.3)
          ..lineTo(c.dx + r * 0.2, cy + r * 0.1)
          ..lineTo(c.dx + r * 0.5, cy - r * 0.18)
          ..lineTo(c.dx + r * 0.5, cy)
          ..close();
        canvas.drawPath(crown, goldPaint);
        canvas.drawCircle(Offset(c.dx - r * 0.05, cy - r * 0.3), r * 0.06, Paint()..color = const Color(0xFFE0496B));
        break;
      case Accessory.flowerCrown:
        for (var i = 0; i < 5; i++) {
          final t = i / 4;
          final fx = c.dx - r * 0.7 + t * (r * 1.4);
          final fy = c.dy - r * 0.85 + math.sin(t * math.pi) * -r * 0.25;
          _drawFlower(canvas, Offset(fx, fy), r * 0.12);
        }
        break;
      case Accessory.hood:
        final hoodPaint = Paint()..color = def.outfitMain.withValues(alpha: 0.95);
        final hood = Path()
          ..moveTo(c.dx - r * 1.05, c.dy + r * 0.4)
          ..quadraticBezierTo(c.dx - r * 1.2, c.dy - r * 0.5, c.dx, c.dy - r * 1.25)
          ..quadraticBezierTo(c.dx + r * 1.2, c.dy - r * 0.5, c.dx + r * 1.05, c.dy + r * 0.4)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.2, c.dx - r * 1.05, c.dy + r * 0.4)
          ..close();
        canvas.drawPath(hood, hoodPaint);
        break;
      case Accessory.headband:
        final bandPaint = Paint()..color = def.outfitAccent;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(c.dx, c.dy - r * 0.55), width: r * 1.7, height: r * 0.18),
            const Radius.circular(4),
          ),
          bandPaint,
        );
        break;
    }
  }

  void _drawFlower(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = const Color(0xFFFFB5D8);
    for (var i = 0; i < 5; i++) {
      final a = i * (math.pi * 2 / 5);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.6, r * 0.4, p);
    }
    canvas.drawCircle(c, r * 0.35, Paint()..color = const Color(0xFFFFE066));
  }

  void _drawRoundedRect(Canvas canvas, Offset topLeft, Size size, double radius, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(topLeft & size, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) =>
      old.def.id != def.id || old.mode != mode;
}
