import 'package:hive/hive.dart';

import '../models/daily_log.dart';
import '../models/level_system.dart';
import '../models/routine.dart';
import '../models/user_profile.dart';
import '../models/week_config.dart';
import 'storage_service.dart';

/// All routine/log/week-config CRUD, plus EXP/level computation.
class RoutineService {
  RoutineService({
    required this.routines,
    required this.weekBox,
    required this.logs,
  });

  final Box<Routine> routines;
  final Box weekBox;
  final Box<DailyLog> logs;

  static const _weekKey = 'config';

  static Future<RoutineService> forUser(String userName) async {
    final r = await StorageService.openRoutines(userName);
    final w = await StorageService.openWeekConfig(userName);
    final l = await StorageService.openLogs(userName);
    final svc = RoutineService(routines: r, weekBox: w, logs: l);
    svc._ensureWeekConfig();
    return svc;
  }

  void _ensureWeekConfig() {
    if (weekBox.get(_weekKey) == null) {
      weekBox.put(_weekKey, WeekConfig.empty().toMap());
    }
  }

  WeekConfig get weekConfig {
    final raw = weekBox.get(_weekKey);
    if (raw is WeekConfig) return raw;
    if (raw is Map) return WeekConfig.fromMap(raw);
    return WeekConfig.empty();
  }

  Future<void> updateWeekConfig(WeekConfig config) async {
    await weekBox.put(_weekKey, config.toMap());
  }

  // -------------------- routine CRUD --------------------

  /// All routines that are not soft-deleted, sorted by `order` then creation time.
  List<Routine> activeRoutines() {
    final list = routines.values.where((r) => !r.isDeleted).toList();
    list.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) return byOrder;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  /// Active routines applicable to a particular weekday (ignores holiday + day overrides).
  List<Routine> activeRoutinesForWeekday(int weekday) {
    return activeRoutines().where((r) => r.appliesOn(weekday)).toList();
  }

