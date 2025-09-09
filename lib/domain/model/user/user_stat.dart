class UserStat {
  final String firstName;
  final String lastName;
  final int stepCount;
  final int talks;
  final bool isMe;

  UserStat({
    required this.firstName,
    required this.lastName,
    required this.stepCount,
    required this.talks,
    this.isMe = false,
  });

  String getInitials() {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName[0];
    if (lastName.isEmpty) return firstName[0];
    return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
  }

  String get prettySteps => "$stepCount";
}