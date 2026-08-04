import '../models.dart';

/// Oblicza Intersection over Union (IoU) między dwoma bounding box
double calculateIoU(BoundingBox a, BoundingBox b) {
  // Oblicz współrzędne intersection
  final x1 = _max(a.left, b.left);
  final y1 = _max(a.top, b.top);
  final x2 = _min(a.left + a.width, b.left + b.width);
  final y2 = _min(a.top + a.height, b.top + b.height);

  // Sprawdź czy jest intersection
  if (x2 <= x1 || y2 <= y1) {
    return 0.0;
  }

  // Pole intersection
  final intersection = (x2 - x1) * (y2 - y1);

  // Pole union
  final areaA = a.width * a.height;
  final areaB = b.width * b.height;
  final union = areaA + areaB - intersection;

  if (union <= 0) {
    return 0.0;
  }

  return intersection / union;
}

/// Oblicza macierz IoU między listami detekcji i tracków
/// Zwraca macierz [tracks.length][detections.length]
List<List<double>> calculateIoUMatrix(
  List<BoundingBox> trackBoxes,
  List<BoundingBox> detectionBoxes,
) {
  final rows = trackBoxes.length;
  final cols = detectionBoxes.length;

  if (rows == 0 || cols == 0) {
    return [];
  }

  final matrix = List.generate(
    rows,
    (_) => List.filled(cols, 0.0),
  );

  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      matrix[i][j] = calculateIoU(trackBoxes[i], detectionBoxes[j]);
    }
  }

  return matrix;
}

/// Konwertuje bounding box na [cx, cy, area, aspectRatio]
List<double> bboxToState(BoundingBox bbox) {
  final cx = bbox.left + bbox.width / 2;
  final cy = bbox.top + bbox.height / 2;
  final area = bbox.width * bbox.height;
  final aspectRatio = bbox.width / bbox.height;
  return [cx, cy, area, aspectRatio];
}

/// Konwertuje stan [cx, cy, area, aspectRatio] na bounding box
BoundingBox stateToBbox(List<double> state) {
  final cx = state[0];
  final cy = state[1];
  final area = state[2];
  final aspectRatio = state[3];

  // Oblicz width i height z area i aspect ratio
  // area = width * height
  // aspectRatio = width / height
  // width = sqrt(area * aspectRatio)
  // height = sqrt(area / aspectRatio)

  final width = _sqrt(area * aspectRatio);
  final height = _sqrt(area / aspectRatio);

  return BoundingBox(
    left: cx - width / 2,
    top: cy - height / 2,
    width: width,
    height: height,
  );
}

double _max(double a, double b) => a > b ? a : b;
double _min(double a, double b) => a < b ? a : b;
double _sqrt(double x) {
  if (x <= 0) return 0;
  // Newton's method for square root
  double guess = x / 2;
  for (int i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
