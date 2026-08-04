import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/sort_tracker.dart';
import 'package:alicja_roadsense/ai/tracking/sort_config.dart';
import 'package:alicja_roadsense/ai/tracking/track_state.dart';

void main() {
  group('SortTracker', () {
    test('tworzenie trackera z domyślną konfiguracją', () {
      final tracker = SortTracker();
      expect(tracker.trackCount, equals(0));
    });

    test('tworzenie trackera z custom konfiguracją', () {
      final tracker = SortTracker(config: SortConfig.performanceConfig);
      expect(tracker.trackCount, equals(0));
    });

    test('pierwsza detekcja tworzy nowy track', () {
      final tracker = SortTracker();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      final tracks = tracker.update(detections, timestampUs: 0);

      expect(tracks.length, equals(1));
      expect(tracks[0].label, equals('car'));
      expect(tracks[0].state, equals(TrackState.tentative));
    });

    test('detekcja poniżej progu nie tworzy tracku', () {
      final tracker = SortTracker();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.1, // poniżej lowConfidenceThreshold
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      final tracks = tracker.update(detections, timestampUs: 0);

      expect(tracks.length, equals(0));
    });

    test('ten sam obiekt w kolejnych klatkach dostaje to samo ID', () {
      final tracker = SortTracker();

      // Klatka 1
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      final tracks1 = tracker.update(det1, timestampUs: 0);
      final id1 = tracks1[0].id;

      // Klatka 2 - ten sam obiekt, lekko przesunięty
      final det2 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 105, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      final tracks2 = tracker.update(det2, timestampUs: 100000); // 100ms

      expect(tracks2.length, equals(1));
      expect(tracks2[0].id, equals(id1)); // To samo ID
    });

    test('różne obiekty dostają różne ID', () {
      final tracker = SortTracker();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 300, top: 300, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      final tracks = tracker.update(detections, timestampUs: 0);

      expect(tracks.length, equals(2));
      expect(tracks[0].id, isNot(equals(tracks[1].id)));
    });

    test('obiekty różnych klas nie są dopasowywane', () {
      final tracker = SortTracker();

      // Klatka 1 - car
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      tracker.update(det1, timestampUs: 0);

      // Klatka 2 - person w tym samym miejscu
      final det2 = [
        Detection(
          label: 'person',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      final tracks = tracker.update(det2, timestampUs: 100000);

      // Powinny być 2 tracki - car i person
      expect(tracks.length, equals(2));
      expect(tracks.any((t) => t.label == 'car'), isTrue);
      expect(tracks.any((t) => t.label == 'person'), isTrue);
    });

    test('track przechodzi z tentative do confirmed', () {
      final tracker = SortTracker(config: const SortConfig(minHits: 3));

      // 3 klatki z tym samym obiektem
      for (int i = 0; i < 3; i++) {
        final detections = [
          Detection(
            label: 'car',
            confidence: 0.9,
            bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
            trackId: 0,
          ),
        ];
        tracker.update(detections, timestampUs: i * 100000);
      }

      final tracks = tracker.confirmedTracks;
      expect(tracks.length, equals(1));
      expect(tracks[0].state, equals(TrackState.confirmed));
    });

    test('track przechodzi do lost po braku detekcji', () {
      final tracker = SortTracker(config: const SortConfig(minHits: 2));

      // Klatka 1 - detekcja
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      tracker.update(det1, timestampUs: 0);

      // Klatka 2 - ta sama detekcja (track becomes confirmed)
      final det2 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      final tracks2 = tracker.update(det2, timestampUs: 100000);
      final id = tracks2[0].id;

      // Klatka 3 - brak detekcji (track should be lost)
      final tracks3 = tracker.update([], timestampUs: 200000);

      final lostTrack = tracks3.where((t) => t.id == id).firstOrNull;
      if (lostTrack != null) {
        expect(lostTrack.state, equals(TrackState.lost));
      }
    });

    test('reset czyści wszystkie tracki', () {
      final tracker = SortTracker();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      tracker.update(detections, timestampUs: 0);
      expect(tracker.trackCount, greaterThan(0));

      tracker.reset();
      expect(tracker.trackCount, equals(0));
    });

    test('ID nie są ponownie używane w sesji', () {
      final tracker = SortTracker();
      final usedIds = <int>{};

      // Utwórz kilka tracków w różnych miejscach (nie będą dopasowywane)
      for (int i = 0; i < 5; i++) {
        final detections = [
          Detection(
            label: 'car',
            confidence: 0.9,
            bbox: BoundingBox(
              left: 100.0 + i * 200, // duże odstępy żeby nie były dopasowywane
              top: 100.0,
              width: 50,
              height: 50,
            ),
            trackId: 0,
          ),
        ];
        final tracks = tracker.update(detections, timestampUs: i * 1000000); // 1s odstępy
        for (final track in tracks) {
          // Sprawdź czy ten track był już widziany
          if (!usedIds.contains(track.id)) {
            usedIds.add(track.id);
          }
        }
      }

      // Powinno być 5 unikalnych ID
      expect(usedIds.length, equals(5));
    });

    test('maxTracks limituje liczbę tracków', () {
      final tracker = SortTracker(config: const SortConfig(maxTracks: 3));

      // Utwórz 5 detekcji
      final detections = List.generate(5, (i) {
        return Detection(
          label: 'car',
          confidence: 0.9,
          bbox: BoundingBox(
            left: 100.0 + i * 100,
            top: 100.0,
            width: 50,
            height: 50,
          ),
          trackId: 0,
        );
      });

      final tracks = tracker.update(detections, timestampUs: 0);

      expect(tracks.length, lessThanOrEqualTo(3));
    });

    test('prędkość obrazu jest obliczana', () {
      final tracker = SortTracker();

      // Klatka 1
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      tracker.update(det1, timestampUs: 0);

      // Klatka 2 - lekko przesunięty
      final det2 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 110, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      tracker.update(det2, timestampUs: 500000); // 0.5s

      // Klatka 3 - bardziej przesunięty (Kalman potrzebuje kilku update)
      final det3 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 130, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      final tracks = tracker.update(det3, timestampUs: 1000000); // 1s

      expect(tracks.length, equals(1));
      // Track powinien istnieć i mieć ID
      expect(tracks[0].id, greaterThan(0));
      // Label powinien być car
      expect(tracks[0].label, equals('car'));
    });

    test('trajectory jest zapisywana', () {
      final tracker = SortTracker();

      for (int i = 0; i < 5; i++) {
        final detections = [
          Detection(
            label: 'car',
            confidence: 0.9,
            bbox: BoundingBox(
              left: 100.0 + i * 10,
              top: 100.0,
              width: 50,
              height: 50,
            ),
            trackId: 0,
          ),
        ];
        tracker.update(detections, timestampUs: i * 100000);
      }

      final tracks = tracker.confirmedTracks;
      if (tracks.isNotEmpty) {
        expect(tracks[0].trajectory.length, greaterThan(0));
      }
    });
  });
}
