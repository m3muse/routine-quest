import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/strings.dart';
import '../models/icon_catalog.dart';
import '../models/routine.dart';
import '../models/week_config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/routine_edit_dialog.dart';

class WeekSettingsScreen extends ConsumerWidget {
  const WeekSettingsScreen({super.key});

  static const _dayLongKeys = [
    'dayLong.mon', 'dayLong.tue', 'dayLong.wed', 'dayLong.thu',
    'dayLong.fri', 'dayLong.sat', 'dayLong.sun',
  ];

  Future<void> _addForDay(BuildContext context, WidgetRef ref, int day) async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null || !context.mounted) return;
    final result = await showDialog<RoutineEditResult>(
      context: context,
      builder: (_) => RoutineEditDialog(lockedToWeekday: day),
    );
    if (result == null) return;
    await svc.addRoutine(
      title: result.title,
      iconKey: result.iconKey,
      applicableDaysOfWeek: result.applicableDays,
    );
    bumpRevision(ref);
  }

  Future<void> _editRoutine(BuildContext context, WidgetRef ref, Routine r) async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null || !context.mounted) return;
    final result = await showDialog<RoutineEditResult>(
      context: context,
      builder: (_) => RoutineEditDialog(initial: r),
    );
    if (result == null) return;
    await svc.updateRoutine(
      r.id,
      title: result.title,
      iconKey: result.iconKey,
      applicableDaysOfWeek: result.applicableDays,
      clearApplicableDays: result.applicableDays == null,
    );
    bumpRevision(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    ref.watch(themeProvider);
    final asyncSvc = ref.watch(routineServiceProvider);
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);

    return asyncSvc.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppStrings.fmt(loc, 'common.error', {'e': '$e'}))),
      data: (svc) {
        if (svc == null) return const SizedBox.shrink();
        final allRoutines = svc.activeRoutines();
        final config = svc.weekConfig;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s('week.intro'),
                        style: TextStyle(
                          color: AppColors.text.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 1; i <= 7; i++)
              _DayCard(
                dayOfWeek: i,
                label: s(_dayLongKeys[i - 1]),
                config: config.days[i]!,
                allRoutines: allRoutines,
                onUpdate: (cfg) async {
                  await svc.updateWeekConfig(config.updateDay(i, cfg));
                  bumpRevision(ref);
                },
                onAdd: () => _addForDay(context, ref, i),
                onEdit: (r) => _editRoutine(context, ref, r),
              ),
          ],
        );
      },
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.dayOfWeek,
    required this.label,
    required this.config,
    required this.allRoutines,
    required this.onUpdate,
    required this.onAdd,
    required this.onEdit,
  });
  final int dayOfWeek;
  final String label;
  final DayConfig config;
  final List<Routine> allRoutines;
  final ValueChanged<DayConfig> onUpdate;
  final VoidCallback onAdd;
  final ValueChanged<Routine> onEdit;

  List<Routine> get _appliedRoutines {
    final byDay = allRoutines.where((r) => r.appliesOn(dayOfWeek)).toList();
    final override = config.routineIdsOverride;
    if (override == null) return byDay;
    final set = override.toSet();
    return byDay.where((r) => set.contains(r.id)).toList();
  }

  List<Routine> get _excludedRoutines {
    final byDay = allRoutines.where((r) => r.appliesOn(dayOfWeek)).toList();
    final override = config.routineIdsOverride;
    if (override == null) return const [];
    final set = override.toSet();
    return byDay.where((r) => !set.contains(r.id)).toList();
  }

  void _toggleInclude(Routine r, bool include) {
    final byDay = allRoutines.where((x) => x.appliesOn(dayOfWeek)).map((x) => x.id).toSet();
    final current = (config.routineIdsOverride ?? byDay.toList()).toSet();
    if (include) {
      current.add(r.id);
    } else {
      current.remove(r.id);
    }
    if (current.length == byDay.length && current.containsAll(byDay)) {
      onUpdate(config.copyWith(clearOverride: true));
    } else {
      onUpdate(config.copyWith(routineIdsOverride: current.toList()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final applied = _appliedRoutines;
    final excluded = _excludedRoutines;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: config.isHoliday
                          ? AppColors.accent.withValues(alpha: 0.25)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label[0],
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: config.isHoliday
                            ? AppColors.accentDeep
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  Switch(
                    value: !config.isHoliday,
                    onChanged: (v) => onUpdate(config.copyWith(isHoliday: !v)),
                  ),
                  Text(
                    config.isHoliday ? s('week.holiday') : s('week.active'),
                    style: TextStyle(
                      fontSize: 12,
                      color: config.isHoliday ? AppColors.accentDeep : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (!config.isHoliday) ...[
                const SizedBox(height: 10),
                if (applied.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      s('week.empty'),
                      style: TextStyle(color: AppColors.subtle, fontSize: 12),
                    ),
                  )
                else
                  Column(
                    children: applied.map((r) => _AppliedRoutineRow(
                          routine: r,
                          onEdit: () => onEdit(r),
                          onExclude: () => _toggleInclude(r, false),
                        )).toList(),
                  ),
                if (excluded.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    s('week.excluded'),
                    style: TextStyle(fontSize: 11, color: AppColors.subtle),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: excluded.map((r) {
                      final ic = iconByKey(r.iconKey);
                      return ActionChip(
                        avatar: buildIconWidget(ic, size: 16),
                        label: Text(r.title),
                        onPressed: () => _toggleInclude(r, true),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppStrings.fmt(loc, 'week.addForDay', {'day': label})),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppliedRoutineRow extends ConsumerWidget {
  const _AppliedRoutineRow({
    required this.routine,
    required this.onEdit,
    required this.onExclude,
  });
  final Routine routine;
  final VoidCallback onEdit;
  final VoidCallback onExclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final ic = iconByKey(routine.iconKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ic.color.withValues(alpha: ic.backgroundAlpha),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: buildIconWidget(ic, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(routine.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: s('today.edit'),
            color: AppColors.subtle,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onExclude,
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            tooltip: s('week.excludeDay'),
            color: AppColors.subtle,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
