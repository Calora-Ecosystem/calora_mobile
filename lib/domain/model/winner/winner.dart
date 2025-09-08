class Winner {
  final String firstName;
  final String lastName;
  final int stepCount;

  Winner({
    required this.firstName,
    required this.lastName,
    required this.stepCount,
  });

  String getInitials() {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (firstName.isEmpty) return lastName[0];
    if (lastName.isEmpty) return firstName[0];
    return '${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}';
  }
}
