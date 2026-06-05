import 'package:flutter/material.dart';

enum Archetype { steady, smart, beauty }

extension ArchetypeLabel on Archetype {
  String get label {
    switch (this) {
      case Archetype.steady:
        return '느리지만 꾸준한 자';
      case Archetype.smart:
        return '똑똑하고 빠른 자';
      case Archetype.beauty:
        return '눈부신 매력의 자';
    }
  }

  String get subtitle {
    switch (this) {
      case Archetype.steady:
        return '연속 달성 보너스 +20%';
      case Archetype.smart:
        return '학습 루틴 EXP +20%';
      case Archetype.beauty:
        return '일일 EXP 보너스 +10%';
    }
  }

  IconData get icon {
    switch (this) {
      case Archetype.steady:
        return Icons.eco;
      case Archetype.smart:
        return Icons.bolt;
      case Archetype.beauty:
        return Icons.auto_awesome;
    }
  }
}

enum HairStyle { shortStraight, mediumWavy, longTied, longWavy, ponytail, cropped }
enum Accessory { none, glasses, crown, flowerCrown, hood, headband }

class CharacterDef {
  final String id;
  final String defaultName;
  final bool isFemale;
  final Archetype archetype;
  /// Short personality blurb shown in the selection banner.
  final String personality;
  final Color skin;
  final Color hair;
  final HairStyle hairStyle;
  final Color outfitMain;
  final Color outfitAccent;
  final Accessory accessory;
  final Color aura; // glow color when selected

  const CharacterDef({
    required this.id,
    required this.defaultName,
    required this.isFemale,
    required this.archetype,
    required this.personality,
    required this.skin,
    required this.hair,
    required this.hairStyle,
    required this.outfitMain,
    required this.outfitAccent,
    required this.accessory,
    required this.aura,
  });

  /// Asset path for full-body image. May or may not exist on disk.
  String get fullBodyAsset => 'assets/characters/$id.png';
  /// Asset path for portrait image (head/shoulders).
  String get portraitAsset => 'assets/characters/portraits/$id.png';
  /// Asset path for side-view climbing pose.
  String get climbingAsset => 'assets/characters/climbing/$id.png';
}

/// All 6 selectable characters.
const List<CharacterDef> kCharacters = [
  // === 여 ===
  CharacterDef(
    id: 'f_steady',
    defaultName: '리나',
    isFemale: true,
    archetype: Archetype.steady,
    personality: '조용하고 끈기 있는, 한 번 마음먹으면 끝까지 가는 아이',
    skin: Color(0xFFF6D7B0),
    hair: Color(0xFF6D4A2A),
    hairStyle: HairStyle.longTied,
    outfitMain: Color(0xFF4E7C4B),
    outfitAccent: Color(0xFFA1C295),
    accessory: Accessory.flowerCrown,
    aura: Color(0xFFA8D5A2),
  ),
  CharacterDef(
    id: 'f_smart',
    defaultName: '밀라',
    isFemale: true,
    archetype: Archetype.smart,
    personality: '호기심 많고 머리 회전 빠른, 항상 한발 앞서가는 아이',
    skin: Color(0xFFF6D9BC),
    hair: Color(0xFF2A2533),
    hairStyle: HairStyle.shortStraight,
    outfitMain: Color(0xFF3A5BAA),
    outfitAccent: Color(0xFFE0B14A),
    accessory: Accessory.glasses,
    aura: Color(0xFF8BB6FF),
  ),
  CharacterDef(
    id: 'f_beauty',
    defaultName: '제시카',
    isFemale: true,
    archetype: Archetype.beauty,
    personality: '덤벙대지만 낙관적인, 옆에 있으면 기분 좋아지는 아이',
    skin: Color(0xFFFCE0C4),
    hair: Color(0xFFE9C770),
    hairStyle: HairStyle.longWavy,
    outfitMain: Color(0xFFD0539B),
    outfitAccent: Color(0xFFF4C3DC),
    accessory: Accessory.crown,
    aura: Color(0xFFF6B5D6),
  ),
  // === 남 ===
  CharacterDef(
    id: 'm_steady',
    defaultName: '루이',
    isFemale: false,
    archetype: Archetype.steady,
    personality: '말은 적지만 묵묵히 든든한, 어려울 때 옆에 있는 아이',
    skin: Color(0xFFE9C39B),
    hair: Color(0xFF4B3A2A),
    hairStyle: HairStyle.cropped,
    outfitMain: Color(0xFF7B4B2A),
    outfitAccent: Color(0xFFCBB69A),
    accessory: Accessory.headband,
    aura: Color(0xFFD1B58A),
  ),
  CharacterDef(
    id: 'm_smart',
    defaultName: '엘빈',
    isFemale: false,
    archetype: Archetype.smart,
    personality: '까칠한 천재 타입, 알고 보면 다정한 아이',
    skin: Color(0xFFF0CDA8),
    hair: Color(0xFFB6BCC7),
    hairStyle: HairStyle.mediumWavy,
    outfitMain: Color(0xFF5B3F8C),
    outfitAccent: Color(0xFFD4A24C),
    accessory: Accessory.hood,
    aura: Color(0xFFB29BE5),
  ),
  CharacterDef(
    id: 'm_beauty',
    defaultName: '데이빗',
    isFemale: false,
    archetype: Archetype.beauty,
    personality: '허세 부리지만 의리 있는, 자유로운 영혼의 아이',
    skin: Color(0xFFEFC9A5),
    hair: Color(0xFF1F1A1A),
    hairStyle: HairStyle.shortStraight,
    outfitMain: Color(0xFFE0E2E8),
    outfitAccent: Color(0xFFD4A24C),
    accessory: Accessory.none,
    aura: Color(0xFFE9D08C),
  ),
];

CharacterDef characterById(String? id) =>
    kCharacters.firstWhere((c) => c.id == id, orElse: () => kCharacters.first);
