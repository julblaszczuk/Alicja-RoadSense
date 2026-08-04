import '../models.dart';
import 'sort_config.dart';
import 'kalman_box_tracker.dart';
import 'tracked_object.dart';
import 'track_state.dart';
import 'trajectory_point.dart';
import 'iou_utils.dart';
import 'linear_assignment.dart';

/// Internal tracker z Kalman Filter
class _InternalTrack {
  final int id;
  final KalmanBoxTracker kalman;
  String label;
  double confidence;
  TrackState state;
  int age;
  int hits;
  int missedUpdates;
  int firstSeenTimestampUs;
  int lastSeenTimestampUs;
  List<double> confidences;

  _InternalTrack({
    required this.id,
    required this.kalman,
    required this.label,
    required this.confidence,
    required this.firstSeenTimestampUs,
  })  : state = TrackState.tentative,
        age = 0,
        hits = 0,
        missedUpdates = 0,
        lastSeenTimestampUs = firstSeenTimestampUs,
        confidences = [confidence];
}

/// SORT Tracker - Simple Online and Realtime Tracking
///
/// Śledzi obiekty między klatkami z użyciem Kalman Filter
/// i Hungarian Algorithm do dopasowania.
class SortTracker {
  final SortConfig _config;
  final List<_InternalTrack> _tracks = [];
  int _nextId = 1;

  SortTracker({SortConfig? config}) : _config = config ?? SortConfig.defaultConfig;

