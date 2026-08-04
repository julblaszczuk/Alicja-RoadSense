import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'models.dart';

class VisionEngine {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _modelAvailable = false;

  static const int _inputSize = 640;
  double _confidenceThreshold = 0.35;
  static const double _iouThreshold = 0.45;

  void setConfidenceThreshold(double value) {
    _confidenceThreshold = value;
  }

  static const Map<int, String> _labels = {
    0: 'person',
    1: 'rider',
    2: 'car',
    3: 'truck',
    4: 'bus',
    5: 'train',
    6: 'motorcycle',
    7: 'bicycle',
    8: 'traffic light',
    9: 'traffic sign',
  };

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('models/yolov8n_bdd100k_int8.tflite');
      _isInitialized = true;
      _modelAvailable = true;
    } catch (e) {
      _isInitialized = true;
      _modelAvailable = false;
    }
  }

  Future<List<Detection>> detect(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (!_modelAvailable || _interpreter == null) {
      return [];
    }

    try {
      final input = _preprocess(cameraImage);
      final output = _runInference(input);
      final detections = _postprocess(output, cameraImage.width, cameraImage.height);
      
      return detections;
    } catch (e) {
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

  List<List<double>> _runInference(Uint8List input) {
    final interpreter = _interpreter!;
    
    interpreter.allocateTensors();
    
    final outputTensors = interpreter.getOutputTensors();
    final outputShape = outputTensors[0].shape;
    final numAnchors = outputShape[2];
    
    final output = List.generate(1, (_) => List.generate(outputShape[1], (_) => List.filled(numAnchors, 0.0)));

    interpreter.runForMultipleInputs([input], {0: output});
    
    return output[0];
  }

  List<Detection> _postprocess(
    List<List<double>> output,
    int imageWidth,
    int imageHeight,
  ) {
    final numClasses = output.length - 4;
    final numAnchors = output[0].length;

    final allDetections = <_RawDetection>[];
    
    for (int i = 0; i < numAnchors; i++) {
      double maxConfidence = 0;
      int maxClassId = 0;
      
      for (int c = 0; c < numClasses; c++) {
        final conf = output[4 + c][i];
        if (conf > maxConfidence) {
          maxConfidence = conf;
          maxClassId = c;
        }
      }
      
      if (maxConfidence < _confidenceThreshold) continue;
      
      final cx = output[0][i];
      final cy = output[1][i];
      final w = output[2][i];
      final h = output[3][i];
      
      final x1 = (cx - w / 2).clamp(0.0, 1.0);
      final y1 = (cy - h / 2).clamp(0.0, 1.0);
      final x2 = (cx + w / 2).clamp(0.0, 1.0);
      final y2 = (cy + h / 2).clamp(0.0, 1.0);
      
      if (x2 <= x1 || y2 <= y1) continue;
      
      allDetections.add(_RawDetection(
        classId: maxClassId,
        confidence: maxConfidence,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
      ));
    }

    final nmsDetections = _applyNMS(allDetections);

    final detections = <Detection>[];
    
    for (int i = 0; i < nmsDetections.length && i < 20; i++) {
      final raw = nmsDetections[i];
      final label = _labels[raw.classId] ?? 'unknown';
      
      final xmin = raw.x1 * imageWidth;
      final ymin = raw.y1 * imageHeight;
      final xmax = raw.x2 * imageWidth;
      final ymax = raw.y2 * imageHeight;

      detections.add(
        Detection(
          label: label,
          confidence: raw.confidence,
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

  List<_RawDetection> _applyNMS(List<_RawDetection> detections) {
    // Sortuj po confidence (malejąco)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final selected = <_RawDetection>[];
    final suppressed = <int>{};
    
    for (int i = 0; i < detections.length; i++) {
      if (suppressed.contains(i)) continue;
      
      selected.add(detections[i]);
      
      // Suppress overlapping detections
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed.contains(j)) continue;
        
        final iou = _calculateIoU(detections[i], detections[j]);
        if (iou > _iouThreshold) {
          suppressed.add(j);
        }
      }
    }
    
    return selected;
  }

  double _calculateIoU(_RawDetection a, _RawDetection b) {
    final x1 = max(a.x1, b.x1);
    final y1 = max(a.y1, b.y1);
    final x2 = min(a.x2, b.x2);
    final y2 = min(a.y2, b.y2);
    
    final intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final union = areaA + areaB - intersection;
    
    return union > 0 ? intersection / union : 0;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _modelAvailable = false;
  }
}

class _RawDetection {
  final int classId;
  final double confidence;
  final double x1, y1, x2, y2;
  
  _RawDetection({
    required this.classId,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
}
