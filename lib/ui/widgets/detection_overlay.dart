import 'package:flutter/material.dart';
import '../../ai/models.dart';
import '../../core/theme/design_system.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final Detection? selectedDetection;
  final Size imageSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    this.selectedDetection,
    this.imageSize = const Size(300, 300),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _DetectionPainter(
            detections: detections,
            selectedDetection: selectedDetection,
            imageSize: imageSize,
            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Detection? selectedDetection;
  final Size imageSize;
  final Size screenSize;

  _DetectionPainter({
    required this.detections,
    this.selectedDetection,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Oblicz skalę - obraz jest obrócony o 90 stopni
    // Więc szerokość obrazu = wysokość ekranu i odwrotnie
    final scaleX = screenSize.height / imageSize.width;
    final scaleY = screenSize.width / imageSize.height;

    for (final detection in detections) {
      final isSelected = selectedDetection != null && 
                         selectedDetection!.trackId == detection.trackId;
      _drawDetection(canvas, detection, isSelected, scaleX, scaleY);
    }
  }

  void _drawDetection(Canvas canvas, Detection detection, bool isSelected, double scaleX, double scaleY) {
    final color = _getRiskColor(detection.riskLevel);

    final boxPaint = Paint()
      ..color = isSelected ? Colors.white : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 5.0 : 3.0
      ..strokeCap = StrokeCap.round;

    // Przeskaluj i obróć współrzędne (obraz jest obrócony o 90 stopni)
    final left = detection.bbox.top * scaleX;
    final top = screenSize.height - (detection.bbox.left + detection.bbox.width) * scaleY;
    final width = detection.bbox.height * scaleX;
    final height = detection.bbox.width * scaleY;

    final rect = Rect.fromLTWH(left, top, width, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, boxPaint);

    _drawLabel(canvas, detection, color, left, top);
    _drawTTC(canvas, detection, color, left, top, height);

    if (detection.riskLevel == RiskLevel.critical) {
      _drawPulseEffect(canvas, rect, color);
    }
  }

  void _drawLabel(Canvas canvas, Detection detection, Color color, double left, double top) {
    final label = '${detection.label} ${(detection.confidence * 100).toInt()}%';

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: color.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left,
        top - textPainter.height - 8,
        textPainter.width + 12,
        textPainter.height + 8,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      labelRect,
      Paint()..color = color.withOpacity(0.9),
    );

    textPainter.paint(
      canvas,
      Offset(left + 6, top - textPainter.height - 4),
    );
  }

  void _drawTTC(Canvas canvas, Detection detection, Color color, double left, double top, double height) {
    if (detection.ttc == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TTC: ${detection.ttc!.toStringAsFixed(1)}s',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: color.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final ttcRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left,
        top + height + 4,
        textPainter.width + 12,
        textPainter.height + 8,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      ttcRect,
      Paint()..color = color.withOpacity(0.8),
    );

    textPainter.paint(
      canvas,
      Offset(left + 6, top + height + 8),
    );
  }

  void _drawPulseEffect(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final expandedRect = rect.inflate(8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(expandedRect, const Radius.circular(12)),
      paint,
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return AppColors.riskCritical;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.low:
        return AppColors.riskLow;
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.detections != detections ||
           oldDelegate.selectedDetection != selectedDetection ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.screenSize != screenSize;
  }
}
