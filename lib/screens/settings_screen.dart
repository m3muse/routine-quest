import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/character_def.dart';
import '../models/level_system.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';
import '../widgets/character_painter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _s(String key) => AppStrings.get(ref.read(localeProvider), key);

  Future<void> _editName() async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_s('settings.changeName')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: _s('settings.newName')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(_s('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: Text(_s('common.save')),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref.read(authControllerProvider.notifier).applyUpdate(
          user.copyWith(displayName: result),
        );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_s('auth.logout')),
        content: Text(_s('auth.logoutKeepData')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_s('common.cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(_s('auth.logout'))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _pickTheme() async {
    final current = ref.read(themeProvider);
    final picked = await showDialog<AppThemeId>(
      context: context,
      builder: (c) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Text(
                      _s('settings.theme'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(c),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    for (final id in AppThemeId.values)
                      _ThemeSwatch(
                        id: id,
                        selected: id == current,
                        onTap: () => Navigator.pop(c, id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(themeProvider.notifier).set(picked);
    }
  }

  Future<void> _pickLanguage() async {
    final loc = ref.read(localeProvider);
    final picked = await showDialog<AppLocale>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(_s('settings.language')),
        children: [
          for (final l in AppLocale.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, l),
              child: Row(
                children: [
                  if (l == loc) Icon(Icons.check, color: AppColors.primary) else SizedBox(width: 24),
                  const SizedBox(width: 8),
                  Text(l.nativeLabel),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(localeProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    if (user == null) return const SizedBox.shrink();
    final def = characterById(user.characterId);
    final currentTier = LevelSystem.tierFor(user.level);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // === Profile card — same dark style as CharacterHeader for EXP bar unity ===
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.text, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 80,
                child: CharacterArt(
                  def: def,
                  mode: CharacterRenderMode.fullBody,
                  size: 72,
                  bobbing: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(currentTier.icon, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Lv ${user.level} · ${s('tier.${user.level}')}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (user.level < LevelSystem.maxLevel) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: user.expProgress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.fmt(loc, 'settings.weeksToNext', {'n': user.weeksToNext.toString()}),
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ] else
                      Text(
                        s('settings.maxReached'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editName,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: s('settings.changeName'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // === Account section — at the top per user request ===
        _SectionTitle(icon: Icons.settings_outlined, label: s('settings.account')),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(s('settings.theme')),
                subtitle: Text(ref.watch(themeProvider).label),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickTheme,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(s('settings.language')),
                subtitle: Text(loc.nativeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickLanguage,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(s('settings.charName')),
                subtitle: Text(user.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editName,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(s('settings.loginId')),
                subtitle: Text(user.name),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.danger),
                title: Text(
                  s('auth.logout'),
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: _signOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // === Energy tiers + EXP rules collapsed into one entry ===
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_stories),
            title: Text(s('settings.energyTitle')),
            subtitle: Text('Lv ${user.level} · ${s('tier.${user.level}')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const EnergyDetailScreen(),
              ));
            },
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Routine Quest · v1.0',
            style: TextStyle(fontSize: 11, color: AppColors.subtle.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}

/// Dedicated page showing the 12 energy tiers + EXP rules.
class EnergyDetailScreen extends ConsumerWidget {
  const EnergyDetailScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final user = ref.watch(authControllerProvider);
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: Text(s('settings.energyTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              s('settings.energyDesc'),
              style: TextStyle(fontSize: 12, color: AppColors.subtle),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (var i = 0; i < kLevelTiers.length; i++)
                    _TierRow(
                      tier: kLevelTiers[i],
                      currentLevel: user.level,
                      currentExp: user.exp,
                      title: s('tier.${kLevelTiers[i].level}'),
                      subtitle: s('tier.${kLevelTiers[i].level}.sub'),
                      currentLabel: s('settings.current'),
                      weeksLabel: '${LevelSystem.weeksPerLevel}${s('settings.weeksPerLevel')}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(icon: Icons.info_outline, label: s('settings.expTitle')),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RuleRow(icon: Icons.check_circle_outline, color: AppColors.primary, text: s('settings.rule1')),
                  _RuleRow(icon: Icons.local_fire_department, color: AppColors.danger, text: s('settings.rule2')),
                  _RuleRow(icon: Icons.star, color: AppColors.accent, text: s('settings.rule3')),
                  _RuleRow(icon: Icons.emoji_events, color: AppColors.magic, text: s('settings.rule4')),
                  _RuleRow(icon: Icons.calendar_today, color: AppColors.primary, text: s('settings.rule5')),
                ],
              ),
            ),
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
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.currentLevel,
    required this.currentExp,
    required this.title,
    required this.subtitle,
    required this.currentLabel,
    required this.weeksLabel,
  });
  final LevelTier tier;
  final int currentLevel;
  final int currentExp;
  final String title;
  final String subtitle;
  final String currentLabel;
  final String weeksLabel;

  @override
  Widget build(BuildContext context) {
    final isCurrent = tier.level == currentLevel;
    final isReached = tier.level < currentLevel;
    final isLocked = tier.level > currentLevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? tier.color.withValues(alpha: 0.18)
            : isReached
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.subtle.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: tier.color, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.subtle.withValues(alpha: 0.18)
                  : tier.color.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isLocked ? Icons.lock_outline : tier.icon,
              color: isLocked ? AppColors.subtle : Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lv ${tier.level}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: isLocked ? AppColors.subtle : tier.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isLocked ? AppColors.subtle : AppColors.text,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    if (isReached) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.subtle,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: currentExp / LevelSystem.expToNext(tier.level),
                      minHeight: 5,
                      backgroundColor: tier.color.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(tier.color),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            weeksLabel,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.subtle.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.id, required this.selected, required this.onTap});
  final AppThemeId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = kPalettes[id]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? p.primary : p.text.withValues(alpha: 0.15),
            width: selected ? 2.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // 4-swatch preview
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Swatch(color: p.background),
                _Swatch(color: p.primary),
                _Swatch(color: p.accent),
                _Swatch(color: p.text),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                id.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: p.text,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: p.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
        ),
      );
}
