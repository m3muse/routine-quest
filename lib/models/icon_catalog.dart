import 'package:flutter/material.dart';

/// Catalog of selectable routine icons. Stored as string keys for persistence.
class IconOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String category;
  /// Optional emoji that overrides the Material icon for better visual recognition.
  final String? emoji;
  /// Background container opacity. Default 0.15; increase for dark/vivid colors.
  final double backgroundAlpha;
  /// When true, applies ColorFiltered(BlendMode.srcIn) to the emoji using [color],
  /// producing a monochrome silhouette in the specified color.
  final bool tintEmoji;
  const IconOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.category,
    this.emoji,
    this.backgroundAlpha = 0.15,
    this.tintEmoji = false,
  });
}

/// Renders an icon option as a widget. Uses emoji when available, otherwise Material icon.
Widget buildIconWidget(IconOption opt, {double size = 22}) {
  if (opt.emoji != null) {
    final style = TextStyle(fontSize: size * 0.88);
    if (opt.tintEmoji) {
      // Body silhouette tinted to [opt.color], with the original emoji's bright
      // pixels (pickups/fret guides/strings) extracted as a white overlay.
      return Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(opt.color, BlendMode.srcIn),
            child: Text(opt.emoji!, style: style),
          ),
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0, 0, 0, 0, 255,
              0, 0, 0, 0, 255,
              0, 0, 0, 0, 255,
              2, 2, 2, 0, -1020,
            ]),
            child: Text(opt.emoji!, style: style),
          ),
        ],
      );
    }
    return Text(opt.emoji!, style: style);
  }
  return Icon(opt.icon, color: opt.color, size: size);
}

