import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/kalman_box_tracker.dart';

void main() {
  group('KalmanBoxTracker', () {
    test('inicjalizacja z bounding box', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);

      final predicted = tracker.predictedBbox;
      expect(predicted.left, closeTo(100, 5));
      expect(predicted.top, closeTo(100, 5));
      expect(predicted.width, closeTo(50, 5));
      expect(predicted.height, closeTo(50, 5));
    });

    test('predict bez aktualizacji', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);
      tracker.predict(100000); // 100ms później

      final predicted = tracker.predictedBbox;
      // Bez prędkości pozycja powinna być podobna
      expect(predicted.left, closeTo(100, 10));
      expect(predicted.top, closeTo(100, 10));
    });

    test('update z nową detekcją', () {
      final tracker = KalmanBoxTracker();
      const bbox1 = BoundingBox(left: 100, top: 100, width: 50, height: 50);
      const bbox2 = BoundingBox(left: 110, top: 100, width: 50, height: 50);

      tracker.initialize(bbox1, 0);
      tracker.update(bbox2, 100000); // 100ms później, przesunięty o 10px

      final predicted = tracker.predictedBbox;
      // Powinien być blisko nowej pozycji
      expect(predicted.left, closeTo(110, 10));
    });

    test('trajectory jest zapisywana', () {
      final tracker = KalmanBoxTracker(maxTrajectoryLength: 5);
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);
      tracker.update(bbox, 100000);
      tracker.update(bbox, 200000);
      tracker.update(bbox, 300000);

      expect(tracker.trajectory.length, equals(4)); // initial + 3 updates
    });

    test('trajectory ma ograniczoną długość', () {
      final tracker = KalmanBoxTracker(maxTrajectoryLength: 3);
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);
      for (int i = 1; i <= 10; i++) {
        tracker.update(bbox, i * 100000);
      }

      expect(tracker.trajectory.length, lessThanOrEqualTo(3));
    });

    test('velocity jest obliczana', () {
      final tracker = KalmanBoxTracker();
      const bbox1 = BoundingBox(left: 100, top: 100, width: 50, height: 50);
      const bbox2 = BoundingBox(left: 150, top: 100, width: 50, height: 50);

      tracker.initialize(bbox1, 0);
      tracker.update(bbox2, 1000000); // 1s później, przesunięty o 50px

      // Prędkość powinna być > 0
      expect(tracker.velocity, greaterThan(0));
    });

    test('lastTimestampUs jest aktualizowany', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 1000);
      expect(tracker.lastTimestampUs, equals(1000));

      tracker.update(bbox, 2000);
      expect(tracker.lastTimestampUs, equals(2000));
    });

    test('state ma 7 elementów', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);

      expect(tracker.state.length, equals(7));
    });

    test('predictedBbox bez inicjalizacji zwraca pusty bbox', () {
      final tracker = KalmanBoxTracker();

      final predicted = tracker.predictedBbox;

      expect(predicted.left, equals(0));
      expect(predicted.top, equals(0));
      expect(predicted.width, equals(0));
      expect(predicted.height, equals(0));
    });

    test('różny deltaTime nie powoduje NaN', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);

      // Bardzo mały deltaTime
      tracker.predict(1);
      expect(tracker.predictedBbox.left.isNaN, isFalse);

      // Duży deltaTime
      tracker.predict(10000000);
      expect(tracker.predictedBbox.left.isNaN, isFalse);
    });

    test('ujemne wymiary bbox są korygowane', () {
      final tracker = KalmanBoxTracker();
      const bbox = BoundingBox(left: 100, top: 100, width: 50, height: 50);

      tracker.initialize(bbox, 0);
      tracker.predict(100000);

      final predicted = tracker.predictedBbox;
      expect(predicted.width, greaterThanOrEqualTo(0));
      expect(predicted.height, greaterThanOrEqualTo(0));
    });
  });
}
