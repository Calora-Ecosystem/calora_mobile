enum ConnectionQuality {
  excellent,
  good,
  average,
  poor,
  none,
  fair;

  bool get isGood => this == ConnectionQuality.good;

  bool get isBad =>
      this == ConnectionQuality.none || this == ConnectionQuality.poor;

  bool get isFair => this == ConnectionQuality.fair;

  bool get isExcellent => this == ConnectionQuality.excellent;
}
