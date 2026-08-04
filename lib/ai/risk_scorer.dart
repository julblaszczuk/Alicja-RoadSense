import 'dart:math';
import 'models.dart';
import 'tracking/tracked_object.dart';
import 'tracking/track_state.dart';

/// Wynik oceny ryzyka
class RiskAssessment {
  /// Poziom ryzyka
  final RiskLevel level;
  
  /// Score ryzyka (0-100, gdzie 100 = maksymalne ryzyko)
  final double score;
  
  /// Czas do kolizji (sekundy) - null jeśli nie można obliczyć
  final double? ttc;
  
  /// Szacowana odległość (metry) - null jeśli nie można obliczyć
  final double? distance;
  
  /// Prędkość względna (m/s)
  final double relativeSpeed;
  
  /// Opis ryzyka
  final String description;

  const RiskAssessment({
    required this.level,
    required this.score,
    this.ttc,
    this.distance,
    required this.relativeSpeed,
    required this.description,
  });

  /// Czy ryzyko wymaga natychmiastowej uwagi
  bool get requiresImmediateAttention =>
      level == RiskLevel.critical || level == RiskLevel.high;

  @override
  String toString() {
    return 'RiskAssessment(level: $level, score: ${score.toStringAsFixed(1)}, '
        'ttc: ${ttc?.toStringAsFixed(1) ?? "N/A"}s, '
        'distance: ${distance?.toStringAsFixed(1) ?? "N/A"}m)';
  }
}

/// Oceniacz ryzyka kolizji
///
/// Łączy wiele czynników:
/// - TTC (Time To Collision)
/// - Typ obiektu (pieszy > pojazd)
/// - Odległość
/// - Prędkość względna
/// - Confidence tracku
class RiskScorer {
  /// Wagi dla różnych czynników (suma = 1.0)
  final double ttcWeight;
  final double objectTypeWeight;
  final double distanceWeight;
  final double speedWeight;
  final double confidenceWeight;

  /// Progi TTC (sekundy)
  final double criticalTtcThreshold;
  final double highTtcThreshold;
  final double mediumTtcThreshold;

  /// Progi odległości (metry)
  final double criticalDistanceThreshold;
  final double highDistanceThreshold;
  final double mediumDistanceThreshold;

  RiskScorer({
    this.ttcWeight = 0.4,
    this.objectTypeWeight = 0.2,
    this.distanceWeight = 0.2,
    this.speedWeight = 0.1,
    this.confidenceWeight = 0.1,
    this.criticalTtcThreshold = 2.0,
    this.highTtcThreshold = 4.0,
    this.mediumTtcThreshold = 6.0,
    this.criticalDistanceThreshold = 10.0,
    this.highDistanceThreshold = 20.0,
    this.mediumDistanceThreshold = 40.0,
  });

  /// Ocienia ryzyko dla tracku
  RiskAssessment assessRisk(
    TrackedObject track, {
    double? ttc,
    double? distance,
    double relativeSpeed = 0.0,
  }) {
    // Tylko potwierdzone tracki
    if (track.state != TrackState.confirmed) {
      return RiskAssessment(
        level: RiskLevel.low,
        score: 0,
        ttc: ttc,
        distance: distance,
        relativeSpeed: relativeSpeed,
        description: 'Track niepotwierdzony',
      );
    }

    // Oblicz składowe score
    final ttcScore = _calculateTtcScore(ttc);
    final objectTypeScore = _calculateObjectTypeScore(track.label);
    final distanceScore = _calculateDistanceScore(distance);
    final speedScore = _calculateSpeedScore(relativeSpeed);
    final confidenceScore = _calculateConfidenceScore(track.confidence);

    // Ważony score całkowity
    final totalScore = (ttcScore * ttcWeight) +
        (objectTypeScore * objectTypeWeight) +
        (distanceScore * distanceWeight) +
        (speedScore * speedWeight) +
        (confidenceScore * confidenceWeight);

    // Określ poziom ryzyka
    final level = _determineRiskLevel(totalScore, ttc);

    // Generuj opis
    final description = _generateDescription(track, ttc, distance, level);

    return RiskAssessment(
      level: level,
      score: totalScore,
      ttc: ttc,
      distance: distance,
      relativeSpeed: relativeSpeed,
      description: description,
    );
  }

  /// Oblicza score na podstawie TTC (0-100)
  double _calculateTtcScore(double? ttc) {
    if (ttc == null) {
      return 0; // Nie można obliczyć TTC = niskie ryzyko
    }

    if (ttc <= criticalTtcThreshold) {
      return 100; // Krytyczne
    } else if (ttc <= highTtcThreshold) {
      // 100 -> 70 (liniowa interpolacja)
      return 100 - ((ttc - criticalTtcThreshold) / 
          (highTtcThreshold - criticalTtcThreshold)) * 30;
    } else if (ttc <= mediumTtcThreshold) {
      // 70 -> 40
      return 70 - ((ttc - highTtcThreshold) / 
          (mediumTtcThreshold - highTtcThreshold)) * 30;
    } else {
      // 40 -> 0
      return max(0, 40 - ((ttc - mediumTtcThreshold) / 4.0) * 40);
    }
  }

