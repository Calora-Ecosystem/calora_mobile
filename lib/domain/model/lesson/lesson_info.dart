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
}

class TaskInfo {
  final String count;
  final String title;
  final bool isCompleted;
  final int duration;
  final String videoUrl;
  final String descriptionTitle;
  final String description;

  TaskInfo({
    this.descriptionTitle = 'Press mashqi (qorin muskullari uchun)',
    this.description = '',
    this.videoUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    this.duration = 30,
    required this.count,
    required this.title,
    this.isCompleted = false,
  });
}

sealed class LessonCardData {}

class LessonData extends LessonCardData {
  final LessonInfo lessonInfo;

  LessonData(this.lessonInfo);
}

class TaskData extends LessonCardData {
  final TaskInfo taskInfo;

  TaskData(this.taskInfo);
}
