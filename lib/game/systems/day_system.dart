class DaySystem {
  double timeLeft = 30;
  bool didCompleteDay = false;

  void update(double dt) {
    timeLeft -= dt;
    if (timeLeft <= 0) {
      didCompleteDay = true;
    }
  }

  void startNewDay(int day) {
    // Keep each day short enough for MVP pacing.
    timeLeft = 30 + (day - 1) * 4;
  }

  void reset() {
    timeLeft = 30;
    didCompleteDay = false;
  }
}
