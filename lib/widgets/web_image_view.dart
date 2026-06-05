// Web-only: renders an asset image via a native HTML <img> tag, bypassing
// Flutter's image pipeline. The browser downsamples large source images with
// its own (typically smoother) algorithm and respects `image-rendering: auto`.
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class WebImageView extends StatelessWidget {
  const WebImageView({super.key, required this.assetPath});

  final String assetPath;

  static final Set<String> _registered = <String>{};

  String get _viewType => 'rq-img-$assetPath';

  void _ensureRegistered() {
    if (_registered.contains(_viewType)) return;
    _registered.add(_viewType);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = web.HTMLImageElement();
      img.src = 'assets/$assetPath';
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = 'contain';
      img.style.imageRendering = 'auto';
      img.style.display = 'block';
      img.style.pointerEvents = 'none';
      // Hint for the browser to optimize quality.
      img.setAttribute('decoding', 'async');
      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureRegistered();
    // IgnorePointer is critical: HtmlElementView eats pointer events by
    // default, which blocks taps on Flutter widgets behind/around it
    // (e.g. the grid card's InkWell).
    // Key forces a fresh mount when viewType (i.e. assetPath) changes,
    // so swapping the selected character actually swaps the <img> element.
    return IgnorePointer(
      child: HtmlElementView(key: ValueKey(_viewType), viewType: _viewType),
    );
  }
}
