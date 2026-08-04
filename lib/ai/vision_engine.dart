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
  static const double _confidenceThreshold = 0.35; // Threshold dla stabilnych detekcji

  static const Map<int, String> _labels = {
    0: '???',
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
    12: '???',
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
    26: '???',
    27: 'backpack',
    28: 'umbrella',
    29: '???',
    30: '???',
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
    45: '???',
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
    66: '???',
    67: 'dining table',
    68: '???',
    69: '???',
    70: 'toilet',
    71: '???',
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
    83: '???',
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
      _logger.i('Loading TFLite model...');
      _interpreter = await Interpreter.fromAsset('models/mobilenet_ssd.tflite');
      _isInitialized = true;
      _modelAvailable = true;
      _logger.i('TFLite model loaded successfully');
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensors = _interpreter!.getOutputTensors();
      _logger.i('Input shape: ${inputTensor.shape}');
      _logger.i('Output count: ${outputTensors.length}');
      for (int i = 0; i < outputTensors.length; i++) {
        _logger.i('  Output $i: ${outputTensors[i].shape}');
      }
    } catch (e, st) {
      _logger.w('Failed to load TFLite model: $e\n$st');
      _isInitialized = true;
      _modelAvailable = false;
    }
  }

  Future<List<Detection>> detect(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (!_modelAvailable || _interpreter == null) {
      _logger.w('Model not available, returning empty');
      return [];
    }

    try {
      final input = _preprocess(cameraImage);
      final output = _runInference(input);
      final detections = _postprocess(output, cameraImage.width, cameraImage.height);
      
      return detections;
    } catch (e, st) {
      _logger.e('Detection error: $e\n$st');
      return [];
    }
  }

  Uint8List _preprocess(CameraImage image) {
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

    final buffer = Uint8List(1 * _inputSize * _inputSize * 3);
    int offset = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[offset++] = pixel.r.toInt().clamp(0, 255);
        buffer[offset++] = pixel.g.toInt().clamp(0, 255);
        buffer[offset++] = pixel.b.toInt().clamp(0, 255);
      }
    }
    return buffer;
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

    _logger.i('YUV420: ${width}x${height}, yRowStride=$yRowStride, uvRowStride=$uvRowStride, uvPixelStride=$uvPixelStride');

    for (int y = 0; y < height && y < rgbImage.height; y++) {
      for (int x = 0; x < width && x < rgbImage.width; x++) {
        final yIndex = y * yRowStride + x * yPixelStride;
        final uvY = y ~/ 2;
        final uvX = x ~/ 2;
        final uvIndex = uvY * uvRowStride + uvX * uvPixelStride;

        if (yIndex >= yBytes.length || uvIndex >= uBytes.length || uvIndex >= vBytes.length) {
          continue;
        }

        final yVal = yBytes[yIndex] & 0xFF;
        final uVal = uBytes[uvIndex] & 0xFF;
        final vVal = vBytes[uvIndex] & 0xFF;

        int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).round().clamp(0, 255);
        int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);

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

  Map<String, dynamic> _runInference(Uint8List input) {
    final interpreter = _interpreter!;
    
    interpreter.allocateTensors();
    
    final inputTensor = interpreter.getInputTensor(0);
    _logger.i('Input tensor: shape=${inputTensor.shape}, type=${inputTensor.type}');
    
    final outputTensors = interpreter.getOutputTensors();
    _logger.i('Output tensors: ${outputTensors.length}');
    for (int i = 0; i < outputTensors.length; i++) {
      _logger.i('  Tensor $i: shape=${outputTensors[i].shape}, type=${outputTensors[i].type}');
    }
    
    // Tensor 0: boxes [1, 10, 4]
    final outputBoxes = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
    // Tensor 1: classes [1, 10]
    final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
    // Tensor 2: scores [1, 10]
    final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
    // Tensor 3: numDetections [1]
    final outputNum = List.filled(1, 0.0);

    interpreter.runForMultipleInputs([input], {
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
      3: outputNum,
    });

    return {
      'boxes': outputBoxes,
      'classes': outputClasses,
      'scores': outputScores,
      'num': outputNum,
    };
  }

  List<Detection> _postprocess(
    Map<String, dynamic> output,
    int imageWidth,
    int imageHeight,
  ) {
    final detections = <Detection>[];
    
    try {
      final numList = output['num'] as List?;
      if (numList == null || numList.isEmpty) {
        _logger.w('No numDetections in output');
        return detections;
      }
      
      final numDetections = (numList[0] as num).toInt();
      _logger.i('numDetections: $numDetections');

      final boxes = output['boxes'] as List?;
      final classes = output['classes'] as List?;
      final scores = output['scores'] as List?;

      if (boxes == null || classes == null || scores == null) {
        _logger.w('Null output tensors');
        return detections;
      }

      // Loguj surowe wyniki (pierwsze 5)
      final logCount = numDetections.clamp(0, 5);
      for (int i = 0; i < logCount; i++) {
        try {
          final score = (scores[0][i] as num).toDouble();
          final classId = (classes[0][i] as num).toInt();
          final box = boxes[0][i] as List;
          final top = (box[0] as num).toDouble();
          final left = (box[1] as num).toDouble();
          final bottom = (box[2] as num).toDouble();
          final right = (box[3] as num).toDouble();
          
          _logger.i('[$i] score=${score.toStringAsFixed(3)} classId=$classId box=[${top.toStringAsFixed(3)}, ${left.toStringAsFixed(3)}, ${bottom.toStringAsFixed(3)}, ${right.toStringAsFixed(3)}]');
        } catch (e) {
          _logger.w('Error logging [$i]: $e');
        }
      }

      // Przetwórz tylko prawdziwe detekcje
      for (int i = 0; i < numDetections && i < 10; i++) {
        try {
          final score = (scores[0][i] as num).toDouble();
          if (!score.isFinite || score < _confidenceThreshold) continue;

          final classId = (classes[0][i] as num).toInt();
          final label = _labels[classId] ?? 'unknown';

          final box = boxes[0][i] as List;
          final top = (box[0] as num).toDouble();
          final left = (box[1] as num).toDouble();
          final bottom = (box[2] as num).toDouble();
          final right = (box[3] as num).toDouble();
          
          if (!top.isFinite || !left.isFinite || !bottom.isFinite || !right.isFinite) continue;
          if (right <= left || bottom <= top) continue;
          
          final ymin = top * imageHeight;
          final xmin = left * imageWidth;
          final ymax = bottom * imageHeight;
          final xmax = right * imageWidth;

          _logger.i('OK $label ${score.toStringAsFixed(2)} bbox=[$xmin,$ymin,$xmax,$ymax]');

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
        } catch (e) {
          _logger.w('Error processing [$i]: $e');
        }
      }
      
      _logger.i('Valid detections: ${detections.length}');
    } catch (e, st) {
      _logger.e('Postprocess error: $e\n$st');
    }

    return detections;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _modelAvailable = false;
  }
}