  /// Oblicza score na podstawie typu obiektu (0-100)
  double _calculateObjectTypeScore(String label) {
    switch (label.toLowerCase()) {
      case 'person':
      case 'rider':
        return 100; // Piesi/rowerzyści = najwyższe ryzyko
      case 'bicycle':
        return 90;
      case 'motorcycle':
        return 80;
      case 'car':
        return 60;
      case 'truck':
      case 'bus':
        return 70; // Duże pojazdy = wyższe ryzyko
      default:
        return 50;
    }
  }

  /// Oblicza score na podstawie odległości (0-100)
  double _calculateDistanceScore(double? distance) {
    if (distance == null) {
      return 50; // Nieznana odległość = średnie ryzyko
    }

    if (distance <= criticalDistanceThreshold) {
      return 100;
    } else if (distance <= highDistanceThreshold) {
      return 100 - ((distance - criticalDistanceThreshold) / 
          (highDistanceThreshold - criticalDistanceThreshold)) * 30;
    } else if (distance <= mediumDistanceThreshold) {
      return 70 - ((distance - highDistanceThreshold) / 
          (mediumDistanceThreshold - highDistanceThreshold)) * 30;
    } else {
      return max(0, 40 - ((distance - mediumDistanceThreshold) / 40.0) * 40);
    }
  }

  /// Oblicza score na podstawie prędkości względnej (0-100)
  double _calculateSpeedScore(double relativeSpeed) {
    // Im większa prędkość względna, tym wyższe ryzyko
    if (relativeSpeed <= 0) {
      return 0; // Obiekt się oddala
    } else if (relativeSpeed <= 5) {
      return relativeSpeed * 10; // 0-50
    } else if (relativeSpeed <= 15) {
      return 50 + (relativeSpeed - 5) * 5; // 50-100
    } else {
      return 100;
    }
  }

  /// Oblicza score na podstawie confidence tracku (0-100)
  double _calculateConfidenceScore(double confidence) {
    // Wyższa confidence = wyższe ryzyko (bardziej pewni detekcji)
    return confidence * 100;
  }

  /// Określa poziom ryzyka na podstawie score i TTC
  RiskLevel _determineRiskLevel(double score, double? ttc) {
    // TTC ma priorytet
    if (ttc != null && ttc < criticalTtcThreshold) {
      return RiskLevel.critical;
    }
    if (ttc != null && ttc < highTtcThreshold) {
      return RiskLevel.high;
    }

    // Score
    if (score >= 80) {
      return RiskLevel.critical;
    } else if (score >= 60) {
      return RiskLevel.high;
    } else if (score >= 40) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Generuje opis ryzyka
  String _generateDescription(
    TrackedObject track,
    double? ttc,
    double? distance,
    RiskLevel level,
  ) {
    final label = track.label.toLowerCase();
    
    switch (level) {
      case RiskLevel.critical:
        if (ttc != null) {
          return 'KRYTYCZNE: Kolizja z $label za ${ttc.toStringAsFixed(1)}s!';
        }
        return 'KRYTYCZNE: Bezpośrednie zagrożenie kolizją z $label!';
      
      case RiskLevel.high:
        if (ttc != null) {
          return 'WYSOKIE: $label zbliża się - kolizja za ${ttc.toStringAsFixed(1)}s';
        }
        return 'WYSOKIE: $label w niebezpiecznej odległości';
      
      case RiskLevel.medium:
        return 'ŚREDNIE: $label wykryty w pobliżu';
      
      case RiskLevel.low:
        return 'NISKIE: $label w bezpiecznej odległości';
    }
  }

  /// Ocienia ryzyko dla wszystkich tracków
  Map<int, RiskAssessment> assessAllRisks(
    List<TrackedObject> tracks, {
    Map<int, double?>? ttcMap,
    Map<int, double?>? distanceMap,
  }) {
    final results = <int, RiskAssessment>{};
    
    for (final track in tracks) {
      final ttc = ttcMap?[track.id];
      final distance = distanceMap?[track.id];
      
      results[track.id] = assessRisk(
        track,
        ttc: ttc,
        distance: distance,
      );
    }
    
    return results;
  }

  /// Zwraca track z najwyższym ryzykiem
  RiskAssessment? getHighestRisk(Map<int, RiskAssessment> assessments) {
    if (assessments.isEmpty) {
      return null;
    }
    
    return assessments.values.reduce((a, b) => a.score > b.score ? a : b);
  }
}
