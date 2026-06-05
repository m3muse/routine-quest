import 'package:hive/hive.dart';

/// A reusable routine template. The same routine can appear on multiple days.
class Routine {
  final String id;
  final String title;
  final String iconKey;
  final DateTime createdAt;
  final DateTime? deletedAt; // Soft delete - applies to all future days
  /// If non-null, this routine only applies on the listed weekdays (1=Mon..7=Sun).
  /// null = applies every (non-holiday) day.
  final List<int>? applicableDaysOfWeek;
  /// Sort order within the active routine list.
  final int order;

  Routine({
    required this.id,
    required this.title,
    this.iconKey = 'star',
    DateTime? createdAt,
    this.deletedAt,
    this.applicableDaysOfWeek,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'iconKey': iconKey,
        'createdAt': createdAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'applicableDaysOfWeek': applicableDaysOfWeek,
        'order': order,
      };

  factory Routine.fromMap(Map map) {
    final daysRaw = map['applicableDaysOfWeek'];
    return Routine(
      id: map['id'] as String,
      title: map['title'] as String,
      // backward compat: old `emoji` -> iconKey is 'star'
      iconKey: (map['iconKey'] as String?) ?? 'star',
      createdAt: DateTime.parse(map['createdAt'] as String),
      deletedAt: map['deletedAt'] == null
          ? null
          : DateTime.parse(map['deletedAt'] as String),
      applicableDaysOfWeek: daysRaw == null
          ? null
          : (daysRaw as List).map((e) => (e as num).toInt()).toList(),
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Routine copyWith({
    String? title,
    String? iconKey,
    DateTime? deletedAt,
    List<int>? applicableDaysOfWeek,
    bool clearApplicableDays = false,
    int? order,
  }) =>
      Routine(
        id: id,
        title: title ?? this.title,
        iconKey: iconKey ?? this.iconKey,
        createdAt: createdAt,
        deletedAt: deletedAt ?? this.deletedAt,
        applicableDaysOfWeek: clearApplicableDays
            ? null
            : (applicableDaysOfWeek ?? this.applicableDaysOfWeek),
        order: order ?? this.order,
      );

  bool get isDeleted => deletedAt != null;
  bool appliesOn(int weekday) =>
      applicableDaysOfWeek == null || applicableDaysOfWeek!.contains(weekday);
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 1;

  @override
  Routine read(BinaryReader reader) => Routine.fromMap(reader.readMap());

  @override
  void write(BinaryWriter writer, Routine obj) => writer.writeMap(obj.toMap());
}
