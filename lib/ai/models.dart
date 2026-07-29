class Detection {
  final String label;
  final double confidence;
  final Rect bbox;
  final double? distance;
  final double? velocity;
  final double? ttc;
  final int trackId;

  Detection({
    required this.label,
    required this.confidence,
    required this.bbox,
    this.distance,
    this.velocity,
    this.ttc,
    required this.trackId,
  });

  bool get isVehicle =>
      label == 'car' ||
      label == 'truck' ||
      label == 'bus' ||
      label == 'motorcycle' ||
      label == 'bicycle';

  bool get isPedestrian => label == 'person';

  RiskLevel get riskLevel {
    if (ttc == null) return RiskLevel.low;
    if (ttc! < 2.0) return RiskLevel.critical;
    if (ttc! < 4.0) return RiskLevel.high;
    if (ttc! < 6.0) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
  double get area => width * height;
}
