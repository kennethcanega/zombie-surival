class DaySystem {
  // Make days 2 minutes longer than the original 30s baseline.
  static const double _baseDaySeconds = 150;
  double timeLeft = _baseDaySeconds;
  bool didCompleteDay = false;

  void update(double dt) {
    timeLeft -= dt;
    if (timeLeft <= 0) {
      didCompleteDay = true;
    }
  }

  void startNewDay(int day) {
    timeLeft = _baseDaySeconds + (day - 1) * 8;
  }

  void reset() {
    timeLeft = _baseDaySeconds;
    didCompleteDay = false;
  }
}
