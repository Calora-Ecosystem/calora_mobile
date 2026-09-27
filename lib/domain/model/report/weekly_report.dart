/// One day of the weekly report (`GET reports/weekly` → `days`).
class WeeklyReportDay {
  final DateTime date;
  final double kcal;
  final double protein;
  final double fat;
  final double carb;
  final double water;
  final double steps;
  final int mealCount;

  /// Food was logged and kcal stayed within 75%–110% of the norm.
  final bool inNorm;

  const WeeklyReportDay({
    required this.date,
    this.kcal = 0,
    this.protein = 0,
    this.fat = 0,
    this.carb = 0,
    this.water = 0,
    this.steps = 0,
    this.mealCount = 0,
    this.inNorm = false,
  });

  bool get isLogged => mealCount > 0;

  /// Anything recorded that day: food, steps or water.
  bool get isActive => mealCount > 0 || steps > 0 || water > 0;

  WeeklyReportDay copyWithSteps(double steps) => WeeklyReportDay(
    date: date,
    kcal: kcal,
    protein: protein,
    fat: fat,
    carb: carb,
    water: water,
    steps: steps,
    mealCount: mealCount,
    inNorm: inNorm,
  );

  factory WeeklyReportDay.fromJson(Map<String, dynamic> json) =>
      WeeklyReportDay(
        date: DateTime.parse(json['date'] as String),
        kcal: _d(json['kcal']),
        protein: _d(json['protein']),
        fat: _d(json['fat']),
        carb: _d(json['carb']),
        water: _d(json['water']),
        steps: _d(json['steps']),
        mealCount: _i(json['mealCount']),
        inNorm: json['inNorm'] as bool? ?? false,
      );
}

/// Sums or averages over the week (`totals` / `averages`).
class WeeklyReportTotals {
  final double kcal;
  final double protein;
  final double fat;
  final double carb;
  final double water;
  final double steps;
  final int mealCount;

  const WeeklyReportTotals({
    this.kcal = 0,
    this.protein = 0,
    this.fat = 0,
    this.carb = 0,
    this.water = 0,
    this.steps = 0,
    this.mealCount = 0,
  });

  WeeklyReportTotals copyWithSteps(double steps) => WeeklyReportTotals(
    kcal: kcal,
    protein: protein,
    fat: fat,
    carb: carb,
    water: water,
    steps: steps,
    mealCount: mealCount,
  );

  factory WeeklyReportTotals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyReportTotals();
    return WeeklyReportTotals(
      kcal: _d(json['kcal']),
      protein: _d(json['protein']),
      fat: _d(json['fat']),
      carb: _d(json['carb']),
      water: _d(json['water']),
      steps: _d(json['steps']),
      mealCount: _i(json['mealCount']),
    );
  }
}

class WeeklyReportNorms {
  final double kcal;
  final double protein;
  final double water;
  final double step;

  /// Target weight, kg.
  final double weight;

  const WeeklyReportNorms({
    this.kcal = 0,
    this.protein = 0,
    this.water = 0,
    this.step = 0,
    this.weight = 0,
  });

  factory WeeklyReportNorms.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyReportNorms();
    return WeeklyReportNorms(
      kcal: _d(json['kcal']),
      protein: _d(json['protein']),
      water: _d(json['water']),
      step: _d(json['step']),
      weight: _d(json['weight']),
    );
  }
}

/// The food eaten most often during the week.
class WeeklyTopFood {
  final String name;
  final String? coverUrl;
  final int count;

  const WeeklyTopFood({required this.name, this.coverUrl, this.count = 0});

  factory WeeklyTopFood.fromJson(Map<String, dynamic> json) {
    // The server localizes MultiLanguageField by Accept-Language, but fall back
    // to the raw object in case it ever arrives unconverted.
    final raw = json['name'];
    final name = raw is Map
        ? '${raw['uz'] ?? raw['ru'] ?? raw['en'] ?? ''}'
        : '${raw ?? ''}';
    return WeeklyTopFood(
      name: name,
      coverUrl: json['coverUrl'] as String?,
      count: _i(json['count']),
    );
  }
}

/// Profile body numbers at the time the report was requested (`body`).
class WeeklyBody {
  /// Current, starting (when the goal was picked) and target weight, kg;
  /// 0 = unknown.
  final double weight;
  final double entryWeight;
  final double targetWeight;
  final double height;
  final double bmi;

