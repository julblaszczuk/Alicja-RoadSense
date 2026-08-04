import 'dart:math';
import '../models.dart';
import 'iou_utils.dart';
import 'trajectory_point.dart';

/// Kalman Filter dla śledzenia bounding box
///
/// Stan: [cx, cy, area, aspectRatio, vx, vy, areaVelocity]
/// - cx, cy: środek bounding box
/// - area: pole bounding box
/// - aspectRatio: stosunek szerokości do wysokości
/// - vx, vy: prędkość środka (piksele/sekundę)
/// - areaVelocity: zmiana pola w czasie
class KalmanBoxTracker {
  /// Stan: [cx, cy, area, aspectRatio, vx, vy, areaVelocity]
  List<double> _state;

  /// Macierz kowariancji stanu
  late List<List<double>> _covariance;

  /// Macierz kowariancji pomiaru
  final List<List<double>> _measurementNoise;

  /// Macierz kowariancji procesu
  final List<List<double>> _processNoise;

  /// Historia trajektorii
  final List<TrajectoryPoint> _trajectory = [];

  /// Maksymalna długość trajektorii
  final int _maxTrajectoryLength;

  /// Ostatni timestamp
  int _lastTimestampUs = 0;

  /// Czy filter został zainicjalizowany
  bool _initialized = false;

  KalmanBoxTracker({
    int maxTrajectoryLength = 20,
  })  : _state = List.filled(7, 0.0),
        _covariance = _identityMatrix(7),
        _measurementNoise = _createMeasurementNoise(),
        _processNoise = _createProcessNoise(),
        _maxTrajectoryLength = maxTrajectoryLength;

  /// Inicjalizuje filter z pierwszą detekcją
  void initialize(BoundingBox bbox, int timestampUs) {
    final state = bboxToState(bbox);
    _state = [
      state[0], // cx
      state[1], // cy
      state[2], // area
      state[3], // aspectRatio
      0.0, // vx
      0.0, // vy
      0.0, // areaVelocity
    ];
    _lastTimestampUs = timestampUs;
    _initialized = true;

    _trajectory.add(TrajectoryPoint(
      centerX: state[0],
      centerY: state[1],
      timestampUs: timestampUs,
    ));
  }

  /// Przewiduje nową pozycję na podstawie modelu ruchu
  void predict(int timestampUs) {
    if (!_initialized) return;

    final deltaTime = (timestampUs - _lastTimestampUs) / 1000000.0; // sekundy
    if (deltaTime <= 0) return;

    // Macierz przejścia stanu (F)
    // Stan: [cx, cy, area, aspectRatio, vx, vy, areaVelocity]
    final F = [
      [1.0, 0.0, 0.0, 0.0, deltaTime, 0.0, 0.0], // cx' = cx + vx*dt
      [0.0, 1.0, 0.0, 0.0, 0.0, deltaTime, 0.0], // cy' = cy + vy*dt
      [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, deltaTime], // area' = area + areaVel*dt
      [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0], // aspectRatio' = aspectRatio
      [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0], // vx' = vx
      [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0], // vy' = vy
      [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0], // areaVel' = areaVel
    ];

    // Przewiduj stan: x' = F * x
    _state = _matrixVectorMultiply(F, _state);

    // Przewiduj kowariancję: P' = F * P * F^T + Q
    _covariance = _addMatrices(
      _multiplyMatrices(_multiplyMatrices(F, _covariance), _transpose(F)),
      _scaleMatrix(_processNoise, deltaTime),
    );

    _lastTimestampUs = timestampUs;
  }

  /// Aktualizuje filter z nową detekcją
  void update(BoundingBox bbox, int timestampUs) {
    if (!_initialized) {
      initialize(bbox, timestampUs);
      return;
    }

    // Przewiduj najpierw
    predict(timestampUs);

    // Pomiar: [cx, cy, area, aspectRatio]
    final measurement = bboxToState(bbox);

    // Macierz pomiaru (H) - mapuje stan na pomiar
    final H = [
      [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], // cx
      [0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0], // cy
      [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0], // area
      [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0], // aspectRatio
    ];

    // Innowacja: y = z - H * x
    final predictedMeasurement = _matrixVectorMultiply(H, _state);
    final innovation = _subtractVectors(measurement, predictedMeasurement);

    // Kowariancja innowacji: S = H * P * H^T + R
    final S = _addMatrices(
      _multiplyMatrices(
        _multiplyMatrices(H, _covariance),
        _transpose(H),
      ),
      _measurementNoise,
    );

    // Wzmocnienie Kalmana: K = P * H^T * S^-1
    final Sinv = _invertMatrix(S);
    final K = _multiplyMatrices(
      _multiplyMatrices(_covariance, _transpose(H)),
      Sinv,
    );

    // Aktualizuj stan: x = x + K * y
    final correction = _matrixVectorMultiply(K, innovation);
    _state = _addVectors(_state, correction);

    // Aktualizuj kowariancję: P = (I - K * H) * P
    final I = _identityMatrix(7);
    final KH = _multiplyMatrices(K, H);
    _covariance = _multiplyMatrices(_subtractMatrices(I, KH), _covariance);

    // Dodaj do trajektorii
    _trajectory.add(TrajectoryPoint(
      centerX: _state[0],
      centerY: _state[1],
      timestampUs: timestampUs,
    ));

    // Ogranicz długość trajektorii
    while (_trajectory.length > _maxTrajectoryLength) {
      _trajectory.removeAt(0);
    }

    _lastTimestampUs = timestampUs;
  }

