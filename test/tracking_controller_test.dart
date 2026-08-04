import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/tracking_controller.dart';
import 'package:alicja_roadsense/ai/tracking/track_state.dart';

void main() {
  group('TrackingController', () {
    test('inicjalizacja z pustym stanem', () {
      final controller = TrackingController();

      expect(controller.state.objects, isEmpty);
      expect(controller.state.processedFrames, equals(0));
      expect(controller.state.error, isNull);
      expect(controller.isActive, isTrue);

      controller.dispose();
    });

    test('processDetections tworzy track z detekcji', () {
      final controller = TrackingController();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      controller.processDetections(
        detections: detections,
        sourceImageSize: const Size(640, 480),
      );

      expect(controller.state.objects.length, equals(1));
      expect(controller.state.processedFrames, equals(1));
      expect(controller.state.objects[0].label, equals('car'));

      controller.dispose();
    });

    test('ten sam obiekt zachowuje ID między klatkami', () {
      final controller = TrackingController();

      // Klatka 1
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      controller.processDetections(
        detections: det1,
        sourceImageSize: const Size(640, 480),
      );
      final id1 = controller.state.objects[0].id;

      // Klatka 2 - ten sam obiekt, lekko przesunięty
      final det2 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 105, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      controller.processDetections(
        detections: det2,
        sourceImageSize: const Size(640, 480),
      );

      expect(controller.state.objects.length, equals(1));
      expect(controller.state.objects[0].id, equals(id1));

      controller.dispose();
    });

    test('różne klasy nie są łączone', () {
      final controller = TrackingController();

      // Klatka 1 - car
      final det1 = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      controller.processDetections(
        detections: det1,
        sourceImageSize: const Size(640, 480),
      );

      // Klatka 2 - person w tym samym miejscu
      final det2 = [
        Detection(
          label: 'person',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];
      controller.processDetections(
        detections: det2,
        sourceImageSize: const Size(640, 480),
      );

      // Powinny być 2 tracki - car i person
      expect(controller.state.objects.length, equals(2));
      expect(controller.state.objects.any((t) => t.label == 'car'), isTrue);
      expect(controller.state.objects.any((t) => t.label == 'person'), isTrue);

      controller.dispose();
    });

    test('reset czyści wszystkie tracki', () {
      final controller = TrackingController();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      controller.processDetections(
        detections: detections,
        sourceImageSize: const Size(640, 480),
      );
      expect(controller.state.objects.length, equals(1));

      controller.reset();
      expect(controller.state.objects, isEmpty);
      expect(controller.state.processedFrames, equals(0));

      controller.dispose();
    });

    test('backpressure - pomija klatki gdy przetwarzanie trwa', () {
      final controller = TrackingController();
      final detections = [
        Detection(
          label: 'car',
          confidence: 0.9,
          bbox: const BoundingBox(left: 100, top: 100, width: 50, height: 50),
          trackId: 0,
        ),
      ];

      // Pierwsze wywołanie powinno zadziałać
      controller.processDetections(
        detections: detections,
        sourceImageSize: const Size(640, 480),
      );
      expect(controller.state.processedFrames, equals(1));

      // Drugie wywołanie powinno też zadziałać (nie ma blokady)
      controller.processDetections(
        detections: detections,
        sourceImageSize: const Size(640, 480),
      );
      expect(controller.state.processedFrames, equals(2));

      controller.dispose();
    });

    test('puste detekcje nie powodują błędów', () {
      final controller = TrackingController();

      controller.processDetections(
        detections: [],
        sourceImageSize: const Size(640, 480),
      );

      expect(controller.state.objects, isEmpty);
      expect(controller.state.error, isNull);
      expect(controller.state.processedFrames, equals(1));

      controller.dispose();
    });

    test('confirmedTracks zwraca tylko CONFIRMED tracki', () {
      final controller = TrackingController();

      // Dodaj kilka detekcji żeby tracki stały się CONFIRMED
      for (int i = 0; i < 5; i++) {
        final detections = [
          Detection(
            label: 'car',
            confidence: 0.9,
            bbox: BoundingBox(
              left: 100.0 + i * 5,
              top: 100.0,
              width: 50,
              height: 50,
            ),
            trackId: 0,
          ),
        ];
        controller.processDetections(
          detections: detections,
          sourceImageSize: const Size(640, 480),
        );
      }

      final confirmed = controller.confirmedTracks;
      for (final track in confirmed) {
        expect(track.state, equals(TrackState.confirmed));
      }

      controller.dispose();
    });

    test('sessionId zmienia się po resecie', () {
      final controller = TrackingController();
      final initialSessionId = controller.state.sessionId;

      controller.reset();

      expect(controller.state.sessionId, equals(initialSessionId + 1));

      controller.dispose();
    });
  });
}
