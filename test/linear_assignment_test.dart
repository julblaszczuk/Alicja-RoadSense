import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/tracking/linear_assignment.dart';

void main() {
  group('Linear Assignment', () {
    group('hungarianAlgorithm', () {
      test('prosta macierz 2x2', () {
        final costMatrix = [
          [0.1, 0.9],
          [0.8, 0.2],
        ];

        final assignments = hungarianAlgorithm(costMatrix);

        expect(assignments.length, equals(2));
        // Oczekiwane: (0,0) i (1,1) - minimalny koszt
        expect(assignments.any((p) => p[0] == 0 && p[1] == 0), isTrue);
        expect(assignments.any((p) => p[0] == 1 && p[1] == 1), isTrue);
      });

      test('macierz 3x3', () {
        final costMatrix = [
          [0.1, 0.5, 0.9],
          [0.8, 0.2, 0.6],
          [0.7, 0.8, 0.3],
        ];

        final assignments = hungarianAlgorithm(costMatrix);

        expect(assignments.length, equals(3));
      });

      test('pusta macierz', () {
        final assignments = hungarianAlgorithm([]);
        expect(assignments, isEmpty);
      });

      test('macierz z pustymi kolumnami', () {
        final costMatrix = <List<double>>[
          [],
        ];

        final assignments = hungarianAlgorithm(costMatrix);
        expect(assignments, isEmpty);
      });
    });

    group('matchTracksToDetections', () {
      test('dopasowanie z wysokim IoU', () {
        final iouMatrix = [
          [0.9, 0.1, 0.0],
          [0.0, 0.8, 0.1],
          [0.1, 0.0, 0.85],
        ];

        final matches = matchTracksToDetections(iouMatrix, 0.3);

        expect(matches.length, equals(3));
        expect(matches.any((p) => p[0] == 0 && p[1] == 0), isTrue);
        expect(matches.any((p) => p[0] == 1 && p[1] == 1), isTrue);
        expect(matches.any((p) => p[0] == 2 && p[1] == 2), isTrue);
      });

      test('odrzucenie poniżej progu IoU', () {
        final iouMatrix = [
          [0.5, 0.1],
          [0.1, 0.2],
        ];

        final matches = matchTracksToDetections(iouMatrix, 0.3);

        // Tylko (0,0) powinno być dopasowane (IoU = 0.5 >= 0.3)
        expect(matches.length, equals(1));
        expect(matches[0][0], equals(0));
        expect(matches[0][1], equals(0));
      });

      test('brak dopasowań przy niskim IoU', () {
        final iouMatrix = [
          [0.1, 0.2],
          [0.2, 0.1],
        ];

        final matches = matchTracksToDetections(iouMatrix, 0.3);

        expect(matches, isEmpty);
      });

      test('pusta macierz IoU', () {
        final matches = matchTracksToDetections([], 0.3);
        expect(matches, isEmpty);
      });
    });

    group('calculateCostMatrix', () {
      test('konwersja IoU na koszt', () {
        final iouMatrix = [
          [0.8, 0.2],
          [0.3, 0.9],
        ];

        final costMatrix = calculateCostMatrix(iouMatrix);

        expect(costMatrix[0][0], closeTo(0.2, 0.01)); // 1 - 0.8
        expect(costMatrix[0][1], closeTo(0.8, 0.01)); // 1 - 0.2
        expect(costMatrix[1][0], closeTo(0.7, 0.01)); // 1 - 0.3
        expect(costMatrix[1][1], closeTo(0.1, 0.01)); // 1 - 0.9
      });
    });
  });
}