  /// Zwraca przewidywany bounding box
  BoundingBox get predictedBbox {
    if (!_initialized) {
      return const BoundingBox(left: 0, top: 0, width: 0, height: 0);
    }
    return stateToBbox(_state);
  }

  /// Zwraca aktualny stan
  List<double> get state => List.unmodifiable(_state);

  /// Zwraca prędkość w pikselach/sekundę
  double get velocity {
    if (!_initialized) return 0.0;
    final vx = _state[4];
    final vy = _state[5];
    return sqrt(vx * vx + vy * vy);
  }

  /// Zwraca historię trajektorii
  List<TrajectoryPoint> get trajectory => List.unmodifiable(_trajectory);

  /// Zwraca ostatni timestamp
  int get lastTimestampUs => _lastTimestampUs;

  // === Metody pomocnicze ===

  static List<List<double>> _identityMatrix(int size) {
    final matrix = List.generate(
      size,
      (i) => List.filled(size, 0.0),
    );
    for (int i = 0; i < size; i++) {
      matrix[i][i] = 1.0;
    }
    return matrix;
  }

  static List<List<double>> _createMeasurementNoise() {
    // R - kowariancja szumu pomiaru
    return [
      [1.0, 0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0, 1.0],
    ];
  }

  static List<List<double>> _createProcessNoise() {
    // Q - kowariancja szumu procesu
    return List.generate(
      7,
      (i) => List.filled(7, i == 4 || i == 5 || i == 6 ? 0.01 : 0.001),
    );
  }

  static List<double> _matrixVectorMultiply(
    List<List<double>> matrix,
    List<double> vector,
  ) {
    final result = List.filled(matrix.length, 0.0);
    for (int i = 0; i < matrix.length; i++) {
      for (int j = 0; j < vector.length; j++) {
        result[i] += matrix[i][j] * vector[j];
      }
    }
    return result;
  }

  static List<List<double>> _multiplyMatrices(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final rows = a.length;
    final cols = b[0].length;
    final inner = b.length;
    final result = List.generate(
      rows,
      (_) => List.filled(cols, 0.0),
    );
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        for (int k = 0; k < inner; k++) {
          result[i][j] += a[i][k] * b[k][j];
        }
      }
    }
    return result;
  }

  static List<List<double>> _transpose(List<List<double>> matrix) {
    final rows = matrix.length;
    final cols = matrix[0].length;
    final result = List.generate(
      cols,
      (_) => List.filled(rows, 0.0),
    );
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        result[j][i] = matrix[i][j];
      }
    }
    return result;
  }

  static List<List<double>> _addMatrices(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final rows = a.length;
    final cols = a[0].length;
    return List.generate(
      rows,
      (i) => List.generate(cols, (j) => a[i][j] + b[i][j]),
    );
  }

  static List<List<double>> _subtractMatrices(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final rows = a.length;
    final cols = a[0].length;
    return List.generate(
      rows,
      (i) => List.generate(cols, (j) => a[i][j] - b[i][j]),
    );
  }

  static List<List<double>> _scaleMatrix(
    List<List<double>> matrix,
    double scalar,
  ) {
    return matrix.map((row) => row.map((val) => val * scalar).toList()).toList();
  }

  static List<double> _addVectors(List<double> a, List<double> b) {
    return List.generate(a.length, (i) => a[i] + b[i]);
  }

  static List<double> _subtractVectors(List<double> a, List<double> b) {
    return List.generate(a.length, (i) => a[i] - b[i]);
  }

  static List<List<double>> _invertMatrix(List<List<double>> matrix) {
    // Dla małych macierzy 4x4 używamy prostej metody
    final n = matrix.length;
    final augmented = List.generate(
      n,
      (i) => [...matrix[i], ...List.generate(n, (j) => i == j ? 1.0 : 0.0)],
    );

    // Eliminacja Gaussa
    for (int i = 0; i < n; i++) {
      // Znajdź pivot
      int maxRow = i;
      for (int k = i + 1; k < n; k++) {
        if (augmented[k][i].abs() > augmented[maxRow][i].abs()) {
          maxRow = k;
        }
      }
      final temp = augmented[i];
      augmented[i] = augmented[maxRow];
      augmented[maxRow] = temp;

      // Normalizuj wiersz
      final pivot = augmented[i][i];
      if (pivot.abs() < 1e-10) {
        return _identityMatrix(n); // Macierz osobliwa
      }
      for (int j = 0; j < 2 * n; j++) {
        augmented[i][j] /= pivot;
      }

      // Eliminuj kolumnę
      for (int k = 0; k < n; k++) {
        if (k != i) {
          final factor = augmented[k][i];
          for (int j = 0; j < 2 * n; j++) {
            augmented[k][j] -= factor * augmented[i][j];
          }
        }
      }
    }

    // Wyciągnij odwrotność
    return List.generate(
      n,
      (i) => List.generate(n, (j) => augmented[i][n + j]),
    );
  }
}
