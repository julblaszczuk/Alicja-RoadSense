import 'package:flutter/material.dart';
import '../../ai/models.dart';
import '../../ai/risk_scorer.dart';
import '../../ai/tracking/tracked_object.dart';
import '../../ai/tracking/track_state.dart';

/// Overlay wyświetlający śledzone obiekty na podglądzie kamery
class TrackingOverlay extends StatelessWidget {
  /// Lista śledzonych obiektów
  final List<TrackedObject> objects;

  /// Rozmiar podglądu kamery na ekranie
  final Size previewSize;

  /// Rozmiar obrazu źródłowego z kamery
  final Size sourceImageSize;

  /// Czy wyświetlać informacje debug
  final bool debugMode;

  /// Czy wyświetlać tracki TENTATIVE
  final bool showTentative;

  /// Czy wyświetlać tracki LOST
  final bool showLost;

  /// Czy wyświetlać trajektorie
  final bool showTrajectory;

  /// Mapa TTC dla tracków (trackId -> ttc w sekundach)
  final Map<int, double?> ttcMap;

  /// Mapa ryzyka dla tracków (trackId -> RiskAssessment)
  final Map<int, RiskAssessment> riskMap;

  const TrackingOverlay({
    super.key,
    required this.objects,
    required this.previewSize,
    required this.sourceImageSize,
    this.debugMode = false,
    this.showTentative = false,
    this.showLost = false,
    this.showTrajectory = false,
    this.ttcMap = const {},
    this.riskMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (objects.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: previewSize,
      painter: _TrackingPainter(
        objects: objects,
        previewSize: previewSize,
        sourceImageSize: sourceImageSize,
        debugMode: debugMode,
        showTentative: showTentative,
        showLost: showLost,
        showTrajectory: showTrajectory,
        ttcMap: ttcMap,
        riskMap: riskMap,
      ),
    );
  }
}

class _TrackingPainter extends CustomPainter {
  final List<TrackedObject> objects;
  final Size previewSize;
  final Size sourceImageSize;
  final bool debugMode;
  final bool showTentative;
  final bool showLost;
  final bool showTrajectory;
  final Map<int, double?> ttcMap;
  final Map<int, RiskAssessment> riskMap;

  _TrackingPainter({
    required this.objects,
    required this.previewSize,
    required this.sourceImageSize,
    required this.debugMode,
    required this.showTentative,
    required this.showLost,
    required this.showTrajectory,
    required this.ttcMap,
    required this.riskMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Oblicz skalę transformacji
    final scaleX = previewSize.width / sourceImageSize.width;
    final scaleY = previewSize.height / sourceImageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Oblicz offset dla centrowania (letterbox)
    final scaledWidth = sourceImageSize.width * scale;
    final scaledHeight = sourceImageSize.height * scale;
    final offsetX = (previewSize.width - scaledWidth) / 2;
    final offsetY = (previewSize.height - scaledHeight) / 2;

    for (final obj in objects) {
      // Filtruj według stanu
      if (obj.state == TrackState.tentative && !showTentative && !debugMode) {
        continue;
      }
      if (obj.state == TrackState.lost && !showLost && !debugMode) {
        continue;
      }

      // Transformuj bounding box
      final bbox = obj.bbox;
      final left = bbox.left * scale + offsetX;
      final top = bbox.top * scale + offsetY;
      final width = bbox.width * scale;
      final height = bbox.height * scale;

      final rect = Rect.fromLTWH(left, top, width, height);

      // Kolor według stanu
      final color = _getColorForState(obj.state, obj.predictedOnly);

      // Rysuj bounding box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = debugMode ? 3.0 : 2.0;

      canvas.drawRect(rect, boxPaint);

      // Rysuj wypełnienie
      final fillPaint = Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, fillPaint);

      // Rysuj trajektorie
      if (showTrajectory && obj.trajectory.length > 1) {
        _drawTrajectory(canvas, obj, scale, offsetX, offsetY, color);
      }

      // Rysuj etykiety
      _drawLabel(canvas, obj, rect, color);
    }
  }

  void _drawTrajectory(
    Canvas canvas,
    TrackedObject obj,
    double scale,
    double offsetX,
    double offsetY,
    Color color,
  ) {
    final trajectoryPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    var first = true;

    for (final point in obj.trajectory) {
      final x = point.centerX * scale + offsetX;
      final y = point.centerY * scale + offsetY;

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, trajectoryPaint);
  }

  void _drawLabel(
    Canvas canvas,
    TrackedObject obj,
    Rect rect,
    Color color,
  ) {
    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    // Główna etykieta: ID + klasa
    String label;
    if (debugMode) {
      label = '#${obj.id} ${obj.label}';
      if (obj.state == TrackState.tentative) {
        label += ' [T]';
      } else if (obj.state == TrackState.lost) {
        label += ' [L]';
      }
      if (obj.predictedOnly) {
        label += ' [P]';
      }
    } else {
      label = '#${obj.id} ${obj.label}';
    }

    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: debugMode ? 12 : 14,
        fontWeight: FontWeight.bold,
        background: Paint()..color = color.withOpacity(0.8),
      ),
    );
    textPainter.layout();

    // Pozycja etykiety (nad bounding box)
    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 4,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    // Tło etykiety
    final bgPaint = Paint()..color = color.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
      bgPaint,
    );

    // Tekst
    textPainter.paint(canvas, Offset(rect.left + 4, labelRect.top + 2));

    // Dodatkowe informacje w debug mode
    if (debugMode) {
      final debugInfo = <String>[
        'conf: ${(obj.confidence * 100).toStringAsFixed(0)}%',
        'hits: ${obj.hits}',
        'age: ${obj.age}',
      ];

      if (obj.imageVelocity.magnitude > 0) {
        debugInfo.add(
            'vel: ${obj.imageVelocity.magnitude.toStringAsFixed(0)} px/s');
      }

      // Dodaj TTC jeśli dostępne
      final ttc = ttcMap[obj.id];
      if (ttc != null) {
        debugInfo.add('TTC: ${ttc.toStringAsFixed(1)}s');
      }

      // Dodaj risk jeśli dostępne
      final risk = riskMap[obj.id];
      if (risk != null) {
        debugInfo.add('risk: ${risk.score.toStringAsFixed(0)}');
      }

      final debugText = debugInfo.join(' | ');
      textPainter.text = TextSpan(
        text: debugText,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          background: Paint()..color = Colors.black54,
        ),
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.bottom + 4),
      );
    }

    textPainter.dispose();
  }

  Color _getColorForState(TrackState state, bool predictedOnly) {
    if (predictedOnly) {
      return Colors.orange;
    }

    switch (state) {
      case TrackState.confirmed:
        return Colors.green;
      case TrackState.tentative:
        return Colors.yellow;
      case TrackState.lost:
        return Colors.red;
      case TrackState.deleted:
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant _TrackingPainter oldPainter) {
    return oldPainter.objects != objects ||
        oldPainter.previewSize != previewSize ||
        oldPainter.sourceImageSize != sourceImageSize ||
        oldPainter.debugMode != debugMode ||
        oldPainter.showTentative != showTentative ||
        oldPainter.showLost != showLost ||
        oldPainter.showTrajectory != showTrajectory;
  }
}
