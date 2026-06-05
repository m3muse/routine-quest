import 'package:flutter/widgets.dart';

/// Supported app languages. Order is the order shown in selectors.
enum AppLocale { ko, en, zh }

extension AppLocaleX on AppLocale {
  /// Display name in the language itself.
  String get nativeLabel {
    switch (this) {
      case AppLocale.ko:
        return '한국어';
      case AppLocale.en:
        return 'English';
      case AppLocale.zh:
        return '中文';
    }
  }

  /// Short flag/code shown in compact toggles.
  String get code {
    switch (this) {
      case AppLocale.ko:
        return 'KO';
      case AppLocale.en:
        return 'EN';
      case AppLocale.zh:
        return 'ZH';
    }
  }

  Locale toFlutterLocale() {
    switch (this) {
      case AppLocale.ko:
        return const Locale('ko');
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.zh:
        return const Locale('zh');
    }
  }

  static AppLocale fromCode(String? code) {
    switch (code) {
      case 'en':
        return AppLocale.en;
      case 'zh':
        return AppLocale.zh;
      case 'ko':
      default:
        return AppLocale.ko;
    }
  }

  String get persistKey {
    switch (this) {
      case AppLocale.ko:
        return 'ko';
      case AppLocale.en:
        return 'en';
      case AppLocale.zh:
        return 'zh';
    }
  }

  /// BCP-47 locale tag used by the `intl` package (DateFormat etc.).
  String get intlLocale {
    switch (this) {
      case AppLocale.ko:
        return 'ko_KR';
      case AppLocale.en:
        return 'en_US';
      case AppLocale.zh:
        return 'zh_CN';
    }
  }

  /// Date format pattern for full date display.
  String get dateFormat {
    switch (this) {
      case AppLocale.ko:
        return 'y년 M월 d일 (E)';
      case AppLocale.en:
        return 'EEE, MMM d y';
      case AppLocale.zh:
        return 'y年M月d日(E)';
    }
  }
}