  /// Routines that apply to a given date (respecting deletion, applicableDays + per-day overrides).
  List<Routine> routinesForDate(DateTime date) {
    final day = weekConfig.forDate(date);
    if (day.isHoliday) return const [];

    final dateKey = DailyLog.keyFor(date);
    final all = routines.values.where((r) {
      if (r.deletedAt == null) return r.appliesOn(date.weekday);
      final delKey = DailyLog.keyFor(r.deletedAt!);
      if (dateKey.compareTo(delKey) >= 0) return false;
      return r.appliesOn(date.weekday);
    }).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.createdAt.compareTo(b.createdAt);
      });

    final override = day.routineIdsOverride;
    if (override == null) return all;
    final overrideSet = override.toSet();
    return all.where((r) => overrideSet.contains(r.id)).toList();
  }

  Future<Routine> addRoutine({
    required String title,
    String iconKey = 'star',
    List<int>? applicableDaysOfWeek,
  }) async {
    final nextOrder = activeRoutines().fold<int>(0, (m, r) => r.order >= m ? r.order + 1 : m);
    final routine = Routine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      iconKey: iconKey,
      applicableDaysOfWeek: applicableDaysOfWeek,
      order: nextOrder,
    );
    await routines.put(routine.id, routine);
    return routine;
  }

  Future<void> updateRoutine(
    String id, {
    String? title,
    String? iconKey,
    List<int>? applicableDaysOfWeek,
    bool clearApplicableDays = false,
  }) async {
    final r = routines.get(id);
    if (r == null) return;
    await routines.put(
      id,
      r.copyWith(
        title: title,
        iconKey: iconKey,
        applicableDaysOfWeek: applicableDaysOfWeek,
        clearApplicableDays: clearApplicableDays,
      ),
    );
  }

  Future<void> reorderRoutines(List<Routine> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      final r = newOrder[i];
      await routines.put(r.id, r.copyWith(order: i));
    }
  }

  /// Soft-delete a routine: applies to this day and all future days.
  Future<void> deleteRoutineFromDate(String id, DateTime fromDate) async {
    final r = routines.get(id);
    if (r == null) return;
    final updated = r.copyWith(deletedAt: DateTime(fromDate.year, fromDate.month, fromDate.day));
    await routines.put(id, updated);
    final week = weekConfig;
    final next = Map.of(week.days);
    next.updateAll((day, cfg) {
      final override = cfg.routineIdsOverride;
      if (override == null) return cfg;
      return cfg.copyWith(routineIdsOverride: override.where((x) => x != id).toList());
    });
    await updateWeekConfig(WeekConfig(next));
  }

  // -------------------- logs --------------------

  DailyLog logFor(DateTime date) {
    final key = DailyLog.keyFor(date);
    return logs.get(key) ?? DailyLog(dateKey: key);
  }

  /// Toggle done state for a routine on a date.
  Future<ExpResult> toggleDone({
    required UserProfile user,
    required DateTime date,
    required Routine routine,
  }) async {
    final current = logFor(date);
    final isDone = current.completedRoutineIds.contains(routine.id);
    final next = Set<String>.from(current.completedRoutineIds);
    int expDelta = 0;
    final result = ExpResult.zero();

    if (isDone) {
      next.remove(routine.id);
    } else {
      next.add(routine.id);
    }
    var updatedLog = current.copyWith(completedRoutineIds: next);

    final required = routinesForDate(date).map((r) => r.id).toSet();
    final allDone = required.isNotEmpty && next.containsAll(required);
    if (allDone && !current.dailyBonusGranted) {
      updatedLog = updatedLog.copyWith(dailyBonusGranted: true);
    } else if (!allDone && current.dailyBonusGranted) {
      updatedLog = updatedLog.copyWith(dailyBonusGranted: false);
    }

    await logs.put(updatedLog.dateKey, updatedLog);

    if (allDone) {
      final weekStart = _startOfWeek(date);
      final dateKey = DailyLog.keyFor(date); // today or the date being toggled
      bool weekComplete = true;
      bool anyDayRequired = false;
      for (var i = 0; i < 7; i++) {
        final d = weekStart.add(Duration(days: i));
        if (DailyLog.keyFor(d).compareTo(dateKey) > 0) continue; // skip future days
        final dayReq = routinesForDate(d).map((r) => r.id).toSet();
        final dayDone = logFor(d).completedRoutineIds;
        if (dayReq.isEmpty) continue;
        anyDayRequired = true;
        if (!dayDone.containsAll(dayReq)) {
          weekComplete = false;
          break;
        }
      }
      if (!anyDayRequired) weekComplete = false;
      if (weekComplete && !current.weeklyBonusGranted) {
        for (var i = 0; i < 7; i++) {
          final d = weekStart.add(Duration(days: i));
          final k = DailyLog.keyFor(d);
          final existing = logs.get(k) ?? DailyLog(dateKey: k);
          await logs.put(k, existing.copyWith(weeklyBonusGranted: true));
        }
        // New rule: 1 perfect week = 1 badge (4 badges → level up).
        expDelta += 1;
        result.weeklyBonus = 1;
      }
    }

    result.totalExpDelta = expDelta;
    return result;
  }

  ({UserProfile user, int levelsGained}) applyExp(UserProfile user, int delta) {
    var exp = user.exp + delta;
    var level = user.level;
    var levelsGained = 0;
    while (level < LevelSystem.maxLevel && exp >= LevelSystem.expToNext(level)) {
      exp -= LevelSystem.expToNext(level);
      level += 1;
      levelsGained += 1;
    }
    if (exp < 0) exp = 0;
    if (level >= LevelSystem.maxLevel) exp = 0; // cap at max
    final history = List<String>.from(user.levelUpHistory);
    if (levelsGained > 0) {
      history.add(DateTime.now().toIso8601String());
    }
    return (
      user: user.copyWith(level: level, exp: exp, levelUpHistory: history),
      levelsGained: levelsGained,
    );
  }

  double weekProgress(DateTime anyDateInWeek) {
    final weekStart = _startOfWeek(anyDateInWeek);
    int total = 0;
    int done = 0;
    for (var i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final required = routinesForDate(d);
      if (required.isEmpty) continue;
      final completed = logFor(d).completedRoutineIds;
      total += required.length;
      done += required.where((r) => completed.contains(r.id)).length;
    }
    if (total == 0) return 0;
    return done / total;
  }

  /// Character position on the mountain: today's weekday / 7 (Mon=1/7 … Sun=1.0).
  /// If the week is fully in the past, returns 1.0. If fully future, returns 0.0.
  double weekTodayProgress(DateTime anyDateInWeek) {
    final weekStart = _startOfWeek(anyDateInWeek);
    final today = DateTime.now();
    final todayKey = DailyLog.keyFor(today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekEndKey = DailyLog.keyFor(weekEnd);
    final weekStartKey = DailyLog.keyFor(weekStart);

    if (todayKey.compareTo(weekStartKey) < 0) return 0.0; // week in future
    if (todayKey.compareTo(weekEndKey) > 0) return 1.0;   // week in past

    // today is inside this week — map Mon=0.0 … Sun=1.0 onto the 7 anchors
    return (today.weekday - 1) / 6.0;
  }

  /// Per-day completion state for the week containing [anyDateInWeek].
  List<DayStatus> weekStatuses(DateTime anyDateInWeek) {
    final weekStart = _startOfWeek(anyDateInWeek);
    final today = DateTime.now();
    final todayKey = DailyLog.keyFor(today);
    return List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      final isPast = DailyLog.keyFor(d).compareTo(todayKey) < 0;
      final dayIsHoliday = weekConfig.forDate(d).isHoliday;
      if (dayIsHoliday) {
        return DayStatus(date: d, ratio: null, isPast: isPast, isHoliday: true);
      }
      final required = routinesForDate(d);
      if (required.isEmpty) {
        return DayStatus(date: d, ratio: null, isPast: isPast, isHoliday: false);
      }
      final completed = logFor(d).completedRoutineIds;
      final done = required.where((r) => completed.contains(r.id)).length;
      return DayStatus(
        date: d,
        ratio: done / required.length,
        isPast: isPast,
        isHoliday: false,
      );
    });
  }

  /// EXP earned for [date] (0–100), proportional to completion ratio.
  int dailyExp(DateTime date) {
    final list = routinesForDate(date);
    if (list.isEmpty) return 0;
    final done = logFor(date).completedRoutineIds;
    final completed = list.where((r) => done.contains(r.id)).length;
    return ((completed / list.length) * 100).round();
  }

  /// Sum of daily EXP for all 7 days in the week containing [anyDateInWeek].
  int weeklyExpTotal(DateTime anyDateInWeek) {
    final weekStart = _startOfWeek(anyDateInWeek);
    int total = 0;
    for (var i = 0; i < 7; i++) {
      total += dailyExp(weekStart.add(Duration(days: i)));
    }
    return total;
  }

  /// Max weekly EXP = (non-holiday days) × 100.
  int weeklyExpMax(DateTime anyDateInWeek) {
    final weekStart = _startOfWeek(anyDateInWeek);
    int active = 0;
    for (var i = 0; i < 7; i++) {
      if (!weekConfig.forDate(weekStart.add(Duration(days: i))).isHoliday) active++;
    }
    return active * 100;
  }

  DateTime _startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Checks whether the week ending before [today] was fully completed,
  /// and applies an EXP reset if it was not. Returns updated UserProfile,
  /// or null if nothing changed.
  UserProfile? checkWeeklyPenalty(UserProfile user, DateTime today) {
    final currentMondayKey = DailyLog.keyFor(_startOfWeek(today));

    // First ever check: just initialize tracking, no penalty.
    if (user.weekStartDate == null) {
      return user.copyWith(
        weekStartDate: currentMondayKey,
        weekStartExp: user.exp,
        weekStartLevel: user.level,
      );
    }

    // Still in the same week: nothing to do.
    if (user.weekStartDate == currentMondayKey) return null;

    // A new week has started. Evaluate the recorded previous week.
    final parts = user.weekStartDate!.split('-');
    final prevMonday = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final wasComplete = _isWeekComplete(prevMonday);

    // On success: keep current EXP/level. On failure: revert to week-start snapshot.
    final newLevel = wasComplete ? user.level : user.weekStartLevel;
    final newExp   = wasComplete ? user.exp   : user.weekStartExp;

    return user.copyWith(
      level: newLevel,
      exp: newExp,
      weekStartDate: currentMondayKey,
      weekStartExp: newExp,
      weekStartLevel: newLevel,
    );
  }

  /// True if every non-future day in [weekMonday..weekMonday+6] that has routines was 100% done.
  /// Future days and days with no routines are skipped.
  bool _isWeekComplete(DateTime weekMonday) {
    final today = DateTime.now();
    final todayKey = DailyLog.keyFor(today);
    bool anyDayRequired = false;
    for (var i = 0; i < 7; i++) {
      final d = weekMonday.add(Duration(days: i));
      if (DailyLog.keyFor(d).compareTo(todayKey) > 0) continue; // skip future days
      final required = routinesForDate(d).map((r) => r.id).toSet();
      if (required.isEmpty) continue;
      anyDayRequired = true;
      final done = logFor(d).completedRoutineIds;
      if (!done.containsAll(required)) return false;
    }
    return anyDayRequired;
  }
}

class ExpResult {
  int basePerRoutine = 0;
  int dailyBonus = 0;
  int weeklyBonus = 0;
  int totalExpDelta = 0;
  ExpResult.zero();
  bool get hasBonus => dailyBonus != 0 || weeklyBonus != 0;
}

class DayStatus {
  final DateTime date;
  final double? ratio; // null = holiday or no routines
  final bool isPast;
  final bool isHoliday; // explicitly marked holiday in week settings
  DayStatus({required this.date, required this.ratio, required this.isPast, this.isHoliday = false});
  bool get isSuccess => ratio != null && ratio! >= 1.0;
  bool get isFailure => isPast && ratio != null && ratio! < 1.0;
}