  const WeeklyBody({
    this.weight = 0,
    this.entryWeight = 0,
    this.targetWeight = 0,
    this.height = 0,
    this.bmi = 0,
  });

  bool get hasWeight => weight > 0;

  /// Kg changed since the goal was set (negative = lost).
  double get changeSinceStart => entryWeight > 0 ? weight - entryWeight : 0;

  /// Kg still to go to the target.
  double get toTarget => targetWeight > 0 ? (weight - targetWeight).abs() : 0;

  /// Share of the way from [entryWeight] to [targetWeight], 0…1; null when
  /// there is no goal to measure against.
  double? get goalProgress {
    final total = (entryWeight - targetWeight).abs();
    if (entryWeight <= 0 || targetWeight <= 0 || total < 0.1) return null;
    final movedTowards =
        (targetWeight - entryWeight).sign == (weight - entryWeight).sign;
    if (!movedTowards) return 0;
    return ((entryWeight - weight).abs() / total).clamp(0.0, 1.0);
  }

  factory WeeklyBody.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyBody();
    return WeeklyBody(
      weight: _d(json['weight']),
      entryWeight: _d(json['entryWeight']),
      targetWeight: _d(json['targetWeight']),
      height: _d(json['height']),
      bmi: _d(json['bmi']),
    );
  }
}

/// Coin movement during the week (`coins`).
class WeeklyCoins {
  final int steps;
  final int referral;
  final int earned;
  final int spent;

  /// Balance now, not at the end of the week.
  final int balance;

  const WeeklyCoins({
    this.steps = 0,
    this.referral = 0,
    this.earned = 0,
    this.spent = 0,
    this.balance = 0,
  });

  factory WeeklyCoins.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyCoins();
    return WeeklyCoins(
      steps: _i(json['steps']),
      referral: _i(json['referral']),
      earned: _i(json['earned']),
      spent: _i(json['spent']),
      balance: _i(json['balance']),
    );
  }
}

/// Course items completed during the week (`course`).
class WeeklyCourse {
  final int lessons;
  final int exercises;
  final int workouts;

  const WeeklyCourse({this.lessons = 0, this.exercises = 0, this.workouts = 0});

  bool get isEmpty => lessons == 0 && exercises == 0 && workouts == 0;

  factory WeeklyCourse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeeklyCourse();
    return WeeklyCourse(
      lessons: _i(json['lessons']),
      exercises: _i(json['exercises']),
      workouts: _i(json['workouts']),
    );
  }
}

/// Weekly report (Mon–Sun) shown as a story on the first launch of a new week.
/// Computed on the server from logged meals, steps, water, coins, the profile,
/// course progress, invites and step groups.
class WeeklyReport {
  final String name;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int loggedDays;
  final int daysInNorm;

  /// Days that reached the step / water norm.
  final int stepDaysInNorm;
  final int waterDaysInNorm;
  final WeeklyReportNorms norms;

  /// Always 7 days, starting on Monday.
  final List<WeeklyReportDay> days;
  final WeeklyReportTotals totals;
  final WeeklyReportTotals averages;

  /// Weekly kcal per meal: `Breakfast`, `Lunch`, `Dinner`, `Snack`.
  final Map<String, double> kcalByMenu;
  final WeeklyTopFood? topFood;
  final DateTime? heaviestDay;
  final DateTime? mostActiveDay;

  /// Coins earned from steps (same as [WeeklyCoins.steps]).
  final int coinsEarned;
  final int streak;

  /// Change against the previous week, in percent; null when that week had no data.
  final double? kcalAvgChangePercent;
  final double? stepsChangePercent;

  final WeeklyBody body;
  final WeeklyCoins coins;
  final WeeklyCourse course;
  final int friendsInvited;
  final int stepGroups;

  /// Localization keys: `perfect_week`, `consistent`, `step_master`,
  /// `step_goal`, `protein_pro`, `hydrated`.
  final List<String> badges;

  const WeeklyReport({
    required this.name,
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    this.loggedDays = 0,
    this.daysInNorm = 0,
    this.stepDaysInNorm = 0,
    this.waterDaysInNorm = 0,
    this.norms = const WeeklyReportNorms(),
    this.totals = const WeeklyReportTotals(),
    this.averages = const WeeklyReportTotals(),
    this.kcalByMenu = const {},
    this.topFood,
    this.heaviestDay,
    this.mostActiveDay,
    this.coinsEarned = 0,
    this.streak = 0,
    this.kcalAvgChangePercent,
    this.stepsChangePercent,
    this.body = const WeeklyBody(),
    this.coins = const WeeklyCoins(),
    this.course = const WeeklyCourse(),
    this.friendsInvited = 0,
    this.stepGroups = 0,
    this.badges = const [],
  });

