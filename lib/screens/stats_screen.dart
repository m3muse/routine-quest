import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../services/routine_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/character_header.dart';
import '../widgets/mountain_climb.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    final user = ref.watch(authControllerProvider);
    final asyncSvc = ref.watch(routineServiceProvider);
    final date = ref.watch(selectedDateProvider);
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);

    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          CharacterHeader(user: user),
          const SizedBox(height: 18),
          asyncSvc.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(AppStrings.fmt(loc, 'common.error', {'e': '$e'})),
            data: (svc) {
              if (svc == null) return const SizedBox.shrink();
              final statuses = svc.weekStatuses(date);
              final weeklyExp = svc.weeklyExpTotal(date);
              final weeklyMax = svc.weeklyExpMax(date);
              final weekProg = svc.weekProgress(date);
              return Column(
                children: [
                  _SectionTitle(icon: Icons.terrain, label: s('stats.sectionMountain')),
                  const SizedBox(height: 10),
                  MountainClimb(
                    progress: weekProg,
                    dayStatuses: statuses,
                    locale: loc,
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(icon: Icons.bar_chart, label: s('stats.sectionChart')),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
                      child: SizedBox(
                        height: 220,
                        child: _DailyBarChart(statuses: statuses, locale: loc),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WeeklyExpBar(weeklyExp: weeklyExp, weeklyMax: weeklyMax),
                  const SizedBox(height: 18),
                  _StatsTiles(svc: svc, date: date, level: user.level, exp: user.exp),
                  const SizedBox(height: 12),
                  _DayOfYearCard(loc: loc),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            )),
      ],
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.statuses, required this.locale});
  final List<DayStatus> statuses;
  final AppLocale locale;

  static const _dayKeys = ['day.mon', 'day.tue', 'day.wed', 'day.thu', 'day.fri', 'day.sat', 'day.sun'];

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 1.0,
        minY: 0,
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (v) => FlLine(
            color: AppColors.subtle.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 0.5,
              getTitlesWidget: (v, _) => Text(
                '${(v * 100).toInt()}%',
                style: TextStyle(fontSize: 10, color: AppColors.subtle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= 7) return const SizedBox.shrink();
                final isHoliday = statuses[i].isHoliday;
                final isToday = _isToday(statuses[i].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.get(locale, _dayKeys[i]),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isToday
                              ? Colors.red
                              : isHoliday
                                  ? AppColors.subtle
                                  : AppColors.text,
                        ),
                      ),
                      if (isHoliday)
                        Text(
                          AppStrings.get(locale, 'stats.holidayMark'),
                          style: TextStyle(fontSize: 9, color: AppColors.subtle),
                        )
                      else if (isToday)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final status = statuses[i];
          final isHoliday = status.isHoliday;
          final isToday = _isToday(status.date);
          final r = status.ratio ?? 0.0;
          final isComplete = !isHoliday && r >= 1.0;
          // Complete: solid green. Holiday: dark grey. Partial: gradient greens. Empty: very light.
          final Color? solidColor = isComplete
              ? const Color(0xFF52B16A)
              : isHoliday
                  ? const Color(0xFF9E9E9E)
                  : null;
          final List<Color>? gradientColors = solidColor != null
              ? null
              : r >= 0.5
                  ? [const Color(0xFFB7E0A6), const Color(0xFF6FB85F)]
                  : r > 0
                      ? [const Color(0xFFE0E8C9), const Color(0xFFA7D78A)]
                      : [AppColors.subtle.withValues(alpha: 0.15), AppColors.subtle.withValues(alpha: 0.08)];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: isHoliday ? 1.0 : (r == 0 ? 0.0 : r),
                width: 26,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: isHoliday ? const Radius.circular(12) : const Radius.circular(6),
                ),
                color: solidColor,
                gradient: solidColor == null && gradientColors != null
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                borderSide: isToday && !isComplete
                    ? const BorderSide(color: Colors.red, width: 2.5)
                    : BorderSide.none,
                backDrawRodData: BackgroundBarChartRodData(
                  show: !isHoliday,
                  toY: 1.0,
                  color: AppColors.subtle.withValues(alpha: 0.10),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _WeeklyExpBar extends ConsumerWidget {
  const _WeeklyExpBar({required this.weeklyExp, required this.weeklyMax});
  final int weeklyExp;
  final int weeklyMax;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final ratio = weeklyMax == 0 ? 0.0 : weeklyExp / weeklyMax;
    final isFull = weeklyExp >= weeklyMax && weeklyMax > 0;
    final barColor = isFull ? AppColors.success : AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  s('stats.weeklyExpLabel'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '$weeklyExp / $weeklyMax',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: barColor,
                  ),
                ),
                Text(
                  ' EXP',
                  style: TextStyle(fontSize: 12, color: AppColors.subtle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 600),
                builder: (c, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTiles extends ConsumerWidget {
  const _StatsTiles({
    required this.svc,
    required this.date,
    required this.level,
    required this.exp,
  });
  final RoutineService svc;
  final DateTime date;
  final int level;
  final int exp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final activeCount = svc.activeRoutines().length;
    final streak = _calcStreak(svc, date);
    return Row(
      children: [
        Expanded(child: _Tile(title: s('stats.tileLevel'), value: 'Lv $level', icon: Icons.shield)),
        const SizedBox(width: 10),
        Expanded(child: _Tile(title: s('stats.tileStreak'), value: '$streak${s('stats.streakUnit')}', icon: Icons.local_fire_department)),
        const SizedBox(width: 10),
        Expanded(child: _Tile(title: s('stats.tileRoutines'), value: '$activeCount${s('stats.routinesUnit')}', icon: Icons.checklist)),
      ],
    );
  }

  int _calcStreak(RoutineService svc, DateTime date) {
    int streak = 0;
    var d = DateTime(date.year, date.month, date.day);
    while (true) {
      final required = svc.routinesForDate(d).map((r) => r.id).toSet();
      if (required.isEmpty) {
        d = d.subtract(const Duration(days: 1));
        if (streak == 0 && d.isBefore(date.subtract(const Duration(days: 30)))) break;
        continue;
      }
      final done = svc.logFor(d).completedRoutineIds;
      if (!done.containsAll(required)) break;
      streak += 1;
      d = d.subtract(const Duration(days: 1));
      if (streak > 365) break;
    }
    return streak;
  }
}

class _DayOfYearCard extends StatelessWidget {
  const _DayOfYearCard({required this.loc});
  final AppLocale loc;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
    final yearDays = DateTime(now.year, 12, 31).difference(DateTime(now.year)).inDays + 1;
    final progress = dayOfYear / yearDays;
    final dateStr = DateFormat('yyyy. M. d', loc.intlLocale).format(now);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppStrings.fmt(loc, 'today.dayOfYear', {'n': '$dayOfYear', 'total': '$yearDays'}),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: AppColors.subtle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                builder: (c, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.text,
                )),
            const SizedBox(height: 2),
            Text(title,
                style: TextStyle(fontSize: 11, color: AppColors.subtle)),
          ],
        ),
      ),
    );
  }
}
