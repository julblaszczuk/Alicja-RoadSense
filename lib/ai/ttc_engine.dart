import 'dart:math';
import 'models.dart';
import 'tracking/tracked_object.dart';
import 'tracking/track_state.dart';
import '../core/gps_provider.dart';

/// Silnik obliczający czas do kolizji (TTC - Time To Collision)
///
/// TTC = distance / relative_velocity
///
/// Gdzie:
/// - distance: szacowana odległość do obiektu (na podstawie rozmiaru bbox)
/// - relative_velocity: prędkość względna obiektu względem własnego pojazdu
class TtcEngine {
  /// Minimalna prędkość względna do obliczania TTC (m/s)
  final double minRelativeSpeed;
  
  /// Minimalny TTC do rozważania (sekundy)
  final double minTtc;
  
  /// Maksymalny TTC (sekundy) - powyżej uznajemy za bezpieczne
  final double maxTtc;
  
  /// Przybliżona szerokość obiektu w metrach (domyślnie dla samochodu)
  final double defaultObjectWidthMeters;
  
  /// Ogniskowa kamery (w pikselach) - kalibracja
  final double focalLengthPixels;
  
  /// Prędkość własnego pojazdu (m/s) - z GPS
  double _egoSpeed = 0.0;
  
  /// Czy prędkość własnego pojazdu jest dostępna
  bool _hasEgoSpeed = false;

  TtcEngine({
    this.minRelativeSpeed = 0.5, // 1.8 km/h
    this.minTtc = 0.1,
    this.maxTtc = 10.0,
    this.defaultObjectWidthMeters = 1.8, // średnia szerokość samochodu
    this.focalLengthPixels = 500.0, // typowa wartość dla kamery mobilnej
  });

  /// Aktualizuje prędkość własnego pojazdu z GPS
  void updateEgoSpeed(GpsPosition? gpsPosition) {
    if (gpsPosition != null) {
      _egoSpeed = gpsPosition.speed; // m/s
      _hasEgoSpeed = true;
    } else {
      _hasEgoSpeed = false;
    }
  }

  /// Oblicza TTC dla tracku
  ///
  /// Zwraca null jeśli TTC nie może być obliczony (np. obiekt się oddala)
  double? calculateTtc(TrackedObject track) {
    // Tylko potwierdzone tracki
    if (track.state != TrackState.confirmed) {
      return null;
    }

    // Szacuj odległość na podstawie rozmiaru bounding box
    final estimatedDistance = _estimateDistance(track);
    if (estimatedDistance == null || estimatedDistance <= 0) {
      return null;
    }

    // Oblicz prędkość względną
    final relativeSpeed = _calculateRelativeSpeed(track, estimatedDistance);
    
    // Jeśli prędkość względna jest zbyt mała, obiekt się nie zbliża
    if (relativeSpeed < minRelativeSpeed) {
      return null;
    }

    // TTC = distance / relative_speed
    final ttc = estimatedDistance / relativeSpeed;

    // Ogranicz do rozsądnego zakresu
    if (ttc < minTtc || ttc > maxTtc) {
      return null;
    }

    return ttc;
  }

  /// Szacuje odległość do obiektu na podstawie rozmiaru bounding box
  ///
  /// Używa prostej geometrii:
  /// distance = (focal_length * real_width) / bbox_width_pixels
  double? _estimateDistance(TrackedObject track) {
    final bboxWidthPixels = track.bbox.width;
    
    if (bboxWidthPixels <= 0) {
      return null;
    }

    // Dostosuj szerokość obiektu na podstawie klasy
    final objectWidthMeters = _getObjectWidth(track.label);

    // distance = (focal_length * real_width) / bbox_width
    final distance = (focalLengthPixels * objectWidthMeters) / bboxWidthPixels;

    return distance;
  }

  /// Zwraca przybliżoną szerokość obiektu w metrach na podstawie klasy
  double _getObjectWidth(String label) {
    switch (label.toLowerCase()) {
      case 'car':
        return 1.8;
      case 'truck':
        return 2.5;
      case 'bus':
        return 2.5;
      case 'motorcycle':
        return 0.8;
      case 'bicycle':
        return 0.6;
      case 'person':
        return 0.5;
      case 'rider':
        return 0.6;
      default:
        return defaultObjectWidthMeters;
    }
  }

  /// Oblicza prędkość względną obiektu względem własnego pojazdu
  ///
  /// relative_speed = object_speed - ego_speed
  ///
  /// Gdzie object_speed jest szacowana na podstawie zmiany bbox w czasie
  double _calculateRelativeSpeed(TrackedObject track, double distance) {
    // Prędkość obrazu z trackera (piksele/sekundę)
    final imageSpeed = track.imageVelocity.magnitude; // px/s
    
    if (imageSpeed <= 0) {
      return 0;
    }

    // Konwersja prędkości obrazu na prędkość rzeczywistą (m/s)
    // object_speed = (image_speed * distance) / focal_length
    final objectSpeed = (imageSpeed * distance) / focalLengthPixels;

    // Prędkość względna (obiekt zbliża się jeśli > 0)
    // Jeśli mamy prędkość GPS, odejmij prędkość własnego pojazdu
    double relativeSpeed;
    if (_hasEgoSpeed) {
      // Obiekt zbliża się jeśli jego prędkość > prędkość własna
      relativeSpeed = objectSpeed - _egoSpeed;
    } else {
      // Bez GPS zakładamy że obiekt się zbliża jeśli imageSpeed > 0
      relativeSpeed = objectSpeed;
    }

    return max(0, relativeSpeed);
  }

  /// Oblicza TTC dla wszystkich tracków
  Map<int, double> calculateAllTtcs(List<TrackedObject> tracks) {
    final results = <int, double>{};
    
    for (final track in tracks) {
      final ttc = calculateTtc(track);
      if (ttc != null) {
        results[track.id] = ttc;
      }
    }
    
    return results;
  }

  /// Zwraca klasę ryzyka na podstawie TTC
  RiskLevel getRiskLevelFromTtc(double ttc) {
    if (ttc < 2.0) {
      return RiskLevel.critical;
    } else if (ttc < 4.0) {
      return RiskLevel.high;
    } else if (ttc < 6.0) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }
}
