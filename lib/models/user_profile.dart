import 'package:hive/hive.dart';

import 'level_system.dart';

class UserProfile {
  final String name; // login id (lowercased on lookup)
  final String displayName; // character/display name
  final String characterId;
  final String passwordHash;
  final int level;
  final int exp;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> levelUpHistory;

  /// EXP at the start of the current tracking week.
  final int weekStartExp;
  /// Level at the start of the current tracking week.
  final int weekStartLevel;
  /// ISO date string of the Monday of the tracked week (null = not yet initialized).
  final String? weekStartDate;

  UserProfile({
    required this.name,
    required this.passwordHash,
    required this.characterId,
    String? displayName,
    this.level = 1,
    this.exp = 0,
    DateTime? createdAt,
    this.lastLoginAt,
    this.levelUpHistory = const [],
    this.weekStartExp = 0,
    this.weekStartLevel = 1,
    this.weekStartDate,
  })  : displayName = (displayName != null && displayName.trim().isNotEmpty) ? displayName.trim() : name,
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'displayName': displayName,
        'characterId': characterId,
        'passwordHash': passwordHash,
        'level': level,
        'exp': exp,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'levelUpHistory': levelUpHistory,
        'weekStartExp': weekStartExp,
        'weekStartLevel': weekStartLevel,
        'weekStartDate': weekStartDate,
      };

  factory UserProfile.fromMap(Map map) => UserProfile(
        name: map['name'] as String,
        displayName: map['displayName'] as String?,
        characterId: (map['characterId'] as String?) ?? 'f_steady',
        passwordHash: map['passwordHash'] as String,
        level: (map['level'] as num?)?.toInt() ?? 1,
        exp: (map['exp'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastLoginAt: map['lastLoginAt'] == null
            ? null
            : DateTime.parse(map['lastLoginAt'] as String),
        levelUpHistory: (map['levelUpHistory'] as List?)?.cast<String>() ?? const [],
        weekStartExp: (map['weekStartExp'] as num?)?.toInt() ?? 0,
        weekStartLevel: (map['weekStartLevel'] as num?)?.toInt() ?? 1,
        weekStartDate: map['weekStartDate'] as String?,
      );

  UserProfile copyWith({
    String? displayName,
    String? characterId,
    String? passwordHash,
    int? level,
    int? exp,
    DateTime? lastLoginAt,
    List<String>? levelUpHistory,
    int? weekStartExp,
    int? weekStartLevel,
    String? weekStartDate,
  }) =>
      UserProfile(
        name: name,
        displayName: displayName ?? this.displayName,
        characterId: characterId ?? this.characterId,
        passwordHash: passwordHash ?? this.passwordHash,
        level: level ?? this.level,
        exp: exp ?? this.exp,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        levelUpHistory: levelUpHistory ?? this.levelUpHistory,
        weekStartExp: weekStartExp ?? this.weekStartExp,
        weekStartLevel: weekStartLevel ?? this.weekStartLevel,
        weekStartDate: weekStartDate ?? this.weekStartDate,
      );

  int get expToNext => LevelSystem.expToNext(level);
  double get expProgress => (exp / expToNext).clamp(0.0, 1.0);

  /// Korean tier title based on 12-step level system.
  String get rankTitle => LevelSystem.tierFor(level).title;

  /// Legacy fallback: emoji-style avatar based on rank (used by level-up overlay).
  String get avatarEmoji {
    if (level >= 12) return '👑';
    if (level >= 10) return '🛡️';
    if (level >= 8) return '⚔️';
    if (level >= 5) return '🌟';
    if (level >= 3) return '🌿';
    return '🌱';
  }

  /// How many complete weeks are needed before reaching the next level.
  int get weeksToNext {
    final expRemaining = expToNext - exp;
    final weeks = (expRemaining / LevelSystem.expPerPerfectWeek).ceil();
    return weeks.clamp(0, LevelSystem.weeksPerLevel);
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final map = reader.readMap();
    return UserProfile.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeMap(obj.toMap());
  }
}
