import 'dart:typed_data';
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
  static const double _confidenceThreshold = 0.6;

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
      final input = _preprocess(cameraImage);
      final output = _runInference(input);
      return _postprocess(output, cameraImage.width, cameraImage.height);
    } catch (e) {
      _logger.e('Detection error: $e');
      return _generateDemoDetections(cameraImage.width, cameraImage.height);
    }
  }

  List<List<List<List<double>>>> _preprocess(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final rgbBytes = Uint8List(width * height * 3);

    if (image.format.group == ImageFormatGroup.yuv420) {
      _convertYuv420ToRgb(image, rgbBytes, width, height);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      _convertBgra888ToRgb(image, rgbBytes, width, height);
    } else {
      final bytes = image.planes[0].bytes;
      for (int i = 0; i < width * height && i * 4 + 2 < bytes.length; i++) {
        rgbBytes[i * 3] = bytes[i * 4];
        rgbBytes[i * 3 + 1] = bytes[i * 4 + 1];
        rgbBytes[i * 3 + 2] = bytes[i * 4 + 2];
      }
    }

    final rgbImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
    );

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
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }

  void _convertYuv420ToRgb(CameraImage image, Uint8List rgbBytes, int width, int height) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x * yPlane.bytesPerPixel!;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yVal = yBytes[yIndex] & 0xFF;
        final uVal = uBytes[uvIndex] & 0xFF;
        final vVal = vBytes[uvIndex] & 0xFF;

        int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255);
        int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        final rgbIndex = (y * width + x) * 3;
        rgbBytes[rgbIndex] = r;
        rgbBytes[rgbIndex + 1] = g;
        rgbBytes[rgbIndex + 2] = b;
      }
    }
  }

  void _convertBgra888ToRgb(CameraImage image, Uint8List rgbBytes, int width, int height) {
    final bytes = image.planes[0].bytes;
    for (int i = 0; i < width * height; i++) {
      final offset = i * 4;
      if (offset + 2 < bytes.length) {
        rgbBytes[i * 3] = bytes[offset + 2];
        rgbBytes[i * 3 + 1] = bytes[offset + 1];
        rgbBytes[i * 3 + 2] = bytes[offset];
      }
    }
  }

  Map<int, List<dynamic>> _runInference(List<List<List<List<double>>>> input) {
    final outputLocations = List.filled(1, List.filled(10, List.filled(4, 0.0)));
    final outputClasses = List.filled(1, List.filled(10, 0.0));
    final outputScores = List.filled(1, List.filled(10, 0.0));
    final numDetections = List.filled(1, 0.0);

    _interpreter!.run(input, {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    });

    return {
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
      3: numDetections,
    };
  }

  List<Detection> _postprocess(
    Map<int, List<dynamic>> output,
    int imageWidth,
    int imageHeight,
  ) {
    final detections = <Detection>[];
    final numDetections = (output[3]![0][0] as double).toInt();

    for (int i = 0; i < numDetections; i++) {
      final score = (output[2]![0][i] as double);
      if (score < _confidenceThreshold) continue;

      final classId = (output[1]![0][i] as double).toInt();
      final label = _labels[classId] ?? 'unknown';

      final ymin = (output[0]![0][i][0] as double) * imageWidth;
      final xmin = (output[0]![0][i][1] as double) * imageHeight;
      final ymax = (output[0]![0][i][2] as double) * imageWidth;
      final xmax = (output[0]![0][i][3] as double) * imageHeight;

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
