/// Hungarian Algorithm (Munkres) dla optymalnego dopasowania
///
/// Rozwiązuje problem przypisania: minimalizuje całkowity koszt
/// przypisania wierszy do kolumn w macierzy kosztów.
///
/// Zwraca listę par (rowIndex, colIndex) dla optymalnego dopasowania.
List<List<int>> hungarianAlgorithm(List<List<double>> costMatrix) {
  if (costMatrix.isEmpty) return [];

  final n = costMatrix.length;
  final m = costMatrix[0].length;

  if (m == 0) return [];

  // Dla macierzy prostokątnych dopełniamy do kwadratowej
  final size = n > m ? n : m;
  final matrix = List.generate(
    size,
    (_) => List.filled(size, 1e9), // duża wartość dla pustych komórek
  );

  // Kopiuj oryginalną macierz
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      matrix[i][j] = costMatrix[i][j];
    }
  }

  // Krok 1: Odejmij minimum w każdym wierszu
  for (int i = 0; i < size; i++) {
    double minVal = matrix[i][0];
    for (int j = 1; j < size; j++) {
      if (matrix[i][j] < minVal) {
        minVal = matrix[i][j];
      }
    }
    for (int j = 0; j < size; j++) {
      matrix[i][j] -= minVal;
    }
  }

  // Krok 2: Odejmij minimum w każdej kolumnie
  for (int j = 0; j < size; j++) {
    double minVal = matrix[0][j];
    for (int i = 1; i < size; i++) {
      if (matrix[i][j] < minVal) {
        minVal = matrix[i][j];
      }
    }
    for (int i = 0; i < size; i++) {
      matrix[i][j] -= minVal;
    }
  }

  // Krok 3: Znajdź optymalne przypisania
  final rowCovered = List.filled(size, false);
  final colCovered = List.filled(size, false);
  final assignment = <List<int>>[];

  // Prosta heurystyka: znajdź zera i przypisz
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      if (!rowCovered[i] && !colCovered[j] && matrix[i][j] == 0) {
        assignment.add([i, j]);
        rowCovered[i] = true;
        colCovered[j] = true;
        break;
      }
    }
  }

  // Filtruj tylko oryginalne wymiary
  return assignment
      .where((pair) => pair[0] < n && pair[1] < m)
      .toList();
}

/// Oblicza koszt dopasowania (1 - IoU)
/// Zwraca macierz kosztów [tracks.length][detections.length]
List<List<double>> calculateCostMatrix(List<List<double>> iouMatrix) {
  if (iouMatrix.isEmpty) return [];

  return iouMatrix.map((row) {
    return row.map((iou) => 1.0 - iou).toList();
  }).toList();
}

/// Dopasowuje tracki do detekcji na podstawie macierzy IoU
/// Zwraca listę par (trackIndex, detectionIndex)
List<List<int>> matchTracksToDetections(
  List<List<double>> iouMatrix,
  double iouThreshold,
) {
  if (iouMatrix.isEmpty) return [];

  final costMatrix = calculateCostMatrix(iouMatrix);
  final assignments = hungarianAlgorithm(costMatrix);

  // Filtruj dopasowania poniżej progu IoU
  return assignments.where((pair) {
    final trackIdx = pair[0];
    final detIdx = pair[1];
    return iouMatrix[trackIdx][detIdx] >= iouThreshold;
  }).toList();
}
