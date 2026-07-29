import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/models.dart';

void main() {
  group('Detection', () {
    test('should identify vehicle correctly', () {
      final detection = Detection(
        label: 'car',
        confidence: 0.95,
        bbox: Rect(left: 0, top: 0, width: 100, height: 100),
        trackId: 1,
      );

      expect(detection.isVehicle, true);
      expect(detection.isPedestrian, false);
    });

    test('should identify pedestrian correctly', () {
      final detection = Detection(
        label: 'person',
        confidence: 0.88,
        bbox: Rect(left: 0, top: 0, width: 50, height: 150),
        trackId: 2,
      );

      expect(detection.isVehicle, false);
      expect(detection.isPedestrian, true);
    });

    test('should calculate risk level based on TTC', () {
      final critical = Detection(
        label: 'car',
        confidence: 0.9,
        bbox: Rect(left: 0, top: 0, width: 100, height: 100),
        ttc: 1.5,
        trackId: 3,
      );

      final high = Detection(
        label: 'car',
        confidence: 0.9,
        bbox: Rect(left: 0, top: 0, width: 100, height: 100),
        ttc: 3.0,
        trackId: 4,
      );

      final medium = Detection(
        label: 'car',
        confidence: 0.9,
        bbox: Rect(left: 0, top: 0, width: 100, height: 100),
        ttc: 5.0,
        trackId: 5,
      );

      final low = Detection(
        label: 'car',
        confidence: 0.9,
        bbox: Rect(left: 0, top: 0, width: 100, height: 100),
        ttc: 8.0,
        trackId: 6,
      );

      expect(critical.riskLevel, RiskLevel.critical);
      expect(high.riskLevel, RiskLevel.high);
      expect(medium.riskLevel, RiskLevel.medium);
      expect(low.riskLevel, RiskLevel.low);
    });
  });

  group('Rect', () {
    test('should calculate center correctly', () {
      final rect = Rect(left: 10, top: 20, width: 100, height: 50);

      expect(rect.centerX, 60);
      expect(rect.centerY, 45);
    });

    test('should calculate area correctly', () {
      final rect = Rect(left: 0, top: 0, width: 100, height: 50);

      expect(rect.area, 5000);
    });
  });
}
