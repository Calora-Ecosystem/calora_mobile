Duration parseDuration(String value) {
  final parts = value.split(':').map(int.parse).toList();

  if (parts.length == 3) {
    return Duration(
      hours: parts[0],
      minutes: parts[1],
      seconds: parts[2],
    );
  } else if (parts.length == 2) {
    return Duration(
      minutes: parts[0],
      seconds: parts[1],
    );
  } else {
    return Duration(seconds: parts[0]);
  }
}
