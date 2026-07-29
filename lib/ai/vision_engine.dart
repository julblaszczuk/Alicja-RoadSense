import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'models.dart';

class VisionEngine {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('models/mobilenet_ssd.tflite');
      _isInitialized = true;
    } catch (e) {
      print('Failed to load model: $e');
      rethrow;
    }
  }

  Future<List<Detection>> detect(CameraImage image) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final preprocessed = _preprocess(image);
    final output = _runInference(preprocessed);
    final detections = _postprocess(output, image.width, image.height);

    return detections;
  }

  List<List<List<List<double>>>> _preprocess(CameraImage image) {
    const inputSize = 300;
    final imageBytes = image.planes[0].bytes.buffer;

    final img.Image rgbImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: imageBytes,
      numChannels: 4,
    );

    final resized = img.copyResize(
      rgbImage,
      width: inputSize,
      height: inputSize,
    );

    final input = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 127.5 - 1.0,
              pixel.g / 127.5 - 1.0,
              pixel.b / 127.5 - 1.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  List<List<dynamic>> _runInference(List<List<List<List<double>>>> input) {
    final output = List.filled(4, List.filled(10, 0.0));
    _interpreter?.run(input, output);
    return output;
  }

  List<Detection> _postprocess(
    List<List<dynamic>> output,
    int imageWidth,
    int imageHeight,
  ) {
    final detections = <Detection>[];
    final numDetections = output[0][0].length as int;

    for (int i = 0; i < numDetections; i++) {
      final confidence = output[0][1][i] as double;

      if (confidence < 0.6) continue;

      final classId = (output[0][2][i] as double).toInt();
      final label = _getLabel(classId);

      final top = (output[0][3][i][0] as double) * imageHeight;
      final left = (output[0][3][i][1] as double) * imageWidth;
      final bottom = (output[0][3][i][2] as double) * imageHeight;
      final right = (output[0][3][i][3] as double) * imageWidth;

      detections.add(
        Detection(
          label: label,
          confidence: confidence,
          bbox: BoundingBox(
            left: left,
            top: top,
            width: right - left,
            height: bottom - top,
          ),
          trackId: i,
        ),
      );
    }

    return detections;
  }

  String _getLabel(int classId) {
    const labels = {
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
    };
    return labels[classId] ?? 'unknown';
  }

  void dispose() {
    _interpreter?.close();
  }
}
