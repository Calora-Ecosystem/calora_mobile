import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Singleton event bus used by `DashboardPage` to tell `CourseManager`
/// "the Course bottom-nav tab was just tapped — refetch."
///
/// Lives in `service/` rather than the presentation layer because both
/// the dashboard (publisher) and the course manager (subscriber) need a
/// shared, app-wide instance — and DI ownership is conceptually a
/// cross-feature plumbing concern, not feature-local state.
@lazySingleton
class CourseTabSignal {
  final PublishSubject<void> _subject = PublishSubject<void>();

  Stream<void> get stream => _subject.stream;

  void fire() => _subject.add(null);

  @disposeMethod
  void dispose() => _subject.close();
}
