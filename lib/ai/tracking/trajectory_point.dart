/// Punkt trajektorii obiektu
class TrajectoryPoint {
  /// Środek bounding box (x)
  final double centerX;

  /// Środek bounding box (y)
  final double centerY;

  /// Timestamp w mikrosekundach
  final int timestampUs;

  const TrajectoryPoint({
    required this.centerX,
    required this.centerY,
    required this.timestampUs,
  });

  /// Oblicza prędkość w pikselach/sekundę do innego punktu
  double velocityTo(TrajectoryPoint other) {
    final dx = other.centerX - centerX;
    final dy = other.centerY - centerY;
    final distance = _hypot(dx, dy);
    final deltaTimeSec = (other.timestampUs - timestampUs) / 1000000.0;

    if (deltaTimeSec <= 0) return 0.0;
    return distance / deltaTimeSec;
  }

  static double _hypot(double x, double y) {
    return x * x + y * y;
  }

  @override
  String toString() =>
      'TrajectoryPoint(center: ($centerX, $centerY), time: $timestampUs)';
}
