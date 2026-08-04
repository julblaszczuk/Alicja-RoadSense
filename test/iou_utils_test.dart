import 'package:flutter_test/flutter_test.dart';
import 'package:alicja_roadsense/ai/models.dart';
import 'package:alicja_roadsense/ai/tracking/iou_utils.dart';

void main() {
  group('IoU Utils', () {
    group('calculateIoU', () {
      test('pełne nakładanie - IoU = 1.0', () {
        const a = BoundingBox(left: 10, top: 10, width: 100, height: 100);
        const b = BoundingBox(left: 10, top: 10, width: 100, height: 100);

        final iou = calculateIoU(a, b);

        expect(iou, closeTo(1.0, 0.001));
      });

      test('częściowe nakładanie - IoU ~0.33', () {
        const a = BoundingBox(left: 0, top: 0, width: 100, height: 100);
        const b = BoundingBox(left: 50, top: 50, width: 100, height: 100);

        final iou = calculateIoU(a, b);

        // Intersection: 50x50 = 2500
        // Union: 10000 + 10000 - 2500 = 17500
        // IoU: 2500 / 17500 ≈ 0.143
        expect(iou, closeTo(0.143, 0.01));
      });

      test('brak nakładania - IoU = 0.0', () {
        const a = BoundingBox(left: 0, top: 0, width: 100, height: 100);
        const b = BoundingBox(left: 200, top: 200, width: 100, height: 100);

        final iou = calculateIoU(a, b);

        expect(iou, equals(0.0));
      });

      test('stykające się krawędzie - IoU = 0.0', () {
        const a = BoundingBox(left: 0, top: 0, width: 100, height: 100);
        const b = BoundingBox(left: 100, top: 0, width: 100, height: 100);

        final iou = calculateIoU(a, b);

        expect(iou, equals(0.0));
      });

      test('jeden wewnątrz drugiego', () {
        const a = BoundingBox(left: 0, top: 0, width: 200, height: 200);
        const b = BoundingBox(left: 50, top: 50, width: 50, height: 50);

        final iou = calculateIoU(a, b);

        // Intersection: 50x50 = 2500
        // Union: 40000 + 2500 - 2500 = 40000
        // IoU: 2500 / 40000 = 0.0625
        expect(iou, closeTo(0.0625, 0.01));
      });

      test('pusty bounding box', () {
        const a = BoundingBox(left: 0, top: 0, width: 0, height: 0);
        const b = BoundingBox(left: 0, top: 0, width: 100, height: 100);

        final iou = calculateIoU(a, b);

        expect(iou, equals(0.0));
      });
    });

    group('calculateIoUMatrix', () {
      test('macierz 2x2', () {
        final trackBoxes = <BoundingBox>[
          const BoundingBox(left: 0, top: 0, width: 100, height: 100),
          const BoundingBox(left: 200, top: 200, width: 100, height: 100),
        ];
        final detectionBoxes = <BoundingBox>[
          const BoundingBox(left: 10, top: 10, width: 100, height: 100),
          const BoundingBox(left: 210, top: 210, width: 100, height: 100),
        ];

        final matrix = calculateIoUMatrix(trackBoxes, detectionBoxes);

        expect(matrix.length, equals(2));
        expect(matrix[0].length, equals(2));
        expect(matrix[0][0], greaterThan(0.5)); // track 0 -> det 0
        expect(matrix[1][1], greaterThan(0.5)); // track 1 -> det 1
        expect(matrix[0][1], closeTo(0.0, 0.1)); // track 0 -> det 1
        expect(matrix[1][0], closeTo(0.0, 0.1)); // track 1 -> det 0
      });

      test('pusta macierz', () {
        final matrix = calculateIoUMatrix([], []);
        expect(matrix, isEmpty);
      });
    });

    group('bboxToState / stateToBbox', () {
      test('konwersja w obie strony', () {
        const original = BoundingBox(left: 50, top: 50, width: 100, height: 80);

        final state = bboxToState(original);
        final converted = stateToBbox(state);

        expect(converted.left, closeTo(original.left, 1.0));
        expect(converted.top, closeTo(original.top, 1.0));
        expect(converted.width, closeTo(original.width, 1.0));
        expect(converted.height, closeTo(original.height, 1.0));
      });

      test('state ma 4 elementy', () {
        const bbox = BoundingBox(left: 0, top: 0, width: 100, height: 100);
        final state = bboxToState(bbox);

        expect(state.length, equals(4));
        // cx = 50, cy = 50, area = 10000, aspectRatio = 1.0
        expect(state[0], closeTo(50.0, 0.1)); // cx
        expect(state[1], closeTo(50.0, 0.1)); // cy
        expect(state[2], closeTo(10000.0, 1.0)); // area
        expect(state[3], closeTo(1.0, 0.01)); // aspectRatio
      });
    });
  });
}
