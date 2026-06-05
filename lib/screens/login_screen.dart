import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/character_def.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/character_painter.dart';
import '../widgets/language_toggle.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _pw = TextEditingController();
  final _charName = TextEditingController();
  int _charIndex = 0;
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _pw.dispose();
    _charName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final loc = ref.read(localeProvider);
    try {
      final c = ref.read(authControllerProvider.notifier);
      if (_isSignUp) {
        final picked = kCharacters[_charIndex];
        final fallbackName = AppStrings.get(loc, 'char.${picked.id}.name');
        final displayName = _charName.text.trim().isEmpty
            ? fallbackName
            : _charName.text.trim();
        await c.signUp(
          _name.text,
          _pw.text,
          characterId: picked.id,
          displayName: displayName,
        );
      } else {
        await c.signIn(_name.text, _pw.text);
      }
    } catch (e) {
      // Translate known auth error codes to the current locale.
      String msg;
      final raw = e.toString();
      if (e is FormatException && e.message == 'empty-id') {
        msg = AppStrings.get(loc, 'auth.errEmptyId');
      } else if (e is FormatException && e.message == 'short-pw') {
        msg = AppStrings.get(loc, 'auth.errShortPw');
      } else if (raw.contains('user-exists')) {
        msg = AppStrings.get(loc, 'auth.errUserExists');
      } else if (raw.contains('user-not-found')) {
        msg = AppStrings.get(loc, 'auth.errUserNotFound');
      } else if (raw.contains('wrong-pw')) {
        msg = AppStrings.get(loc, 'auth.errWrongPw');
      } else if (e is FormatException) {
        msg = e.message;
      } else {
        msg = raw.replaceAll('Bad state: ', '');
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // 80s VHS sunset — lime → yellow → orange → red → magenta → plum.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFA8C040), // lime top
              Color(0xFFF0F040), // yellow
              Color(0xFFF09040), // orange
              Color(0xFFF04050), // hot red
              Color(0xFF803060), // magenta
              Color(0xFF503040), // deep plum
            ],
            stops: [0.0, 0.18, 0.38, 0.58, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top-right language picker, available even on the auth screen.
              const Positioned(top: 8, right: 12, child: LanguageToggle(dark: true)),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          s('app.title'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.black.withValues(alpha: 0.22),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s('app.tagline'),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SegmentedButton<bool>(
                                  segments: [
                                    ButtonSegment(value: false, label: Text(s('auth.login'))),
                                    ButtonSegment(value: true, label: Text(s('auth.signup'))),
                                  ],
                                  selected: {_isSignUp},
                                  onSelectionChanged: (sel) => setState(() {
                                    _isSignUp = sel.first;
                                    _error = null;
                                  }),
                                ),
                                const SizedBox(height: 16),
                                if (_isSignUp) ...[
                                  Text(
                                    s('auth.charSelect'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _CharacterHero(def: kCharacters[_charIndex]),
                                  const SizedBox(height: 10),
                                  _CharacterGrid(
                                    selectedIndex: _charIndex,
                                    onSelect: (i) => setState(() => _charIndex = i),
                                  ),
                                  const SizedBox(height: 10),
                                  _ArchetypeBanner(def: kCharacters[_charIndex]),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _charName,
                                    decoration: InputDecoration(
                                      labelText: s('auth.charName'),
                                      hintText: s('char.${kCharacters[_charIndex].id}.name'),
                                      prefixIcon: const Icon(Icons.auto_awesome),
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                TextField(
                                  controller: _name,
                                  decoration: InputDecoration(
                                    labelText: s('auth.id'),
                                    prefixIcon: const Icon(Icons.person),
                                  ),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _pw,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: s('auth.password'),
                                    prefixIcon: const Icon(Icons.lock),
                                  ),
                                  onSubmitted: (_) => _submit(),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: TextStyle(color: AppColors.danger),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _busy ? null : _submit,
                                  child: _busy
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_isSignUp ? s('auth.start') : s('auth.login')),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s('app.localOnly'),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large preview of the currently selected character. High-quality render
/// because we know the box size in advance and request the right cacheWidth.
class _CharacterHero extends StatelessWidget {
  const _CharacterHero({required this.def});
  final CharacterDef def;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Show more of the meadow/field portion under the character so the
        // ground feels grounded (character stands on grass, not in the sky).
        image: const DecorationImage(
          image: AssetImage('assets/scenery/background.png'),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.55),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft aura tint behind the character matching their archetype.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    def.aura.withValues(alpha: 0.35),
                    def.aura.withValues(alpha: 0.0),
                  ],
                  radius: 0.85,
                ),
              ),
            ),
            CharacterArt(
              key: ValueKey('hero-${def.id}'),
              def: def,
              mode: CharacterRenderMode.fullBody,
              bobbing: true,
            ),
          ],
        ),
      ),
    );
  }
}


class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Single-row thumbnail strip — 6 cards. Hero above shows quality detail.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kCharacters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (c, i) {
        final def = kCharacters[i];
        final selected = i == selectedIndex;
        return InkWell(
          onTap: () => onSelect(i),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  def.aura.withValues(alpha: selected ? 0.55 : 0.18),
                  def.aura.withValues(alpha: 0.0),
                ],
                radius: 0.85,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.accent : Colors.transparent,
                width: selected ? 2.5 : 0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CharacterArt(
                def: def,
                mode: CharacterRenderMode.fullBody,
                bobbing: selected,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArchetypeBanner extends ConsumerWidget {
  const _ArchetypeBanner({required this.def});
  final CharacterDef def;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localeProvider);
    final name = AppStrings.get(loc, 'char.${def.id}.name');
    final personality = AppStrings.get(loc, 'char.${def.id}.personality');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: def.aura.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(def.archetype.icon, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  personality,
                  style: TextStyle(fontSize: 11, color: AppColors.subtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
