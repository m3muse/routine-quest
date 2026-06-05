import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/character_def.dart';
import '../models/level_system.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'character_painter.dart';

/// Top bar showing character art, name, level, EXP bar.
/// Pass [todayExp] (0–100) on the Today screen to show daily progress instead of level EXP.
class CharacterHeader extends ConsumerWidget {
  const CharacterHeader({super.key, required this.user, this.todayExp});
  final UserProfile user;
  final int? todayExp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    final tierTitle = AppStrings.get(loc, 'tier.${user.level}');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.text, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Lv ${user.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tierTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                todayExp != null
                    ? _ExpBar(
                        progress: todayExp! / 100.0,
                        subText: '$todayExp / 100 EXP',
                      )
                    : _ExpBar(
                        progress: user.expProgress,
                        subText: user.level < LevelSystem.maxLevel
                            ? AppStrings.fmt(loc, 'settings.weeksToNext', {'n': user.weeksToNext.toString()})
                            : AppStrings.get(loc, 'settings.maxReached'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final def = characterById(user.characterId);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: 60,
          height: 60,
          child: CharacterArt(
            def: def,
            mode: CharacterRenderMode.portrait,
            size: 60,
            bobbing: true,
          ),
        ),
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.progress, required this.subText});
  final double progress;
  final String subText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (c, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subText,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
        ),
      ],
    );
  }
}
