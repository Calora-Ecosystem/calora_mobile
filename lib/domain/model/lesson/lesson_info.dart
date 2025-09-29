class LessonInfo {
  final int id;
  final double duration;
  final double calories;
  final double level;
  final bool isDayOff;
  final bool isLocked;
  final bool isCompleted;
  final List<TaskInfo> tasks;

  LessonInfo({
    required this.tasks,
    required this.id,
    required this.duration,
    required this.calories,
    required this.level,
    this.isLocked = true,
    this.isDayOff = false,
    this.isCompleted = false,
  });

  factory LessonInfo.empty() => LessonInfo(
    id: 0,
    duration: 0,
    calories: 0,
    level: 0,
    tasks: const [],
    isLocked: true,
    isDayOff: false,
    isCompleted: false,
  );
}

class TaskInfo {
  final String count;
  final String title;
  final bool isCompleted;

  TaskInfo({required this.count, required this.title, this.isCompleted = false});

  factory TaskInfo.empty() => TaskInfo(count: '0', title: '', isCompleted: false);
}
