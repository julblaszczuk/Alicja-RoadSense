import 'dart:math' as math;

/// Punkt kalibracyjny w obrazie kamery
class CalibrationPoint {
  final double x;
  final double y;
  final String label;

  CalibrationPoint({
    required this.x,
    required this.y,
    required this.label,
  });
}

/// Kalibracja drogi - transformacja perspektywy
class RoadCalibration {
  /// 4 punkty kalibracyjne (lewy-dolny, prawy-dolny, prawy-górny, lewy-górny)
  List<CalibrationPoint> _points = [];
  
  /// Region of Interest (maska samochodu)
  List<CalibrationPoint> _roiPoints = [];
  
  bool _isCalibrated = false;

  bool get isCalibrated => _isCalibrated;
  List<CalibrationPoint> get points => _points;
  List<CalibrationPoint> get roiPoints => _roiPoints;

  /// Ustaw punkty kalibracyjne drogi
  void setCalibrationPoints(List<CalibrationPoint> points) {
    if (points.length != 4) {
      throw ArgumentError('Wymagane dokładnie 4 punkty kalibracyjne');
    }
    _points = points;
    _isCalibrated = true;
  }

  /// Ustaw ROI (maska samochodu)
  void setROIPoints(List<CalibrationPoint> points) {
    if (points.length < 3) {
      throw ArgumentError('ROI wymaga minimum 3 punktów');
    }
    _roiPoints = points;
  }

  /// Sprawdź czy punkt jest w ROI
  bool isInROI(double x, double y) {
    if (_roiPoints.isEmpty) return true; // Brak ROI = wszystko jest OK
    
    return _isPointInPolygon(x, y, _roiPoints);
  }

  /// Oblicz odległość od kamery (w metrach) na podstawie pozycji w obrazie
  double? calculateDistance(double imageX, double imageY, double imageHeight) {
    if (!_isCalibrated || _points.isEmpty) return null;

    // Prosta estymacja: im niżej w obrazie, tym bliżej
    // Punkt vanishing line (górna linia drogi)
    final vanishingY = _points[2].y; // Górny prawy punkt
    final horizonY = _points[0].y; // Dolny lewy punkt (najbliżej)
    
    if (imageY < vanishingY || imageY > horizonY) return null;
    
    // Normalizacja pozycji Y (0 = horyzont, 1 = najbliżej)
    final normalizedY = (imageY - vanishingY) / (horizonY - vanishingY);
    
    // Szacunkowa odległość (metry) - wymaga kalibracji
    const maxDistance = 50.0; // 50m na horyzoncie
    const minDistance = 2.0;  // 2m najbliżej
    
    return maxDistance - (normalizedY * (maxDistance - minDistance));
  }

  /// Transformuj punkt z obrazu kamery na widok z góry (bird's eye view)
  ({double x, double y})? transformToBirdsEye(double x, double y) {
    if (!_isCalibrated || _points.length != 4) return null;

    // Prosta interpolacja liniowa (w produkcji użyj homografii)
    final leftBottom = _points[0];
    final rightBottom = _points[1];
    final rightTop = _points[2];
    final leftTop = _points[3];

    // Interpolacja X (lewo-prawo)
    final tY = (y - leftTop.y) / (leftBottom.y - leftTop.y);
    final leftX = leftTop.x + (leftBottom.x - leftTop.x) * tY;
    final rightX = rightTop.x + (rightBottom.x - rightTop.x) * tY;
    
    // Interpolacja pozycji X wzdłuż linii
    final tX = (x - leftX) / (rightX - leftX);
    
    // Mapowanie na widok z góry (0-1)
    final birdX = tX.clamp(0.0, 1.0);
    final birdY = tY.clamp(0.0, 1.0);

    return (x: birdX, y: birdY);
  }

  /// Reset kalibracji
  void reset() {
    _points = [];
    _roiPoints = [];
    _isCalibrated = false;
  }

  /// Sprawdź czy punkt jest w wielokącie (ray casting algorithm)
  bool _isPointInPolygon(double x, double y, List<CalibrationPoint> polygon) {
    if (polygon.length < 3) return false;

    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];

      if ((p1.y <= y && p2.y > y) || (p2.y <= y && p1.y > y)) {
        final vt = (y - p1.y) / (p2.y - p1.y);
        if (x < p1.x + vt * (p2.x - p1.x)) {
          crossings++;
        }
      }
    }

    return crossings % 2 == 1;
  }
}
