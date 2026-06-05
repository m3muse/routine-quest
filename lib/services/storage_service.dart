import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_log.dart';
import '../models/routine.dart';
import '../models/user_profile.dart';
import '../models/week_config.dart';

/// Centralized Hive setup. All boxes are namespaced per user.
class StorageService {
  static const String authBox = 'auth';
  static const String authKeyCurrentUser = 'currentUser';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(WeekConfigAdapter());
    Hive.registerAdapter(DailyLogAdapter());
    await Hive.openBox(authBox); // shared registry: username -> UserProfile
  }

  static Box get auth => Hive.box(authBox);

  static Future<Box<Routine>> openRoutines(String userName) =>
      Hive.openBox<Routine>('routines_$userName');

  static Future<Box> openWeekConfig(String userName) =>
      Hive.openBox('weekconfig_$userName');

  static Future<Box<DailyLog>> openLogs(String userName) =>
      Hive.openBox<DailyLog>('logs_$userName');

  static Future<void> closeUserBoxes(String userName) async {
    for (final name in [
      'routines_$userName',
      'weekconfig_$userName',
      'logs_$userName',
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    }
  }
}
