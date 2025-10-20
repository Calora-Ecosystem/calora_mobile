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
