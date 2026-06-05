import 'package:hive/hive.dart';

/// Configuration for each day of the week.
/// dayOfWeek: 1=Monday ... 7=Sunday (matching DateTime.weekday)
class DayConfig {
  final int dayOfWeek;
  final bool isHoliday;
  final List<String>? routineIdsOverride; // null = all active routines

  const DayConfig({
    required this.dayOfWeek,
    this.isHoliday = false,
    this.routineIdsOverride,
  });

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'isHoliday': isHoliday,
        'routineIdsOverride': routineIdsOverride,
      };

  factory DayConfig.fromMap(Map map) => DayConfig(
        dayOfWeek: (map['dayOfWeek'] as num).toInt(),
        isHoliday: (map['isHoliday'] as bool?) ?? false,
        routineIdsOverride:
            (map['routineIdsOverride'] as List?)?.cast<String>(),
      );

  DayConfig copyWith({bool? isHoliday, List<String>? routineIdsOverride, bool clearOverride = false}) =>
      DayConfig(
        dayOfWeek: dayOfWeek,
        isHoliday: isHoliday ?? this.isHoliday,
        routineIdsOverride: clearOverride
            ? null
            : (routineIdsOverride ?? this.routineIdsOverride),
      );
}

class WeekConfig {
  final Map<int, DayConfig> days;

  WeekConfig(this.days);

  factory WeekConfig.empty() => WeekConfig({
        for (var i = 1; i <= 7; i++) i: DayConfig(dayOfWeek: i),
      });

  Map<String, dynamic> toMap() => {
        'days': days.map((k, v) => MapEntry(k.toString(), v.toMap())),
      };

  factory WeekConfig.fromMap(Map map) {
    final raw = (map['days'] as Map?) ?? {};
    final result = <int, DayConfig>{};
    for (var i = 1; i <= 7; i++) {
      final key = i.toString();
      if (raw.containsKey(key)) {
        result[i] = DayConfig.fromMap(raw[key] as Map);
      } else {
        result[i] = DayConfig(dayOfWeek: i);
      }
    }
    return WeekConfig(result);
  }

  DayConfig forDate(DateTime date) => days[date.weekday]!;

  WeekConfig updateDay(int dayOfWeek, DayConfig config) {
    final next = Map<int, DayConfig>.from(days);
    next[dayOfWeek] = config;
    return WeekConfig(next);
  }
}

class WeekConfigAdapter extends TypeAdapter<WeekConfig> {
  @override
  final int typeId = 2;

  @override
  WeekConfig read(BinaryReader reader) => WeekConfig.fromMap(reader.readMap());

  @override
  void write(BinaryWriter writer, WeekConfig obj) =>
      writer.writeMap(obj.toMap());
}
