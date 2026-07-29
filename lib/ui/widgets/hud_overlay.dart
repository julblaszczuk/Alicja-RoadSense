import 'package:flutter/material.dart';
import '../../ai/models.dart';

class HudOverlay extends StatelessWidget {
  final List<Detection> detections;

  const HudOverlay({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HudPainter(detections: detections),
      child: const SizedBox.expand(),
    );
  }
}

class _HudPainter extends CustomPainter {
  final List<Detection> detections;

  _HudPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      _drawDetection(canvas, size, detection);
    }
  }

  void _drawDetection(Canvas canvas, Size size, Detection detection) {
    final color = _getRiskColor(detection.riskLevel);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTWH(
      detection.bbox.left,
      detection.bbox.top,
      detection.bbox.width,
      detection.bbox.height,
    );

    canvas.drawRect(rect, paint);

    _drawLabel(canvas, detection, color);
    _drawTTC(canvas, detection, color);
  }

  void _drawLabel(Canvas canvas, Detection detection, Color color) {
    final textSpan = TextSpan(
      text: '${detection.label} ${(detection.confidence * 100).toInt()}%',
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(detection.bbox.left, detection.bbox.top - 20),
    );
  }

  void _drawTTC(Canvas canvas, Detection detection, Color color) {
    if (detection.ttc == null) return;

    final textSpan = TextSpan(
      text: 'TTC: ${detection.ttc!.toStringAsFixed(1)}s',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(detection.bbox.left, detection.bbox.bottom + 5),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.yellow;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(covariant _HudPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
