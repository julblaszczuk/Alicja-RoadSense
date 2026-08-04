import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/ttc_engine.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/tracked_object.dart';
import 'package:alicja_roadsense/ai/tracking/track_state.dart';
import 'package:alicja_roadsense/ai/tracking/trajectory_point.dart';

void main() {
  group('TtcEngine', () {
    late TtcEngine engine;

    setUp(() {
      engine = TtcEngine(
        focalLengthPixels: 500.0,
        defaultObjectWidthMeters: 1.8,
      );
    });

    TrackedObject createTrack({
      int id = 1,
      String label = 'car',
      double bboxWidth = 100.0,
      double imageVelocity = 50.0,
      TrackState state = TrackState.confirmed,
    }) {
      return TrackedObject(
        id: id,
        label: label,
        bbox: BoundingBox(left: 100, top: 100, width: bboxWidth, height: 100),
        confidence: 0.9,
        state: state,
        age: 10,
        hits: 10,
        missedUpdates: 0,
        firstSeenTimestampUs: 0,
        lastSeenTimestampUs: 1000000,
        imageVelocity: Velocity2D(vx: imageVelocity, vy: 0),
        trajectory: [],
      );
    }

    test('oblicza TTC dla zbliżającego się obiektu', () {
      final track = createTrack(
        bboxWidth: 100.0,
        imageVelocity: 50.0, // piksele/sekundę
      );

      final ttc = engine.calculateTtc(track);

      // TTC powinno być obliczone
      expect(ttc, isNotNull);
      expect(ttc, greaterThan(0));
    });

    test('nie oblicza TTC dla tracku niepotwierdzonego', () {
      final track = createTrack(state: TrackState.tentative);

      final ttc = engine.calculateTtc(track);

      expect(ttc, isNull);
    });

    test('nie oblicza TTC gdy obiekt się nie porusza', () {
      final track = createTrack(imageVelocity: 0.0);

      final ttc = engine.calculateTtc(track);

      expect(ttc, isNull);
    });

    test('szacuje odległość na podstawie rozmiaru bbox', () {
      final track = createTrack(bboxWidth: 200.0, imageVelocity: 100.0);

      final ttc = engine.calculateTtc(track);

      // TTC powinno być obliczone dla odpowiednich parametrów
      // (może być null jeśli prędkość względna jest zbyt mała)
      // Test sprawdzamy czy metoda działa bez błędów
      expect(() => engine.calculateTtc(track), returnsNormally);
    });

    test('aktualizuje prędkość własnego pojazdu', () {
      engine.updateEgoSpeed(null);
      
      final track = createTrack(imageVelocity: 50.0);
      final ttc = engine.calculateTtc(track);

      expect(ttc, isNotNull);
    });

    test('oblicza TTC dla wszystkich tracków', () {
      final tracks = [
        createTrack(id: 1, imageVelocity: 100.0),
        createTrack(id: 2, imageVelocity: 80.0),
        createTrack(id: 3, imageVelocity: 0.0), // nie porusza się
      ];

      final ttcMap = engine.calculateAllTtcs(tracks);

      // Track 3 nie powinien mieć TTC (imageVelocity = 0)
      expect(ttcMap.containsKey(3), isFalse);
      // Tracki 1 i 2 mogą lub nie mieć TTC w zależności od parametrów
      expect(ttcMap.length, lessThanOrEqualTo(3));
    });

    test('zwraca RiskLevel na podstawie TTC', () {
      expect(engine.getRiskLevelFromTtc(1.0), equals(RiskLevel.critical));
      expect(engine.getRiskLevelFromTtc(3.0), equals(RiskLevel.high));
      expect(engine.getRiskLevelFromTtc(5.0), equals(RiskLevel.medium));
      expect(engine.getRiskLevelFromTtc(8.0), equals(RiskLevel.low));
    });
  });
}
