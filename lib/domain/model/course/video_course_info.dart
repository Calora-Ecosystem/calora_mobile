class VideoCourseInfo {
  final String name;
  final String videoUrl;
  final Duration duration;
  final bool isWatched;

  VideoCourseInfo({
    required this.name,
    this.videoUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    required this.duration,
    this.isWatched = false,
  });
}

class CoursesInfo {
  final String name;
  final String price;
  final Duration duration;
  final bool purchased;
  final List<VideoCourseInfo> videoCourses;

  CoursesInfo({
    required this.videoCourses,
    required this.name,
    required this.price,
    required this.duration,
    this.purchased = false,
  });
}
