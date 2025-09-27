class LessonInfo {
  final int id;
  final double duration;
  final double calories;
  final double level;
  final bool isDayOff;
  final bool isLocked;
  final bool isCompleted;

  LessonInfo({
    required this.id,
    required this.duration,
    required this.calories,
    required this.level,
    this.isLocked = true,
    this.isDayOff = false,
    this.isCompleted = false,
  });
}
