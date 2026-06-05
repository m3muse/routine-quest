import 'package:hive/hive.dart';

/// Per-day completion log. Key is "YYYY-MM-DD".
class DailyLog {
  final String dateKey; // YYYY-MM-DD
  final Set<String> completedRoutineIds;
  final bool dailyBonusGranted;
  final bool weeklyBonusGranted; // true if the week containing this date got the weekly bonus

  DailyLog({
    required this.dateKey,
    Set<String>? completedRoutineIds,
    this.dailyBonusGranted = false,
    this.weeklyBonusGranted = false,
  }) : completedRoutineIds = completedRoutineIds ?? <String>{};

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'completedRoutineIds': completedRoutineIds.toList(),
        'dailyBonusGranted': dailyBonusGranted,
        'weeklyBonusGranted': weeklyBonusGranted,
      };

  factory DailyLog.fromMap(Map map) => DailyLog(
        dateKey: map['dateKey'] as String,
        completedRoutineIds:
            ((map['completedRoutineIds'] as List?) ?? const [])
                .cast<String>()
                .toSet(),
        dailyBonusGranted: (map['dailyBonusGranted'] as bool?) ?? false,
        weeklyBonusGranted: (map['weeklyBonusGranted'] as bool?) ?? false,
      );

  DailyLog copyWith({
    Set<String>? completedRoutineIds,
    bool? dailyBonusGranted,
    bool? weeklyBonusGranted,
  }) =>
      DailyLog(
        dateKey: dateKey,
        completedRoutineIds: completedRoutineIds ?? this.completedRoutineIds,
        dailyBonusGranted: dailyBonusGranted ?? this.dailyBonusGranted,
        weeklyBonusGranted: weeklyBonusGranted ?? this.weeklyBonusGranted,
      );

  static String keyFor(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class DailyLogAdapter extends TypeAdapter<DailyLog> {
  @override
  final int typeId = 3;

  @override
  DailyLog read(BinaryReader reader) => DailyLog.fromMap(reader.readMap());

  @override
  void write(BinaryWriter writer, DailyLog obj) =>
      writer.writeMap(obj.toMap());
}
