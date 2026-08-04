import '../models.dart';
import 'track_state.dart';
import 'trajectory_point.dart';

/// Prędkość 2D w pikselach/sekundę
class Velocity2D {
  final double vx; // piksele/sekundę w osi X
  final double vy; // piksele/sekundę w osi Y

  const Velocity2D({
    required this.vx,
    required this.vy,
  });

  /// Prędkość całkowita (skalarna)
  double get magnitude {
    return _sqrt(vx * vx + vy * vy);
  }

  /// Kierunek ruchu w radianach
  double get direction {
    return _atan2(vy, vx);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    if (x == 0 && y == 0) return 0;
    // Uproszczona implementacja atan2
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159;
    if (x == 0 && y > 0) return 3.14159 / 2;
    return -3.14159 / 2;
  }

  static double _atan(double x) {
    if (x.abs() > 1) {
      return (x > 0 ? 3.14159 / 2 : -3.14159 / 2) - _atan(1 / x);
    }
    // Aproksymacja Taylora
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }

  @override
  String toString() => 'Velocity2D(vx: $vx, vy: $vy, mag: $magnitude)';
}

/// Śledzony obiekt z unikalnym ID
class TrackedObject {
  /// Unikalne ID tracku
  final int id;

  /// Klasa obiektu (car, person, etc.)
  final String label;

  /// Aktualny bounding box
  final BoundingBox bbox;

  /// Pewność detekcji (średnia z ostatnich detekcji)
  final double confidence;

  /// Stan tracku
  final TrackState state;

  /// Wiek tracku (liczba klatek od utworzenia)
  final int age;

  /// Liczba udanych dopasowań
  final int hits;

  /// Liczba kolejnych brakujących detekcji
  final int missedUpdates;

  /// Timestamp pierwszego pojawienia się (mikrosekundy)
  final int firstSeenTimestampUs;

  /// Timestamp ostatniej detekcji (mikrosekundy)
  final int lastSeenTimestampUs;

  /// Prędkość obrazu w pikselach/sekundę
  final Velocity2D imageVelocity;

  /// Historia trajektorii
  final List<TrajectoryPoint> trajectory;

  /// Czy ten obiekt jest tylko predykcją (brak aktualnej detekcji)
  final bool predictedOnly;

  const TrackedObject({
    required this.id,
    required this.label,
    required this.bbox,
    required this.confidence,
    required this.state,
    required this.age,
    required this.hits,
    required this.missedUpdates,
    required this.firstSeenTimestampUs,
    required this.lastSeenTimestampUs,
    required this.imageVelocity,
    required this.trajectory,
    this.predictedOnly = false,
  });

  /// Tworzy kopię z nowymi wartościami
  TrackedObject copyWith({
    int? id,
    String? label,
    BoundingBox? bbox,
    double? confidence,
    TrackState? state,
    int? age,
    int? hits,
    int? missedUpdates,
    int? firstSeenTimestampUs,
    int? lastSeenTimestampUs,
    Velocity2D? imageVelocity,
    List<TrajectoryPoint>? trajectory,
    bool? predictedOnly,
  }) {
    return TrackedObject(
      id: id ?? this.id,
      label: label ?? this.label,
      bbox: bbox ?? this.bbox,
      confidence: confidence ?? this.confidence,
      state: state ?? this.state,
      age: age ?? this.age,
      hits: hits ?? this.hits,
      missedUpdates: missedUpdates ?? this.missedUpdates,
      firstSeenTimestampUs: firstSeenTimestampUs ?? this.firstSeenTimestampUs,
      lastSeenTimestampUs: lastSeenTimestampUs ?? this.lastSeenTimestampUs,
      imageVelocity: imageVelocity ?? this.imageVelocity,
      trajectory: trajectory ?? this.trajectory,
      predictedOnly: predictedOnly ?? this.predictedOnly,
    );
  }

  /// Czas życia tracku w milisekundach
  int get lifetimeMs {
    return (lastSeenTimestampUs - firstSeenTimestampUs) ~/ 1000;
  }

  /// Czas od ostatniej detekcji w milisekundach
  int timeSinceLastDetection(int currentTimestampUs) {
    return (currentTimestampUs - lastSeenTimestampUs) ~/ 1000;
  }

  @override
  String toString() {
    return 'TrackedObject(id: $id, label: $label, state: $state, '
        'hits: $hits, missed: $missedUpdates, bbox: $bbox)';
  }
}
