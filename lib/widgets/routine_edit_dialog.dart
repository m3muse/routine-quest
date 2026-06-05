import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/icon_catalog.dart';
import '../models/routine.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class RoutineEditResult {
  final String title;
  final String iconKey;
  /// null = every day. Non-null list = restricted to those weekdays (1..7).
  final List<int>? applicableDays;
  RoutineEditResult({
    required this.title,
    required this.iconKey,
    required this.applicableDays,
  });
}

/// Dialog used to create or edit a routine.
class RoutineEditDialog extends ConsumerStatefulWidget {
  const RoutineEditDialog({
    super.key,
    this.initial,
    this.weekdayForOnlyOption,
    this.lockedToWeekday,
  });

  final Routine? initial;
  final int? weekdayForOnlyOption;
  final int? lockedToWeekday;

  @override
  ConsumerState<RoutineEditDialog> createState() => _RoutineEditDialogState();
}

enum _Scope { everyDay, todayOnly, custom }

class _RoutineEditDialogState extends ConsumerState<RoutineEditDialog> {
  late TextEditingController _title;
  late String _iconKey;
  late _Scope _scope;
  late Set<int> _customDays;
  String _category = 'cat.study';

  static const _dayKeys = ['day.mon', 'day.tue', 'day.wed', 'day.thu', 'day.fri', 'day.sat', 'day.sun'];
  static const _dayLongKeys = ['dayLong.mon', 'dayLong.tue', 'dayLong.wed', 'dayLong.thu', 'dayLong.fri', 'dayLong.sat', 'dayLong.sun'];

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _title = TextEditingController(text: init?.title ?? '');
    _iconKey = init?.iconKey ?? 'star';
    if (widget.lockedToWeekday != null) {
      _scope = _Scope.custom;
      _customDays = {widget.lockedToWeekday!};
    } else if (init == null) {
      _scope = _Scope.everyDay;
      _customDays = {};
    } else if (init.applicableDaysOfWeek == null) {
      _scope = _Scope.everyDay;
      _customDays = {};
    } else {
      _scope = _Scope.custom;
      _customDays = init.applicableDaysOfWeek!.toSet();
    }
    _category = iconByKey(_iconKey).category;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<int>? _resolveDays() {
    switch (_scope) {
      case _Scope.everyDay:
        return null;
      case _Scope.todayOnly:
        return [widget.weekdayForOnlyOption!];
      case _Scope.custom:
        if (_customDays.isEmpty || _customDays.length == 7) return null;
        final list = _customDays.toList()..sort();
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? s('routine.editTitle') : s('routine.newTitle')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s('routine.titleHint'),
                ),
              ),
              const SizedBox(height: 14),
              Text(s('routine.icon'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: iconCategories()
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(s(c)),
                              selected: _category == c,
                              onSelected: (_) => setState(() => _category = c),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: iconsInCategory(_category).map((opt) {
                  final selected = opt.key == _iconKey;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = opt.key),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: opt.backgroundAlpha),
                        border: Border.all(
                          color: selected
                              ? opt.color
                              : AppColors.subtle.withValues(alpha: 0.25),
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: buildIconWidget(opt, size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (widget.lockedToWeekday == null) ...[
                Text(s('routine.scope'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(s('routine.everyDay')),
                      selected: _scope == _Scope.everyDay,
                      onSelected: (_) => setState(() => _scope = _Scope.everyDay),
                    ),
                    if (!isEdit && widget.weekdayForOnlyOption != null)
                      ChoiceChip(
                        label: Text('${s('routine.todayOnly')} (${s(_dayKeys[widget.weekdayForOnlyOption! - 1])})'),
                        selected: _scope == _Scope.todayOnly,
                        onSelected: (_) => setState(() => _scope = _Scope.todayOnly),
                      ),
                    ChoiceChip(
                      label: Text(s('routine.pickDays')),
                      selected: _scope == _Scope.custom,
                      onSelected: (_) => setState(() => _scope = _Scope.custom),
                    ),
                  ],
                ),
                if (_scope == _Scope.custom) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final d = i + 1;
                      final selected = _customDays.contains(d);
                      return FilterChip(
                        label: Text(s(_dayKeys[i])),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _customDays.add(d);
                          } else {
                            _customDays.remove(d);
                          }
                        }),
                      );
                    }),
                  ),
                ],
              ] else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    AppStrings.fmt(loc, 'routine.addedToDay', {'day': s(_dayLongKeys[widget.lockedToWeekday! - 1])}),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s('common.cancel'))),
        ElevatedButton(
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) return;
            Navigator.pop(
              context,
              RoutineEditResult(
                title: t,
                iconKey: _iconKey,
                applicableDays: _resolveDays(),
              ),
            );
          },
          child: Text(isEdit ? s('routine.save') : s('routine.create')),
        ),
      ],
    );
  }
}