  /// Aktualizuje tracker z nowymi detekcjami
  ///
  /// [detections] - lista detekcji z YOLO
  /// [timestampUs] - timestamp klatki w mikrosekundach
  ///
  /// Zwraca listę śledzonych obiektów
  List<TrackedObject> update(
    List<Detection> detections, {
    required int timestampUs,
  }) {
    // 1. Filtruj detekcje po confidence
    final validDetections = detections.where((d) {
      return d.confidence >= _config.lowConfidenceThreshold;
    }).toList();

    // 2. Predykcja wszystkich tracków
    for (final track in _tracks) {
      track.kalman.predict(timestampUs);
      track.age++;
    }

    // 3. Dopasowanie detekcji do tracków
    final matchedTrackIds = <int>{};
    final matchedDetectionIds = <int>{};

    if (_tracks.isNotEmpty && validDetections.isNotEmpty) {
      // Grupuj po klasie
      final tracksByLabel = <String, List<_InternalTrack>>{};
      for (final track in _tracks) {
        tracksByLabel.putIfAbsent(track.label, () => []).add(track);
      }

      final detectionsByLabel = <String, List<Detection>>{};
      for (final det in validDetections) {
        detectionsByLabel.putIfAbsent(det.label, () => []).add(det);
      }

      // Dopasuj dla każdej klasy osobno
      for (final label in tracksByLabel.keys) {
        final tracks = tracksByLabel[label]!;
        final dets = detectionsByLabel[label] ?? [];

        if (dets.isEmpty) continue;

        // Oblicz macierz IoU
        final trackBoxes = tracks.map((t) => t.kalman.predictedBbox).toList();
        final detBoxes = dets.map((d) => d.bbox).toList();
        final iouMatrix = calculateIoUMatrix(trackBoxes, detBoxes);

        // Dopasuj
        final assignments = matchTracksToDetections(iouMatrix, _config.iouThreshold);

        for (final pair in assignments) {
          final trackIdx = pair[0];
          final detIdx = pair[1];

          final track = tracks[trackIdx];
          final det = dets[detIdx];

          // Aktualizuj track
          track.kalman.update(det.bbox, timestampUs);
          track.confidences.add(det.confidence);
          if (track.confidences.length > 10) {
            track.confidences.removeAt(0);
          }
          track.confidence = track.confidences.reduce((a, b) => a + b) / track.confidences.length;
          track.hits++;
          track.missedUpdates = 0;
          track.lastSeenTimestampUs = timestampUs;

          // Aktualizuj stan
          if (track.state == TrackState.tentative && track.hits >= _config.minHits) {
            track.state = TrackState.confirmed;
          } else if (track.state == TrackState.lost) {
            track.state = TrackState.confirmed;
          }

          matchedTrackIds.add(track.id);
          matchedDetectionIds.add(dets.indexOf(det));
        }
      }
    }

    // 4. Utwórz nowe tracki z niedopasowanych detekcji
    for (int i = 0; i < validDetections.length; i++) {
      if (matchedDetectionIds.contains(i)) continue;
      if (_tracks.length >= _config.maxTracks) break;

      final det = validDetections[i];
      if (det.confidence < _config.highConfidenceThreshold) continue;

      final kalman = KalmanBoxTracker(maxTrajectoryLength: _config.trajectoryLength);
      kalman.initialize(det.bbox, timestampUs);

      final track = _InternalTrack(
        id: _nextId++,
        kalman: kalman,
        label: det.label,
        confidence: det.confidence,
        firstSeenTimestampUs: timestampUs,
      );
      track.hits = 1; // Pierwsza detekcja

      _tracks.add(track);
    }

    // 5. Oznacz niedopasowane tracki jako utracone
    for (final track in _tracks) {
      if (matchedTrackIds.contains(track.id)) continue;

      track.missedUpdates++;

      if (track.state == TrackState.confirmed) {
        track.state = TrackState.lost;
      }
    }

    // 6. Usuń stare tracki
    _tracks.removeWhere((track) {
      if (track.state == TrackState.tentative) {
        final timeSinceCreation = timestampUs - track.firstSeenTimestampUs;
        return timeSinceCreation > _config.tentativeTimeout.inMicroseconds;
      }
      if (track.state == TrackState.lost) {
        final timeSinceLastDetection = timestampUs - track.lastSeenTimestampUs;
        return timeSinceLastDetection > _config.lostTimeout.inMicroseconds;
      }
      return false;
    });

    // 7. Konwertuj na TrackedObject
    return _tracks.map((track) {
      final kalman = track.kalman;
      final velocity = kalman.velocity;

      // Oblicz kierunek prędkości
      final state = kalman.state;
      final vx = state.length > 4 ? state[4] : 0.0;
      final vy = state.length > 5 ? state[5] : 0.0;

      return TrackedObject(
        id: track.id,
        label: track.label,
        bbox: kalman.predictedBbox,
        confidence: track.confidence,
        state: track.state,
        age: track.age,
        hits: track.hits,
        missedUpdates: track.missedUpdates,
        firstSeenTimestampUs: track.firstSeenTimestampUs,
        lastSeenTimestampUs: track.lastSeenTimestampUs,
        imageVelocity: Velocity2D(vx: vx, vy: vy),
        trajectory: kalman.trajectory,
        predictedOnly: track.missedUpdates > 0,
      );
    }).toList();
  }

  /// Resetuje tracker
  void reset() {
    _tracks.clear();
    _nextId = 1;
  }

  /// Zwraca liczbę aktywnych tracków
  int get trackCount => _tracks.length;

  /// Zwraca tracki w stanie confirmed
  List<TrackedObject> get confirmedTracks {
    return _tracks
        .where((t) => t.state == TrackState.confirmed)
        .map((track) {
          final kalman = track.kalman;
          final state = kalman.state;
          final vx = state.length > 4 ? state[4] : 0.0;
          final vy = state.length > 5 ? state[5] : 0.0;

          return TrackedObject(
            id: track.id,
            label: track.label,
            bbox: kalman.predictedBbox,
            confidence: track.confidence,
            state: track.state,
            age: track.age,
            hits: track.hits,
            missedUpdates: track.missedUpdates,
            firstSeenTimestampUs: track.firstSeenTimestampUs,
            lastSeenTimestampUs: track.lastSeenTimestampUs,
            imageVelocity: Velocity2D(vx: vx, vy: vy),
            trajectory: kalman.trajectory,
            predictedOnly: track.missedUpdates > 0,
          );
        })
        .toList();
  }
}
