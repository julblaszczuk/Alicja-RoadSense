import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/risk_scorer.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/tracked_object.dart';
import 'package:alicja_roadsense/ai/tracking/track_state.dart';
import 'package:alicja_roadsense/ai/tracking/trajectory_point.dart';

void main() {
  group('RiskScorer', () {
    late RiskScorer scorer;

    setUp(() {
      scorer = RiskScorer();
    });

    TrackedObject createTrack({
      int id = 1,
      String label = 'car',
      double confidence = 0.9,
      TrackState state = TrackState.confirmed,
    }) {
      return TrackedObject(
        id: id,
        label: label,
        bbox: BoundingBox(left: 100, top: 100, width: 100, height: 100),
        confidence: confidence,
        state: state,
        age: 10,
        hits: 10,
        missedUpdates: 0,
        firstSeenTimestampUs: 0,
        lastSeenTimestampUs: 1000000,
        imageVelocity: const Velocity2D(vx: 50, vy: 0),
        trajectory: [],
      );
    }

    test('ocenia ryzyko krytyczne dla niskiego TTC', () {
      final track = createTrack();

      final assessment = scorer.assessRisk(
        track,
        ttc: 1.5, // poniżej 2s = critical
        distance: 15.0,
      );

      expect(assessment.level, equals(RiskLevel.critical));
      expect(assessment.score, greaterThanOrEqualTo(70)); // TTC ma dużą wagę
    });

    test('ocenia ryzyko wysokie dla średniego TTC', () {
      final track = createTrack();

      final assessment = scorer.assessRisk(
        track,
        ttc: 3.0, // między 2s a 4s = high
        distance: 25.0,
      );

      expect(assessment.level, equals(RiskLevel.high));
    });

    test('ocenia ryzyko niskie dla wysokiego TTC', () {
      final track = createTrack();

      final assessment = scorer.assessRisk(
        track,
        ttc: 8.0, // powyżej 6s = low
        distance: 50.0,
      );

      expect(assessment.level, equals(RiskLevel.low));
    });

    test('pieszy ma wyższe ryzyko niż samochód', () {
      final carTrack = createTrack(label: 'car');
      final personTrack = createTrack(label: 'person');

      final carRisk = scorer.assessRisk(carTrack, ttc: 5.0, distance: 30.0);
      final personRisk = scorer.assessRisk(personTrack, ttc: 5.0, distance: 30.0);

      expect(personRisk.score, greaterThan(carRisk.score));
    });

    test('nie ocenia ryzyka dla tracku niepotwierdzonego', () {
      final track = createTrack(state: TrackState.tentative);

      final assessment = scorer.assessRisk(track, ttc: 2.0);

      expect(assessment.level, equals(RiskLevel.low));
      expect(assessment.score, equals(0));
    });

    test('generuje opis dla krytycznego ryzyka', () {
      final track = createTrack(label: 'car');

      final assessment = scorer.assessRisk(track, ttc: 1.5);

      expect(assessment.description, contains('KRYTYCZNE'));
      expect(assessment.description, contains('car'));
    });

    test('ocenia ryzyko dla wszystkich tracków', () {
      final tracks = [
        createTrack(id: 1, label: 'car'),
        createTrack(id: 2, label: 'person'),
      ];

      final ttcMap = {1: 3.0, 2: 1.5};
      final riskMap = scorer.assessAllRisks(tracks, ttcMap: ttcMap);

      expect(riskMap.length, equals(2));
      expect(riskMap.containsKey(1), isTrue);
      expect(riskMap.containsKey(2), isTrue);
    });

    test('znajduje track z najwyższym ryzykiem', () {
      final tracks = [
        createTrack(id: 1),
        createTrack(id: 2),
      ];

      final ttcMap = {1: 5.0, 2: 1.0}; // track 2 ma niższe TTC = wyższe ryzyko
      final riskMap = scorer.assessAllRisks(tracks, ttcMap: ttcMap);

      final highest = scorer.getHighestRisk(riskMap);

      expect(highest, isNotNull);
      expect(highest!.level, equals(RiskLevel.critical));
    });

    test('requiresImmediateAttention dla critical i high', () {
      final track = createTrack();

      final criticalRisk = scorer.assessRisk(track, ttc: 1.5);
      final highRisk = scorer.assessRisk(track, ttc: 3.0);
      final mediumRisk = scorer.assessRisk(track, ttc: 5.0);
      final lowRisk = scorer.assessRisk(track, ttc: 8.0);

      expect(criticalRisk.requiresImmediateAttention, isTrue);
      expect(highRisk.requiresImmediateAttention, isTrue);
      expect(mediumRisk.requiresImmediateAttention, isFalse);
      expect(lowRisk.requiresImmediateAttention, isFalse);
    });
  });
}
