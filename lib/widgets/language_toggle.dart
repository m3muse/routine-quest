import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Compact language picker — pops a menu of KO / EN / ZH and stores the
/// selection persistently via localeProvider.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.dark = false});

  /// If `dark` is true, use light text on dark background (e.g. over login bg).
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final controller = ref.read(localeProvider.notifier);
    final fg = dark ? Colors.white : AppColors.text;
    final bg = dark ? Colors.black.withValues(alpha: 0.25) : Colors.white;
    return PopupMenuButton<AppLocale>(
      tooltip: AppStrings.get(current, 'settings.language'),
      initialValue: current,
      onSelected: controller.set,
      itemBuilder: (c) => [
        for (final l in AppLocale.values)
          PopupMenuItem(
            value: l,
            child: Row(
              children: [
                if (l == current)
                  Icon(Icons.check, size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(l.nativeLabel),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: fg, size: 16),
            const SizedBox(width: 4),
            Text(
              current.code,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: fg, size: 18),
          ],
        ),
      ),
    );
  }
}
