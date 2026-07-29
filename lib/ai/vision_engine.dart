import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

import 'models.dart';

class VisionEngine {
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _modelAvailable = false;

  static const int _inputSize = 300;
  static const double _confidenceThreshold = 0.4; // Obniżony dla testów

  static const Map<int, String> _labels = {
    0: 'background',
    1: 'person',
    2: 'bicycle',
    3: 'car',
    4: 'motorcycle',
    5: 'airplane',
    6: 'bus',
    7: 'train',
    8: 'truck',
    9: 'boat',
    10: 'traffic light',
    11: 'fire hydrant',
    13: 'stop sign',
    14: 'parking meter',
    15: 'bench',
    16: 'bird',
    17: 'cat',
    18: 'dog',
    19: 'horse',
    20: 'sheep',
    21: 'cow',
    22: 'elephant',
    23: 'bear',
    24: 'zebra',
    25: 'giraffe',
    27: 'backpack',
    28: 'umbrella',
    31: 'handbag',
    32: 'tie',
    33: 'suitcase',
    34: 'frisbee',
    35: 'skis',
    36: 'snowboard',
    37: 'sports ball',
    38: 'kite',
    39: 'baseball bat',
    40: 'baseball glove',
    41: 'skateboard',
    42: 'surfboard',
    43: 'tennis racket',
    44: 'bottle',
    46: 'wine glass',
    47: 'cup',
    48: 'fork',
    49: 'knife',
    50: 'spoon',
    51: 'bowl',
    52: 'banana',
    53: 'apple',
    54: 'sandwich',
    55: 'orange',
    56: 'broccoli',
    57: 'carrot',
    58: 'hot dog',
    59: 'pizza',
    60: 'donut',
    61: 'cake',
    62: 'chair',
    63: 'couch',
    64: 'potted plant',
    65: 'bed',
    67: 'dining table',
    70: 'toilet',
    72: 'tv',
    73: 'laptop',
    74: 'mouse',
    75: 'remote',
    76: 'keyboard',
    77: 'cell phone',
    78: 'microwave',
    79: 'oven',
    80: 'toaster',
    81: 'sink',
    82: 'refrigerator',
    84: 'book',
    85: 'clock',
    86: 'vase',
    87: 'scissors',
    88: 'teddy bear',
    89: 'hair drier',
    90: 'toothbrush',
  };

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('models/mobilenet_ssd.tflite');
      _isInitialized = true;
      _modelAvailable = true;
      _logger.i('TFLite model loaded successfully');
    } catch (e) {
      _logger.w('Failed to load TFLite model: $e');
      _isInitialized = true;
      _modelAvailable = false;
    }
  }

  Future<List<Detection>> detect(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (!_modelAvailable || _interpreter == null) {
      return _generateDemoDetections(cameraImage.width, cameraImage.height);
    }

    try {
      _logger.i('Camera format: ${cameraImage.format.group}');
      _logger.i('Camera size: ${cameraImage.width}x${cameraImage.height}');
      _logger.i('Planes count: ${cameraImage.planes.length}');
      
      final input = _preprocess(cameraImage);
      final output = _runInference(input);
      final detections = _postprocess(output, cameraImage.width, cameraImage.height);
      
      _logger.i('Total detections: ${detections.length}');
      return detections;
    } catch (e) {
      _logger.e('Detection error: $e');
      return _generateDemoDetections(cameraImage.width, cameraImage.height);
    }
  }

  List<List<List<List<int>>>> _preprocess(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final rgbImage = img.Image(width: width, height: height);

    if (image.format.group == ImageFormatGroup.yuv420) {
      _convertYuv420ToImage(image, rgbImage);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      _convertBgra888ToImage(image, rgbImage);
    } else {
      _convertDefaultToImage(image, rgbImage);
    }

    final resized = img.copyResize(
      rgbImage,
      width: _inputSize,
      height: _inputSize,
    );

    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toInt().clamp(0, 255),
              pixel.g.toInt().clamp(0, 255),
              pixel.b.toInt().clamp(0, 255),
            ];
          },
        ),
      ),
    );
  }

  void _convertYuv420ToImage(CameraImage image, img.Image rgbImage) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final width = image.width;
    final height = image.height;

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x * yPixelStride;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        if (yIndex >= yBytes.length || uvIndex >= uBytes.length || uvIndex >= vBytes.length) {
          continue;
        }

        final yVal = yBytes[yIndex] & 0xFF;
        final uVal = uBytes[uvIndex] & 0xFF;
        final vVal = vBytes[uvIndex] & 0xFF;

        int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255);
        int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  void _convertBgra888ToImage(CameraImage image, img.Image rgbImage) {
    final bytes = image.planes[0].bytes;
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        if (offset + 2 < bytes.length) {
          rgbImage.setPixelRgb(x, y, bytes[offset + 2], bytes[offset + 1], bytes[offset]);
        }
      }
    }
  }

  void _convertDefaultToImage(CameraImage image, img.Image rgbImage) {
    final bytes = image.planes[0].bytes;
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        if (offset + 2 < bytes.length) {
          rgbImage.setPixelRgb(x, y, bytes[offset], bytes[offset + 1], bytes[offset + 2]);
        }
      }
    }
  }

  Map<String, List<dynamic>> _runInference(List<List<List<List<int>>>> input) {
    final interpreter = _interpreter!;
    
    // Sprawdź kształty output tensorów
    final outputTensors = interpreter.getOutputTensors();
    
    _logger.i('Output tensors: ${outputTensors.length}');
    for (int i = 0; i < outputTensors.length; i++) {
      _logger.i('  Tensor $i: ${outputTensors[i].shape}');
    }
    
    // MobileNet SSD ma 4 outputy:
    // 0: DetectionBoxes [1][num_detections][4]
    // 1: DetectionClasses [1][num_detections]
    // 2: DetectionScores [1][num_detections]
    // 3: NumDetections [1]
    
    final maxDetections = 20; // Zgodnie z kształtem tensora [1, 20, 4]
    
    final outputLocations = List.generate(1, (_) => List.generate(maxDetections, (_) => List.filled(4, 0.0)));
    final outputClasses = List.generate(1, (_) => List.filled(maxDetections, 0.0));
    final outputScores = List.generate(1, (_) => List.filled(maxDetections, 0.0));
    final numDetections = List.filled(1, 0.0);

    interpreter.run(input, {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    });

    return {
      'boxes': outputLocations,
      'classes': outputClasses,
      'scores': outputScores,
      'num': numDetections,
    };
  }

  List<Detection> _postprocess(
    Map<String, List<dynamic>> output,
    int imageWidth,
    int imageHeight,
  ) {
    final detections = <Detection>[];
    
    try {
      final numDetectionsList = output['num'] as List;
      final numDetections = (numDetectionsList[0] as num).toInt();
      
      _logger.i('Detekcje: $numDetections');

      final boxes = output['boxes'] as List;
      final classes = output['classes'] as List;
      final scores = output['scores'] as List;

      // Loguj wszystkie detekcje (nawet te poniżej threshold)
      for (int i = 0; i < numDetections; i++) {
        final score = (scores[0][i] as num).toDouble();
        final classId = (classes[0][i] as num).toInt();
        final label = _labels[classId] ?? 'unknown';
        _logger.i('  [$i] $label: ${(score * 100).toStringAsFixed(1)}%');
      }

      for (int i = 0; i < numDetections; i++) {
        final score = (scores[0][i] as num).toDouble();
        if (score < _confidenceThreshold) continue;

        final classId = (classes[0][i] as num).toInt();
        final label = _labels[classId] ?? 'unknown';

        final box = boxes[0][i] as List;
        final ymin = (box[0] as num).toDouble() * imageHeight;
        final xmin = (box[1] as num).toDouble() * imageWidth;
        final ymax = (box[2] as num).toDouble() * imageHeight;
        final xmax = (box[3] as num).toDouble() * imageWidth;

        _logger.i('Wykryto: $label (${(score * 100).toStringAsFixed(1)}%)');

        detections.add(
          Detection(
            label: label,
            confidence: score,
            bbox: BoundingBox(
              left: xmin,
              top: ymin,
              width: xmax - xmin,
              height: ymax - ymin,
            ),
            trackId: i,
          ),
        );
      }
    } catch (e) {
      _logger.e('Postprocess error: $e');
    }

    return detections;
  }

  List<Detection> _generateDemoDetections(int width, int height) {
    return [
      Detection(
        label: 'car',
        confidence: 0.92,
        bbox: BoundingBox(
          left: width * 0.1,
          top: height * 0.3,
          width: width * 0.3,
          height: height * 0.4,
        ),
        ttc: 5.2,
        trackId: 1,
      ),
      Detection(
        label: 'person',
        confidence: 0.87,
        bbox: BoundingBox(
          left: width * 0.6,
          top: height * 0.2,
          width: width * 0.1,
          height: height * 0.5,
        ),
        ttc: 8.1,
        trackId: 2,
      ),
    ];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _modelAvailable = false;
  }
}
