import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/user_profile.dart';
import '../models/week_config.dart';
import '../services/auth_service.dart';
import '../services/routine_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ============================ Locale ============================

const String _localeKey = 'app_locale';

class LocaleController extends StateNotifier<AppLocale> {
  LocaleController() : super(_loadInitial());

  static AppLocale _loadInitial() {
    final code = StorageService.auth.get(_localeKey) as String?;
    return AppLocaleX.fromCode(code);
  }

  Future<void> set(AppLocale locale) async {
    await StorageService.auth.put(_localeKey, locale.persistKey);
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleController, AppLocale>(
  (ref) => LocaleController(),
);

// ============================ Theme ============================

const String _themeKey = 'app_theme';

class ThemeController extends StateNotifier<AppThemeId> {
  ThemeController() : super(_loadInitial()) {
    AppColors.current = state; // sync palette right away
  }

  static AppThemeId _loadInitial() {
    final code = StorageService.auth.get(_themeKey) as String?;
    return AppThemeIdX.fromKey(code);
  }

  Future<void> set(AppThemeId id) async {
    AppColors.current = id;
    await StorageService.auth.put(_themeKey, id.persistKey);
    state = id;
  }
}

final themeProvider = StateNotifierProvider<ThemeController, AppThemeId>(
  (ref) => ThemeController(),
);

/// Convenience: read current strings function.
String t(WidgetRef ref, String key) =>
    AppStrings.get(ref.watch(localeProvider), key);

/// Holds the currently signed-in user (null = logged out).
class AuthController extends StateNotifier<UserProfile?> {
  AuthController(this._auth) : super(_auth.currentUser);

  final AuthService _auth;

  Future<void> signUp(
    String name,
    String password, {
    required String characterId,
    String? displayName,
  }) async {
    final p = await _auth.signUp(
      name: name,
      password: password,
      characterId: characterId,
      displayName: displayName,
    );
    state = p;
  }

  Future<void> signIn(String name, String password) async {
    final p = await _auth.signIn(name: name, password: password);
    state = p;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = null;
  }

  Future<void> applyUpdate(UserProfile updated) async {
    await _auth.updateProfile(updated);
    state = updated;
  }

  /// Runs the weekly penalty check against today's date and saves the result.
  Future<void> applyWeeklyPenaltyCheck(RoutineService svc) async {
    final user = state;
    if (user == null) return;
    final updated = svc.checkWeeklyPenalty(user, DateTime.now());
    if (updated != null) await applyUpdate(updated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, UserProfile?>(
        (ref) => AuthController(ref.watch(authServiceProvider)));

/// Builds a RoutineService when there is a signed-in user.
final routineServiceProvider = FutureProvider<RoutineService?>((ref) async {
  final user = ref.watch(authControllerProvider);
  if (user == null) return null;
  return RoutineService.forUser(user.name.trim().toLowerCase());
});

/// "Today" date (refreshed when [selectedDateProvider] is set).
final selectedDateProvider =
    StateProvider<DateTime>((ref) => _today());

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Bumps whenever data changes — UI watches this to rebuild.
final dataRevisionProvider = StateProvider<int>((ref) => 0);

void bumpRevision(WidgetRef ref) {
  ref.read(dataRevisionProvider.notifier).update((v) => v + 1);
}

class WeekConfigUpdater {
  WeekConfigUpdater(this.ref);
  final WidgetRef ref;

  Future<void> save(WeekConfig config) async {
    final svc = await ref.read(routineServiceProvider.future);
    await svc?.updateWeekConfig(config);
    bumpRevision(ref);
  }
}
