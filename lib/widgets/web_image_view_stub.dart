// Stub for non-web platforms. Returns an empty widget — the kIsWeb branch in
// CharacterArt ensures this is never actually used.
import 'package:flutter/widgets.dart';

class WebImageView extends StatelessWidget {
  const WebImageView({super.key, required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
