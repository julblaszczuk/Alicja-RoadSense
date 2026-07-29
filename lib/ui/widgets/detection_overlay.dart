import 'package:flutter/material.dart';
import '../../ai/models.dart';
import '../../core/theme/design_system.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;

  const DetectionOverlay({
    super.key,
    required this.detections,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionPainter(detections: detections),
      child: const SizedBox.expand(),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;

  _DetectionPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      _drawDetection(canvas, detection);
    }
  }

  void _drawDetection(Canvas canvas, Detection detection) {
    final color = _getRiskColor(detection.riskLevel);

    final boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      detection.bbox.left,
      detection.bbox.top,
      detection.bbox.width,
      detection.bbox.height,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, boxPaint);

    _drawLabel(canvas, detection, color);
    _drawTTC(canvas, detection, color);

    if (detection.riskLevel == RiskLevel.critical) {
      _drawPulseEffect(canvas, rect, color);
    }
  }

  void _drawLabel(Canvas canvas, Detection detection, Color color) {
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
        detection.bbox.left,
        detection.bbox.top - textPainter.height - 8,
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
      Offset(detection.bbox.left + 6, detection.bbox.top - textPainter.height - 4),
    );
  }

  void _drawTTC(Canvas canvas, Detection detection, Color color) {
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
        detection.bbox.left,
        detection.bbox.bottom + 4,
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
      Offset(detection.bbox.left + 6, detection.bbox.bottom + 8),
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
    return oldDelegate.detections != detections;
  }
}