/// All user-visible strings keyed by stable IDs.
/// Add new keys to all three maps to avoid runtime fallback to the key.
class AppStrings {
  static const Map<AppLocale, Map<String, String>> _all = {
    AppLocale.ko: {
      // App
      'app.title': 'Routine Quest',
      'app.tagline': '하루의 루틴으로 영웅이 되어가세요',
      'app.localOnly': '데이터는 이 기기에만 저장됩니다',

      // Auth
      'auth.login': '로그인',
      'auth.signup': '회원가입',
      'auth.id': '아이디 (영문/숫자)',
      'auth.password': '비밀번호 (4자 이상)',
      'auth.start': '모험 시작하기',
      'auth.charSelect': '캐릭터 선택',
      'auth.charName': '캐릭터 이름',
      'auth.errEmptyId': '이름을 입력해주세요',
      'auth.errShortPw': '비밀번호는 4자 이상이어야 합니다',
      'auth.errUserExists': '이미 존재하는 사용자입니다',
      'auth.errUserNotFound': '사용자를 찾을 수 없습니다',
      'auth.errWrongPw': '비밀번호가 일치하지 않습니다',
      'auth.logout': '로그아웃',
      'auth.logoutKeepData': '데이터는 그대로 유지됩니다.',
      'auth.cancel': '취소',

      // Nav
      'nav.today': '오늘',
      'nav.stats': '통계',
      'nav.week': '주간',
      'nav.settings': '설정',
      'shell.today': '오늘의 루틴',
      'shell.stats': '나의 모험 기록',
      'shell.week': '주간 설정',
      'shell.settings': '설정',

      // Today
      'today.add': '루틴 추가',
      'today.edit': '수정',
      'today.delete': '삭제',
      'today.toToday': '오늘로',
      'today.empty.title': '오늘의 퀘스트가 없어요',
      'today.empty.body': '새 루틴을 추가하고 모험을 시작하세요.',
      'today.holiday.title': '오늘은 휴일이에요',
      'today.holiday.body': '푹 쉬고 내일 다시 모험을 떠나봐요.',
      'today.progress': '오늘 진행',
      'today.expLabel': '오늘 EXP',
      'today.dayOfYear': '1년 중 {n}일째 / {total}일',
      'today.done': 'Done',
      'today.deleteConfirmTitle': '루틴 삭제',
      'today.deleteConfirmBody': '"{title}" 을(를) 오늘 및 앞으로의 모든 날에서 삭제할까요?\n과거 기록은 유지됩니다.',

      // Routine editor
      'routine.newTitle': '새 루틴',
      'routine.editTitle': '루틴 수정',
      'routine.titleHint': '예: 30분 독서',
      'routine.icon': '아이콘',
      'routine.scope': '적용 범위',
      'routine.everyDay': '매일',
      'routine.todayOnly': '오늘 요일만',
      'routine.pickDays': '요일 선택',
      'routine.save': '저장',
      'routine.create': '추가',
      'routine.addedToDay': '{day}에 추가됩니다.',

      // Days
      'day.mon': '월', 'day.tue': '화', 'day.wed': '수', 'day.thu': '목',
      'day.fri': '금', 'day.sat': '토', 'day.sun': '일',
      'day.everyday': '매일',
      'dayLong.mon': '월요일', 'dayLong.tue': '화요일', 'dayLong.wed': '수요일',
      'dayLong.thu': '목요일', 'dayLong.fri': '금요일', 'dayLong.sat': '토요일',
      'dayLong.sun': '일요일',

      // Week settings
      'week.intro': '요일별로 휴일을 지정하거나, 그 날의 루틴을 직접 추가/수정할 수 있어요.',
      'week.holiday': '휴일',
      'week.active': '활동',
      'week.empty': '이 요일에는 루틴이 없어요.',
      'week.excluded': '이 요일에서 제외됨 (탭으로 복구):',
      'week.addForDay': '{day} 루틴 추가',
      'week.excludeDay': '이 요일에서 제외',

      // Categories
      'cat.study': '학습',
      'cat.music': '음악',
      'cat.fitness': '운동',
      'cat.misc': '기타',

      // Stats
      'stats.sectionMountain': '루틴 지도',
      'stats.sectionChart': '요일별 달성률',
      'stats.weeklyExpLabel': '주간 EXP',
      'stats.holidayMark': '휴',
      'stats.weekly': '주간',
      'stats.tileLevel': '현재 레벨',
      'stats.tileStreak': '연속 달성',
      'stats.tileRoutines': '활성 루틴',
      'stats.streakUnit': '일',
      'stats.routinesUnit': '개',

      // Settings
      'settings.energyTitle': '에너지 단계 (1년의 여정)',
      'settings.energyDesc': '한 단계는 1주일 완성 4번 = 한 달.\n12단계를 모두 거치면 1년 동안의 모험이 완성됩니다.',
      'settings.expTitle': 'EXP 규칙',
      'settings.account': '계정',
      'settings.charName': '캐릭터 이름',
      'settings.loginId': '로그인 아이디',
      'settings.weeksPerLevel': '주',
      'settings.weeksToNext': '다음 단계까지 {n}주 완성 남음',
      'settings.maxReached': '🌟 최고 단계 달성! 1년의 여정 완성',
      'settings.current': '현재',
      'settings.rule1': '하루 루틴 모두 완료: 100 EXP (오늘의 점수)',
      'settings.rule2': '한 주 7일 모두 완료: 배지 1개 획득',
      'settings.rule3': '배지 4개 모으면 1달 완성',
      'settings.rule4': '1달 완성마다 한 단계 상승',
      'settings.rule5': '12단계 모두 = 1년의 여정 완성',
      'settings.changeName': '캐릭터 이름 변경',
      'settings.newName': '새 이름',
      'settings.language': '언어',
      'settings.theme': '테마',

      // Characters
      'char.f_steady.name': '리나',
      'char.f_smart.name': '밀라',
      'char.f_beauty.name': '제시카',
      'char.m_steady.name': '루이',
      'char.m_smart.name': '엘빈',
      'char.m_beauty.name': '데이빗',
      'char.f_steady.personality': '조용하고 끈기 있는, 한 번 마음먹으면 끝까지 가는 아이',
      'char.f_smart.personality': '호기심 많고 머리 회전 빠른, 항상 한발 앞서가는 아이',
      'char.f_beauty.personality': '덤벙대지만 낙관적인, 옆에 있으면 기분 좋아지는 아이',
      'char.m_steady.personality': '말은 적지만 묵묵히 든든한, 어려울 때 옆에 있는 아이',
      'char.m_smart.personality': '까칠한 천재 타입, 알고 보면 다정한 아이',
      'char.m_beauty.personality': '허세 부리지만 의리 있는, 자유로운 영혼의 아이',

      // Tiers
      'tier.1': '무지의 새싹', 'tier.1.sub': '첫 걸음을 내딛는 자',
      'tier.2': '호기심 도제', 'tier.2.sub': '세상의 규칙을 배우기 시작',
      'tier.3': '수련의 길', 'tier.3.sub': '꾸준함이 무기가 된다',
      'tier.4': '약초 술사', 'tier.4.sub': '작은 마법을 다루기 시작',
      'tier.5': '바람의 술사', 'tier.5.sub': '루틴이 자연스러워진다',
      'tier.6': '빛의 학도', 'tier.6.sub': '재능이 빛나기 시작한다',
      'tier.7': '현자의 제자', 'tier.7.sub': '깊이 있는 통찰을 얻다',
      'tier.8': '대 술사', 'tier.8.sub': '한 분야의 대가로 인정받다',
      'tier.9': '현자', 'tier.9.sub': '많은 이의 길잡이가 되다',
      'tier.10': '용사', 'tier.10.sub': '시련을 넘어 영웅의 길로',
      'tier.11': '대마법사', 'tier.11.sub': '강력한 의지의 화신',
      'tier.12': '에너지의 영웅', 'tier.12.sub': '1년의 여정을 완성한 자',

      // Common
      'common.error': '오류: {e}',
      'common.cancel': '취소',
      'common.save': '저장',
      'common.delete': '삭제',
    },
    AppLocale.en: {
      'app.title': 'Routine Quest',
      'app.tagline': 'Become a hero through your daily routines',
      'app.localOnly': 'Data is stored only on this device',

      'auth.login': 'Sign In',
      'auth.signup': 'Sign Up',
      'auth.id': 'ID (letters/digits)',
      'auth.password': 'Password (4+ chars)',
      'auth.start': 'Start the Adventure',
      'auth.charSelect': 'Choose your character',
      'auth.charName': 'Character name',
      'auth.errEmptyId': 'Please enter an ID',
      'auth.errShortPw': 'Password must be at least 4 characters',
      'auth.errUserExists': 'User already exists',
      'auth.errUserNotFound': 'User not found',
      'auth.errWrongPw': 'Password does not match',
      'auth.logout': 'Log out',
      'auth.logoutKeepData': 'Your data stays on this device.',
      'auth.cancel': 'Cancel',

      'nav.today': 'Today',
      'nav.stats': 'Stats',
      'nav.week': 'Week',
      'nav.settings': 'Settings',
      'shell.today': "Today's Routines",
      'shell.stats': 'Adventure Log',
      'shell.week': 'Weekly Setup',
      'shell.settings': 'Settings',

      'today.add': 'Add Routine',
      'today.edit': 'Edit',
      'today.delete': 'Delete',
      'today.toToday': 'Today',
      'today.empty.title': 'No quests for today',
      'today.empty.body': 'Add a new routine and start your adventure.',
      'today.holiday.title': "Today's a rest day",
      'today.holiday.body': 'Rest well and return tomorrow.',
      'today.progress': "Today's progress",
      'today.expLabel': 'Today EXP',
      'today.dayOfYear': 'Day {n} of {total}',
      'today.done': 'Done',
      'today.deleteConfirmTitle': 'Delete routine',
      'today.deleteConfirmBody': 'Remove "{title}" from today and all future days?\nPast logs are preserved.',

      'routine.newTitle': 'New Routine',
      'routine.editTitle': 'Edit Routine',
      'routine.titleHint': 'e.g. Read 30 minutes',
      'routine.icon': 'Icon',
      'routine.scope': 'Applies to',
      'routine.everyDay': 'Every day',
      'routine.todayOnly': 'Only this weekday',
      'routine.pickDays': 'Pick days',
      'routine.save': 'Save',
      'routine.create': 'Add',
      'routine.addedToDay': 'Will be added to {day}.',

      'day.mon': 'Mon', 'day.tue': 'Tue', 'day.wed': 'Wed', 'day.thu': 'Thu',
      'day.fri': 'Fri', 'day.sat': 'Sat', 'day.sun': 'Sun',
      'day.everyday': 'Every day',
      'dayLong.mon': 'Monday', 'dayLong.tue': 'Tuesday', 'dayLong.wed': 'Wednesday',
      'dayLong.thu': 'Thursday', 'dayLong.fri': 'Friday', 'dayLong.sat': 'Saturday',
      'dayLong.sun': 'Sunday',

      'week.intro': 'Pick which weekdays are rest days, or add/edit routines per day.',
      'week.holiday': 'Rest',
      'week.active': 'Active',
      'week.empty': 'No routines for this day.',
      'week.excluded': 'Excluded from this day (tap to restore):',
      'week.addForDay': 'Add for {day}',
      'week.excludeDay': 'Exclude from this day',

      'cat.study': 'Study',
      'cat.music': 'Music',
      'cat.fitness': 'Fitness',
      'cat.misc': 'Misc',

      'stats.sectionMountain': 'Routine Map',
      'stats.sectionChart': 'Daily Completion',
      'stats.weeklyExpLabel': 'Weekly EXP',
      'stats.holidayMark': 'Off',
      'stats.weekly': 'Weekly',
      'stats.tileLevel': 'Current Level',
      'stats.tileStreak': 'Streak',
      'stats.tileRoutines': 'Active Routines',
      'stats.streakUnit': ' days',
      'stats.routinesUnit': '',

      'settings.energyTitle': 'Energy Tiers (a year-long journey)',
      'settings.energyDesc': 'One tier = 4 perfect weeks = a month.\nComplete all 12 tiers in a year of adventures.',
      'settings.expTitle': 'EXP Rules',
      'settings.account': 'Account',
      'settings.charName': 'Character Name',
      'settings.loginId': 'Login ID',
      'settings.weeksPerLevel': 'w',
      'settings.weeksToNext': '{n} more weeks to the next tier',
      'settings.maxReached': '🌟 Max tier reached — a year completed',
      'settings.current': 'Current',
      'settings.rule1': 'All daily routines done: 100 EXP (today\'s score)',
      'settings.rule2': 'Perfect week (7 days): earn 1 badge',
      'settings.rule3': '4 badges = 1 month complete',
      'settings.rule4': 'Each month: tier up',
      'settings.rule5': 'All 12 tiers = a year-long quest completed',
      'settings.changeName': 'Rename character',
      'settings.newName': 'New name',
      'settings.language': 'Language',
      'settings.theme': 'Theme',

      'char.f_steady.name': 'Lina',
      'char.f_smart.name': 'Mila',
      'char.f_beauty.name': 'Jessica',
      'char.m_steady.name': 'Louis',
      'char.m_smart.name': 'Elvin',
      'char.m_beauty.name': 'David',
      'char.f_steady.personality': 'Quiet, persistent — once she decides, she sees it through',
      'char.f_smart.personality': 'Curious and quick-witted — always one step ahead',
      'char.f_beauty.personality': 'Clumsy but cheerful — makes everyone smile',
      'char.m_steady.personality': 'Few words, but a rock — there when you need him',
      'char.m_smart.personality': 'Prickly genius — warmer than he looks',
      'char.m_beauty.personality': 'Boastful but loyal — a free-spirited adventurer',

      'tier.1': 'Sprout of Ignorance', 'tier.1.sub': 'Taking the first step',
      'tier.2': 'Curious Apprentice', 'tier.2.sub': 'Beginning to learn the rules',
      'tier.3': 'Path of Discipline', 'tier.3.sub': 'Consistency becomes a weapon',
      'tier.4': 'Herbalist', 'tier.4.sub': 'Touching small magics',
      'tier.5': 'Wind Mage', 'tier.5.sub': 'Routine feels natural now',
      'tier.6': 'Student of Light', 'tier.6.sub': 'Talent begins to shine',
      'tier.7': 'Sage Apprentice', 'tier.7.sub': 'Insight runs deeper',
      'tier.8': 'Grand Mage', 'tier.8.sub': 'A recognized master of your craft',
      'tier.9': 'Sage', 'tier.9.sub': 'A guide for many',
      'tier.10': 'Champion', 'tier.10.sub': 'Past trials, onto heroism',
      'tier.11': 'Archmage', 'tier.11.sub': 'Embodiment of strong will',
      'tier.12': 'Hero of Energy', 'tier.12.sub': 'Completed the year-long journey',

      'common.error': 'Error: {e}',
      'common.cancel': 'Cancel',
      'common.save': 'Save',
      'common.delete': 'Delete',
    },
    AppLocale.zh: {
      'app.title': 'Routine Quest',
      'app.tagline': '通过每日例程成为英雄',
      'app.localOnly': '数据仅保存在此设备上',

      'auth.login': '登录',
      'auth.signup': '注册',
      'auth.id': '账号 (字母/数字)',
      'auth.password': '密码 (4位以上)',
      'auth.start': '开始冒险',
      'auth.charSelect': '选择角色',
      'auth.charName': '角色名',
      'auth.errEmptyId': '请输入账号',
      'auth.errShortPw': '密码至少需要 4 位',
      'auth.errUserExists': '用户已存在',
      'auth.errUserNotFound': '找不到用户',
      'auth.errWrongPw': '密码不正确',
      'auth.logout': '退出登录',
      'auth.logoutKeepData': '数据将保留在本设备。',
      'auth.cancel': '取消',

      'nav.today': '今日',
      'nav.stats': '统计',
      'nav.week': '每周',
      'nav.settings': '设置',
      'shell.today': '今日例程',
      'shell.stats': '冒险记录',
      'shell.week': '每周设置',
      'shell.settings': '设置',

      'today.add': '添加例程',
      'today.edit': '编辑',
      'today.delete': '删除',
      'today.toToday': '回到今天',
      'today.empty.title': '今天没有任务',
      'today.empty.body': '添加新例程，开始冒险吧。',
      'today.holiday.title': '今天是休息日',
      'today.holiday.body': '好好休息,明天再出发。',
      'today.progress': '今日进度',
      'today.expLabel': '今日EXP',
      'today.dayOfYear': '全年第{n}天 / 共{total}天',
      'today.done': '完成',
      'today.deleteConfirmTitle': '删除例程',
      'today.deleteConfirmBody': '删除 "{title}" 从今天起所有未来日子?\n过去的记录会保留。',

      'routine.newTitle': '新例程',
      'routine.editTitle': '编辑例程',
      'routine.titleHint': '例如 阅读 30 分钟',
      'routine.icon': '图标',
      'routine.scope': '适用范围',
      'routine.everyDay': '每天',
      'routine.todayOnly': '仅本星期日',
      'routine.pickDays': '选择星期',
      'routine.save': '保存',
      'routine.create': '添加',
      'routine.addedToDay': '将添加到 {day}。',

      'day.mon': '一', 'day.tue': '二', 'day.wed': '三', 'day.thu': '四',
      'day.fri': '五', 'day.sat': '六', 'day.sun': '日',
      'day.everyday': '每天',
      'dayLong.mon': '星期一', 'dayLong.tue': '星期二', 'dayLong.wed': '星期三',
      'dayLong.thu': '星期四', 'dayLong.fri': '星期五', 'dayLong.sat': '星期六',
      'dayLong.sun': '星期日',

      'week.intro': '设置每周休息日,或为每天直接添加/编辑例程。',
      'week.holiday': '休息',
      'week.active': '活动',
      'week.empty': '本日没有例程。',
      'week.excluded': '已从此日排除 (点击恢复):',
      'week.addForDay': '添加 {day} 的例程',
      'week.excludeDay': '从该日排除',

      'cat.study': '学习',
      'cat.music': '音乐',
      'cat.fitness': '运动',
      'cat.misc': '其他',

      'stats.sectionMountain': '本周之山',
      'stats.sectionChart': '每日完成率',
      'stats.weeklyExpLabel': '本周EXP',
      'stats.holidayMark': '休',
      'stats.weekly': '本周',
      'stats.tileLevel': '当前等级',
      'stats.tileStreak': '连续天数',
      'stats.tileRoutines': '活跃例程',
      'stats.streakUnit': '天',
      'stats.routinesUnit': '个',

      'settings.energyTitle': '能量等级 (一年的旅程)',
      'settings.energyDesc': '一个等级 = 完成 4 个完美周 = 一个月。\n12 个等级走完即是一年的冒险。',
      'settings.expTitle': 'EXP 规则',
      'settings.account': '账户',
      'settings.charName': '角色名',
      'settings.loginId': '登录账号',
      'settings.weeksPerLevel': '周',
      'settings.weeksToNext': '距下一等级 {n} 周',
      'settings.maxReached': '🌟 已达到最高等级 — 完成了一年的旅程',
      'settings.current': '当前',
      'settings.rule1': '当日例程全部完成: 100 EXP (今日得分)',
      'settings.rule2': '一周 7 天全部完成: 获得 1 枚徽章',
      'settings.rule3': '收集 4 枚徽章 = 完成 1 个月',
      'settings.rule4': '每完成 1 个月: 升一个等级',
      'settings.rule5': '12 个等级 = 完成全年冒险',
      'settings.changeName': '更改角色名',
      'settings.newName': '新名字',
      'settings.language': '语言',
      'settings.theme': '主题',

      'char.f_steady.name': '丽娜',
      'char.f_smart.name': '米拉',
      'char.f_beauty.name': '杰西卡',
      'char.m_steady.name': '路易',
      'char.m_smart.name': '艾文',
      'char.m_beauty.name': '大卫',
      'char.f_steady.personality': '安静且坚韧 — 一旦下定决心,便会贯彻到底',
      'char.f_smart.personality': '充满好奇心,反应敏捷 — 永远领先一步',
      'char.f_beauty.personality': '粗心却乐观 — 让身边的人都开心',
      'char.m_steady.personality': '话不多,却稳如磐石 — 总在你需要的时候出现',
      'char.m_smart.personality': '高冷天才 — 其实心地温柔',
      'char.m_beauty.personality': '爱吹嘘但讲义气 — 自由不羁的冒险者',

      'tier.1': '无知的萌芽', 'tier.1.sub': '迈出第一步',
      'tier.2': '好奇的学徒', 'tier.2.sub': '开始学习世界的规则',
      'tier.3': '修行之路', 'tier.3.sub': '坚持成为武器',
      'tier.4': '草药术师', 'tier.4.sub': '开始接触小法术',
      'tier.5': '风之术师', 'tier.5.sub': '例程变得自然',
      'tier.6': '光之学徒', 'tier.6.sub': '天赋开始闪耀',
      'tier.7': '贤者门徒', 'tier.7.sub': '获得更深的洞察',
      'tier.8': '大术师', 'tier.8.sub': '被公认为某领域的大师',
      'tier.9': '贤者', 'tier.9.sub': '成为许多人的引路者',
      'tier.10': '勇士', 'tier.10.sub': '越过试炼,走向英雄之路',
      'tier.11': '大魔法师', 'tier.11.sub': '强大意志的化身',
      'tier.12': '能量英雄', 'tier.12.sub': '完成一年旅程的人',

      'common.error': '错误: {e}',
      'common.cancel': '取消',
      'common.save': '保存',
      'common.delete': '删除',
    },
  };

  static String get(AppLocale loc, String key) {
    final map = _all[loc] ?? _all[AppLocale.ko]!;
    return map[key] ?? _all[AppLocale.ko]![key] ?? key;
  }

  /// Substitute named tokens like {n}.
  static String fmt(AppLocale loc, String key, Map<String, String> vars) {
    var s = get(loc, key);
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }
}
