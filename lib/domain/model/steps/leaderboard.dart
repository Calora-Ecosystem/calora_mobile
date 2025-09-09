class UserStat {
  final String name;
  final String initials;
  final int talks;
  final String scoreText;
  final bool isMe;

  UserStat({
    required this.name,
    required this.initials,
    required this.talks,
    required this.scoreText,
    this.isMe = false,
  });
}