const List<IconOption> kIconCatalog = [
  // === 학습 ===
  IconOption(key: 'english', label: '영어', icon: Icons.abc, color: Color(0xFF3A8FE0), category: 'cat.study'),
  IconOption(key: 'math', label: '수학', icon: Icons.calculate, color: Color(0xFF7C4FE0), category: 'cat.study'),
  IconOption(key: 'social', label: '사회', icon: Icons.travel_explore, color: Color(0xFF2BA776), category: 'cat.study'),
  IconOption(key: 'coding', label: '코딩', icon: Icons.code, color: Color(0xFF2E2540), category: 'cat.study'),
  IconOption(key: 'vocab', label: '단어', icon: Icons.spellcheck, color: Color(0xFF1FA3A3), category: 'cat.study'),
  IconOption(key: 'exam', label: '시험', icon: Icons.fact_check, color: Color(0xFFD46B3F), category: 'cat.study'),
  IconOption(key: 'reading', label: '독서', icon: Icons.menu_book, color: Color(0xFF8A6E50), category: 'cat.study'),
  IconOption(key: 'writing', label: '작문', icon: Icons.draw, color: Color(0xFF4B6CB7), category: 'cat.study'),
  IconOption(key: 'science', label: '과학', icon: Icons.science, color: Color(0xFF1B6D8C), category: 'cat.study'),
  IconOption(key: 'history', label: '역사', icon: Icons.account_balance, color: Color(0xFF7A5A3A), category: 'cat.study'),
  // === 음악 — emoji for instantly recognizable instruments ===
  IconOption(key: 'piano', label: '피아노', icon: Icons.piano, color: Color(0xFF1F1A1A), category: 'cat.music', emoji: '🎹'),
  IconOption(key: 'guitar', label: '기타', icon: Icons.music_video, color: Color(0xFF1A1A1A), category: 'cat.music', emoji: '🎸', backgroundAlpha: 0.08, tintEmoji: true),
  IconOption(key: 'drum', label: '드럼', icon: Icons.album, color: Color(0xFFB04A2E), category: 'cat.music', emoji: '🥁'),
  IconOption(key: 'bass', label: '베이스', icon: Icons.graphic_eq, color: Color(0xFFD32F2F), category: 'cat.music', emoji: '🎸', backgroundAlpha: 0.15, tintEmoji: true),
  IconOption(key: 'score', label: '악보', icon: Icons.queue_music, color: Color(0xFF5B3F8C), category: 'cat.music'),
  IconOption(key: 'theory', label: '이론', icon: Icons.school, color: Color(0xFF2C5F8D), category: 'cat.music'),
  IconOption(key: 'listen', label: '리스닝', icon: Icons.headphones, color: Color(0xFF6E47B0), category: 'cat.music'),
  IconOption(key: 'sing', label: '보컬', icon: Icons.mic_external_on, color: Color(0xFFB44A7E), category: 'cat.music'),
  // === 운동 ===
  IconOption(key: 'running', label: '러닝', icon: Icons.directions_run, color: Color(0xFFE05A5A), category: 'cat.fitness'),
  IconOption(key: 'workout', label: '운동', icon: Icons.fitness_center, color: Color(0xFF2A8C7A), category: 'cat.fitness'),
  IconOption(key: 'weight', label: '웨이팅', icon: Icons.sports_gymnastics, color: Color(0xFF3E5C76), category: 'cat.fitness'),
  IconOption(key: 'stretch', label: '스트레칭', icon: Icons.self_improvement, color: Color(0xFF8B6FB5), category: 'cat.fitness'),
  IconOption(key: 'walk', label: '산책', icon: Icons.directions_walk, color: Color(0xFF6BAA72), category: 'cat.fitness'),
  IconOption(key: 'yoga', label: '요가', icon: Icons.accessibility_new, color: Color(0xFFB07BB0), category: 'cat.fitness'),
  IconOption(key: 'cycle', label: '자전거', icon: Icons.directions_bike, color: Color(0xFF2C8C9E), category: 'cat.fitness'),
  IconOption(key: 'swim', label: '수영', icon: Icons.pool, color: Color(0xFF3DA6E0), category: 'cat.fitness'),
  // === 기타 ===
  IconOption(key: 'star', label: '별', icon: Icons.star, color: Color(0xFFE0B14A), category: 'cat.misc'),
  IconOption(key: 'heart', label: '하트', icon: Icons.favorite, color: Color(0xFFE45A92), category: 'cat.misc'),
  IconOption(key: 'shopping', label: '쇼핑', icon: Icons.shopping_bag, color: Color(0xFFC0588A), category: 'cat.misc'),
  IconOption(key: 'cleaning', label: '청소', icon: Icons.cleaning_services, color: Color(0xFF5BA7C9), category: 'cat.misc'),
  IconOption(key: 'cook', label: '요리', icon: Icons.restaurant, color: Color(0xFFD46B3F), category: 'cat.misc'),
  IconOption(key: 'flower', label: '꽃', icon: Icons.local_florist, color: Color(0xFFE45A92), category: 'cat.misc'),
  IconOption(key: 'pet', label: '반려동물', icon: Icons.pets, color: Color(0xFF8A6E50), category: 'cat.misc'),
  IconOption(key: 'gift', label: '선물', icon: Icons.card_giftcard, color: Color(0xFFC75B6E), category: 'cat.misc'),
  IconOption(key: 'target', label: '목표', icon: Icons.flag, color: Color(0xFF5B3F8C), category: 'cat.misc'),
  IconOption(key: 'calendar', label: '일정', icon: Icons.event_available, color: Color(0xFF4B6CB7), category: 'cat.misc'),
  IconOption(key: 'phone', label: '전화', icon: Icons.phone_in_talk, color: Color(0xFF2A8C7A), category: 'cat.misc'),
  IconOption(key: 'travel', label: '여행', icon: Icons.luggage, color: Color(0xFF7C4FE0), category: 'cat.misc'),
  IconOption(key: 'art', label: '그림', icon: Icons.palette, color: Color(0xFFE08F2D), category: 'cat.misc'),
  IconOption(key: 'camera', label: '사진', icon: Icons.camera_alt, color: Color(0xFF5B3F8C), category: 'cat.misc'),
];

IconOption iconByKey(String key) =>
    kIconCatalog.firstWhere((i) => i.key == key, orElse: () => kIconCatalog.firstWhere((i) => i.key == 'star'));

List<String> iconCategories() {
  final seen = <String>{};
  final result = <String>[];
  for (final i in kIconCatalog) {
    if (seen.add(i.category)) result.add(i.category);
  }
  return result;
}

List<IconOption> iconsInCategory(String category) =>
    kIconCatalog.where((i) => i.category == category).toList();
