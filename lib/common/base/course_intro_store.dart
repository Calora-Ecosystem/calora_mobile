import 'package:calora/common/di/injection.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';

/// Tracks which workout courses the user has already completed the
/// 3-step intro questionnaire for. The `CourseQuestionsRoute` is gated
/// on this — first tap opens the questionnaire → ProgressRoute →
/// LessonsRoute; every later tap on the same course skips straight to
/// LessonsRoute.
///
/// Deliberately NOT wired through injectable — it's a thin
/// SharedPreferences wrapper with static state, so callers just
/// `CourseIntroStore()` inline (mirrors `StepLedgerStore`).
class CourseIntroStore {
  static const _key = 'course_intro_completed';

  final _prefs = getIt<RxSharedPreferences>();

  Future<Set<int>> getCompleted() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <int>{};
    return raw
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<bool> isCompleted(int courseId) async {
    if (courseId <= 0) return false;
    final set = await getCompleted();
    return set.contains(courseId);
  }

  Future<void> markCompleted(int courseId) async {
    if (courseId <= 0) return;
    final current = await getCompleted();
    if (current.contains(courseId)) return;
    final next = {...current, courseId};
    await _prefs.setString(_key, next.join(','));
  }
}
