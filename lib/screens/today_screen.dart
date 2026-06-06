import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/icon_catalog.dart';
import '../models/routine.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/character_header.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/routine_edit_dialog.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  OverlayEntry? _levelUpEntry;

  @override
  void dispose() {
    _levelUpEntry?.remove();
    super.dispose();
  }

  Future<void> _addRoutine() async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null) return;
    final today = ref.read(selectedDateProvider);
    final result = await showDialog<RoutineEditResult>(
      context: context,
      builder: (_) => RoutineEditDialog(weekdayForOnlyOption: today.weekday),
    );
    if (result == null) return;
    await svc.addRoutine(
      title: result.title,
      iconKey: result.iconKey,
      applicableDaysOfWeek: result.applicableDays,
    );
    bumpRevision(ref);
  }

  Future<void> _editRoutine(Routine r) async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null) return;
    final result = await showDialog<RoutineEditResult>(
      context: context,
      builder: (_) => RoutineEditDialog(
        initial: r,
        weekdayForOnlyOption: ref.read(selectedDateProvider).weekday,
      ),
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

  Future<void> _deleteRoutine(Routine r, DateTime date) async {
    final loc = ref.read(localeProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppStrings.get(loc, 'today.deleteConfirmTitle')),
        content: Text(AppStrings.fmt(loc, 'today.deleteConfirmBody', {'title': r.title})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(AppStrings.get(loc, 'common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(AppStrings.get(loc, 'common.delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final svc = await ref.read(routineServiceProvider.future);
    await svc?.deleteRoutineFromDate(r.id, date);
    bumpRevision(ref);
  }

  Future<void> _toggle(Routine r, DateTime date) async {
    final svc = await ref.read(routineServiceProvider.future);
    final user = ref.read(authControllerProvider);
    if (svc == null || user == null) return;
    final result = await svc.toggleDone(user: user, date: date, routine: r);
    if (result.totalExpDelta != 0) {
      final applied = svc.applyExp(user, result.totalExpDelta);
      await ref.read(authControllerProvider.notifier).applyUpdate(applied.user);
      if (applied.levelsGained > 0 && mounted) {
        _showLevelUp();
      }
    }
    bumpRevision(ref);
  }

  Future<void> _reorder(List<Routine> routines, int oldIndex, int newIndex) async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final next = List<Routine>.from(routines);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    await svc.reorderRoutines(next);
    bumpRevision(ref);
  }

  void _showLevelUp() {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    _levelUpEntry?.remove();
    final entry = OverlayEntry(
      builder: (_) => LevelUpOverlay(
        newLevel: user.level,
        title: user.rankTitle,
        avatarEmoji: user.avatarEmoji,
        onDismiss: () {
          _levelUpEntry?.remove();
          _levelUpEntry = null;
        },
      ),
    );
    _levelUpEntry = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dataRevisionProvider);
    ref.watch(themeProvider);
    final user = ref.watch(authControllerProvider);
    final asyncSvc = ref.watch(routineServiceProvider);
    final date = ref.watch(selectedDateProvider);
    final loc = ref.watch(localeProvider);

    if (user == null) return const SizedBox.shrink();
    final dailyExpToday = asyncSvc.valueOrNull?.dailyExp(date) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          CharacterHeader(user: user, todayExp: dailyExpToday),
          const SizedBox(height: 14),
          _DateBar(date: date, onPick: (d) => ref.read(selectedDateProvider.notifier).state = d),
          const SizedBox(height: 8),
          Expanded(
            child: asyncSvc.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(AppStrings.fmt(loc, 'common.error', {'e': '$e'}))),
              data: (svc) {
                if (svc == null) return const SizedBox.shrink();
                final routines = svc.routinesForDate(date);
                final log = svc.logFor(date);
                final isHoliday = svc.weekConfig.forDate(date).isHoliday;
                if (isHoliday) {
                  return const _HolidayCard();
                }
                if (routines.isEmpty) {
                  return _EmptyCard(onAdd: _addRoutine);
                }
                final completed = routines
                    .where((r) => log.completedRoutineIds.contains(r.id))
                    .length;
                return Column(
                  children: [
                    _ProgressStrip(completed: completed, total: routines.length),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: routines.length,
                        onReorder: (o, n) => _reorder(routines, o, n),
                        padding: const EdgeInsets.only(bottom: 88),
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, anim) => Material(
                          color: Colors.transparent,
                          child: child,
                        ),
                        itemBuilder: (c, i) {
                          final r = routines[i];
                          final done = log.completedRoutineIds.contains(r.id);
                          return Padding(
                            key: ValueKey(r.id),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RoutineCard(
                              routine: r,
                              done: done,
                              index: i,
                              onToggle: () => _toggle(r, date),
                              onEdit: () => _editRoutine(r),
                              onDelete: () => _deleteRoutine(r, date),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBar extends ConsumerWidget {
  const _DateBar({required this.date, required this.onPick});
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    return Row(
      children: [
        IconButton(
          onPressed: () => onPick(date.subtract(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: date,
              );
              if (picked != null) {
                onPick(DateTime(picked.year, picked.month, picked.day));
              }
            },
            child: Center(
              child: Column(
                children: [
                  Text(
                    DateFormat(loc.dateFormat, loc.intlLocale).format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  if (!isToday)
                    TextButton(
                      onPressed: () => onPick(today),
                      child: Text(AppStrings.get(loc, 'today.toToday')),
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => onPick(date.add(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : completed / total;
    final isFull = ratio >= 1.0;
    final barColor = isFull ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: ProgressIndicatorTheme(
                  data: ProgressIndicatorThemeData(
                    color: barColor,
                    linearTrackColor: AppColors.primary.withValues(alpha: 0.18),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 500),
                    builder: (c, v, _) => LinearProgressIndicator(value: v),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$completed / $total',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({
    required this.routine,
    required this.done,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final Routine routine;
  final bool done;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _dayKeys = ['day.mon', 'day.tue', 'day.wed', 'day.thu', 'day.fri', 'day.sat', 'day.sun'];

  String _daysLabel(List<int> days, AppLocale loc) {
    if (days.length == 7) return AppStrings.get(loc, 'day.everyday');
    final sorted = [...days]..sort();
    return sorted.map((d) => AppStrings.get(loc, _dayKeys[d - 1])).join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    final icon = iconByKey(routine.iconKey);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      decoration: BoxDecoration(
        color: done ? AppColors.success.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? AppColors.success : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: done ? 0.0 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 28,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.menu, color: AppColors.subtle, size: 20),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: icon.color.withValues(alpha: icon.backgroundAlpha),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: buildIconWidget(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.subtle : AppColors.text,
                    ),
                  ),
                  if (routine.applicableDaysOfWeek != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _daysLabel(routine.applicableDaysOfWeek!, loc),
                        style: TextStyle(fontSize: 11, color: AppColors.subtle),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.subtle,
              tooltip: AppStrings.get(loc, 'today.edit'),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.subtle,
              tooltip: AppStrings.get(loc, 'today.delete'),
            ),
            const SizedBox(width: 2),
            _DoneButton(done: done, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _DoneButton extends ConsumerWidget {
  const _DoneButton({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 56,
        height: 36,
        decoration: BoxDecoration(
          color: done ? AppColors.success : AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : Text(
                AppStrings.get(loc, 'today.done'),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

class _EmptyCard extends ConsumerWidget {
  const _EmptyCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terrain, size: 60, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                AppStrings.get(loc, 'today.empty.title'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.get(loc, 'today.empty.body'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.subtle, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(AppStrings.get(loc, 'today.add')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HolidayCard extends ConsumerWidget {
  const _HolidayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.beach_access, size: 60, color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                AppStrings.get(loc, 'today.holiday.title'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.get(loc, 'today.holiday.body'),
                style: TextStyle(color: AppColors.subtle, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Allows other screens (FAB on shell) to trigger the add dialog.
class TodayActions {
  static Future<void> addRoutine(BuildContext context, WidgetRef ref) async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null || !context.mounted) return;
    final today = ref.read(selectedDateProvider);
    final result = await showDialog<RoutineEditResult>(
      context: context,
      builder: (_) => RoutineEditDialog(weekdayForOnlyOption: today.weekday),
    );
    if (result == null) return;
    await svc.addRoutine(
      title: result.title,
      iconKey: result.iconKey,
      applicableDaysOfWeek: result.applicableDays,
    );
    bumpRevision(ref);
  }
}
