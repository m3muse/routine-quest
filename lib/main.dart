import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await initializeDateFormatting('ko_KR');
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('zh_CN');
  runApp(const ProviderScope(child: RoutineQuestApp()));
}

class RoutineQuestApp extends ConsumerWidget {
  const RoutineQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final locale = ref.watch(localeProvider);
    final themeId = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Routine Quest',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(locale, themeId),
      locale: locale.toFlutterLocale(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('zh'),
      ],
      home: user == null ? const LoginScreen() : const HomeShell(),
    );
  }
}
