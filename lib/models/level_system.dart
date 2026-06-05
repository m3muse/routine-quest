import 'package:flutter/material.dart';

/// 12-tier level system in the spirit of 제2의 나라.
///
/// Each level represents 4 weeks of perfect completion (one season = ~3 levels).
/// In a year (52 weeks) a fully dedicated player can reach level 12.
class LevelTier {
  final int level; // 1..12
  final String title; // Korean rank name
  final String subtitle; // short flavor text
  final IconData icon;
  final Color color;
  const LevelTier({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<LevelTier> kLevelTiers = [
  LevelTier(
    level: 1,
    title: '무지의 새싹',
    subtitle: '첫 걸음을 내딛는 자',
    icon: Icons.spa,
    color: Color(0xFFA7D78A),
  ),
  LevelTier(
    level: 2,
    title: '호기심 도제',
    subtitle: '세상의 규칙을 배우기 시작',
    icon: Icons.menu_book,
    color: Color(0xFF8DC176),
  ),
  LevelTier(
    level: 3,
    title: '수련의 길',
    subtitle: '꾸준함이 무기가 된다',
    icon: Icons.fitness_center,
    color: Color(0xFF6FB85F),
  ),
  LevelTier(
    level: 4,
    title: '약초 술사',
    subtitle: '작은 마법을 다루기 시작',
    icon: Icons.local_florist,
    color: Color(0xFF52A565),
  ),
  LevelTier(
    level: 5,
    title: '바람의 술사',
    subtitle: '루틴이 자연스러워진다',
    icon: Icons.air,
    color: Color(0xFF67B2D9),
  ),
  LevelTier(
    level: 6,
    title: '빛의 학도',
    subtitle: '재능이 빛나기 시작한다',
    icon: Icons.auto_awesome,
    color: Color(0xFFF6C04E),
  ),
  LevelTier(
    level: 7,
    title: '현자의 제자',
    subtitle: '깊이 있는 통찰을 얻다',
    icon: Icons.school,
    color: Color(0xFFD89824),
  ),
  LevelTier(
    level: 8,
    title: '대 술사',
    subtitle: '한 분야의 대가로 인정받다',
    icon: Icons.bolt,
    color: Color(0xFFB07BE0),
  ),
  LevelTier(
    level: 9,
    title: '현자',
    subtitle: '많은 이의 길잡이가 되다',
    icon: Icons.shield_moon,
    color: Color(0xFF7B4FC8),
  ),
  LevelTier(
    level: 10,
    title: '용사',
    subtitle: '시련을 넘어 영웅의 길로',
    icon: Icons.shield,
    color: Color(0xFF7AC6EB),
  ),
  LevelTier(
    level: 11,
    title: '대마법사',
    subtitle: '강력한 의지의 화신',
    icon: Icons.flare,
    color: Color(0xFFE08F2D),
  ),
  LevelTier(
    level: 12,
    title: '에너지의 영웅',
    subtitle: '1년의 여정을 완성한 자',
    icon: Icons.emoji_events,
    color: Color(0xFFE0496B),
  ),
];

class LevelSystem {
  /// Weeks of perfect completion required to reach the next level (= 1 month).
  static const int weeksPerLevel = 4;

  /// Each perfectly completed week awards exactly 1 badge (stored in user.exp).
  /// Display-only "오늘 EXP (0–100)" and "주간 EXP (0–700)" are computed from
  /// completion ratios and do NOT touch the persisted exp/badges field.
  static const int expPerPerfectWeek = 1;

  /// Badges needed to advance from [level] to [level]+1 (4 badges = 1 month).
  static int expToNext(int level) => weeksPerLevel * expPerPerfectWeek;

  /// Get the tier for a given level (1-indexed, clamped to 1..12).
  static LevelTier tierFor(int level) {
    final l = level.clamp(1, kLevelTiers.length);
    return kLevelTiers[l - 1];
  }

  /// Highest level reachable.
  static int get maxLevel => kLevelTiers.length;
}