  bool get hasFood => loggedDays > 0;

  bool get hasSteps => totals.steps > 0;

  bool get hasWater => totals.water > 0;

  /// Days with food, steps or water recorded.
  int get activeDays => days.where((d) => d.isActive).length;

  /// Nothing at all happened this week — no report to show.
  bool get isEmpty =>
      days.length != 7 ||
      (activeDays == 0 &&
          coins.earned == 0 &&
          course.isEmpty &&
          friendsInvited == 0);

  /// Raises days the server has fewer steps for to the device's own step
  /// ledger (steps not synced yet), then recomputes the step numbers.
  WeeklyReport mergeLocalSteps(Map<DateTime, int> local) {
    if (local.isEmpty || days.length != 7) return this;
    var changed = false;
    final merged = days.map((d) {
      final steps = local[DateTime(d.date.year, d.date.month, d.date.day)];
      if (steps == null || steps <= d.steps) return d;
      changed = true;
      return d.copyWithSteps(steps.toDouble());
    }).toList();
    if (!changed) return this;

    final total = merged.fold<double>(0, (s, d) => s + d.steps);
    final top = merged.reduce((a, b) => b.steps > a.steps ? b : a);
    return WeeklyReport(
      name: name,
      weekStart: weekStart,
      weekEnd: weekEnd,
      days: merged,
      loggedDays: loggedDays,
      daysInNorm: daysInNorm,
      stepDaysInNorm: norms.step > 0
          ? merged.where((d) => d.steps >= norms.step).length
          : stepDaysInNorm,
      waterDaysInNorm: waterDaysInNorm,
      norms: norms,
      totals: totals.copyWithSteps(total),
      averages: averages.copyWithSteps((total / 7).roundToDouble()),
      kcalByMenu: kcalByMenu,
      topFood: topFood,
      heaviestDay: heaviestDay,
      mostActiveDay: total > 0 ? top.date : null,
      coinsEarned: coinsEarned,
      streak: streak,
      kcalAvgChangePercent: kcalAvgChangePercent,
      stepsChangePercent: stepsChangePercent,
      body: body,
      coins: coins,
      course: course,
      friendsInvited: friendsInvited,
      stepGroups: stepGroups,
      badges: badges,
    );
  }

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final byMenu = (json['kcalByMenu'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, _d(value)),
    );
    final topFood = json['topFood'];
    return WeeklyReport(
      name: json['name'] as String? ?? '',
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      loggedDays: _i(json['loggedDays']),
      daysInNorm: _i(json['daysInNorm']),
      stepDaysInNorm: _i(json['stepDaysInNorm']),
      waterDaysInNorm: _i(json['waterDaysInNorm']),
      norms: WeeklyReportNorms.fromJson(json['norms'] as Map<String, dynamic>?),
      days: (json['days'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WeeklyReportDay.fromJson)
          .toList(),
      totals: WeeklyReportTotals.fromJson(
        json['totals'] as Map<String, dynamic>?,
      ),
      averages: WeeklyReportTotals.fromJson(
        json['averages'] as Map<String, dynamic>?,
      ),
      kcalByMenu: byMenu,
      topFood: topFood is Map<String, dynamic>
          ? WeeklyTopFood.fromJson(topFood)
          : null,
      heaviestDay: _date(json['heaviestDay']),
      mostActiveDay: _date(json['mostActiveDay']),
      coinsEarned: _i(json['coinsEarned']),
      streak: _i(json['streak']),
      kcalAvgChangePercent: (json['kcalAvgChangePercent'] as num?)?.toDouble(),
      stepsChangePercent: (json['stepsChangePercent'] as num?)?.toDouble(),
      body: WeeklyBody.fromJson(json['body'] as Map<String, dynamic>?),
      coins: WeeklyCoins.fromJson(json['coins'] as Map<String, dynamic>?),
      course: WeeklyCourse.fromJson(json['course'] as Map<String, dynamic>?),
      friendsInvited: _i(json['friendsInvited']),
      stepGroups: _i(json['stepGroups']),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}

double _d(Object? value) => (value as num?)?.toDouble() ?? 0;

int _i(Object? value) => (value as num?)?.toInt() ?? 0;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
