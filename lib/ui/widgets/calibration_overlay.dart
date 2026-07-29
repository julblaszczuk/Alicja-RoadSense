import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import '../../ai/road_calibration.dart';

/// Overlay do kalibracji drogi - zaznaczanie punktów
class CalibrationOverlay extends StatefulWidget {
  final RoadCalibration calibration;
  final Function(CalibrationPoint)? onPointAdded;
  final Function()? onCalibrationComplete;

  const CalibrationOverlay({
    super.key,
    required this.calibration,
    this.onPointAdded,
    this.onCalibrationComplete,
  });

  @override
  State<CalibrationOverlay> createState() => _CalibrationOverlayState();
}

class _CalibrationOverlayState extends State<CalibrationOverlay> {
  CalibrationMode _mode = CalibrationMode.road;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Rysuj istniejące punkty
        CustomPaint(
          painter: _CalibrationPainter(
            calibration: widget.calibration,
            mode: _mode,
          ),
          child: const SizedBox.expand(),
        ),
        
        // Panel sterowania
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: _buildControlPanel(),
        ),
        
        // Instrukcje
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: _buildInstructions(),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'KALIBRACJA DROGI',
            style: AppTypography.h3.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Przełącznik trybu
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  label: 'Droga',
                  icon: Icons.route,
                  mode: CalibrationMode.road,
                  isActive: _mode == CalibrationMode.road,
                  onTap: () => setState(() => _mode = CalibrationMode.road),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildModeButton(
                  label: 'ROI (maska)',
                  icon: Icons.crop_free,
                  mode: CalibrationMode.roi,
                  isActive: _mode == CalibrationMode.roi,
                  onTap: () => setState(() => _mode = CalibrationMode.roi),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Przyciski akcji
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _complete,
                  icon: const Icon(Icons.check),
                  label: const Text('Gotowe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required CalibrationMode mode,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final points = _mode == CalibrationMode.road 
        ? widget.calibration.points 
        : widget.calibration.roiPoints;
    
    final requiredPoints = _mode == CalibrationMode.road ? 4 : 3;
    final remaining = requiredPoints - points.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remaining > 0
                ? 'Kliknij w ekran aby dodać punkt\nPozostało: $remaining'
                : 'Wszystkie punkty dodane!\nKliknij "Gotowe" aby zakończyć',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: remaining > 0 ? AppColors.textPrimary : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    widget.calibration.reset();
    setState(() {});
  }

  void _complete() {
    widget.onCalibrationComplete?.call();
  }

  void addPoint(double x, double y) {
    final label = _mode == CalibrationMode.road
        ? 'Punkt ${widget.calibration.points.length + 1}'
        : 'ROI ${widget.calibration.roiPoints.length + 1}';

    final point = CalibrationPoint(
      x: x,
      y: y,
      label: label,
    );

    if (_mode == CalibrationMode.road) {
      if (widget.calibration.points.length < 4) {
        widget.calibration.setCalibrationPoints([
          ...widget.calibration.points,
          point,
        ]);
      }
    } else {
      widget.calibration.setROIPoints([
        ...widget.calibration.roiPoints,
        point,
      ]);
    }

    widget.onPointAdded?.call(point);
    setState(() {});
  }
}

enum CalibrationMode {
  road,
  roi,
}

class _CalibrationPainter extends CustomPainter {
  final RoadCalibration calibration;
  final CalibrationMode mode;

  _CalibrationPainter({
    required this.calibration,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rysuj punkty drogi
    if (calibration.points.isNotEmpty) {
      _drawPoints(canvas, calibration.points, AppColors.primary, 'Droga');
      if (calibration.points.length == 4) {
        _drawPolygon(canvas, calibration.points, AppColors.primary.withOpacity(0.2));
      }
    }

    // Rysuj ROI
    if (calibration.roiPoints.isNotEmpty) {
      _drawPoints(canvas, calibration.roiPoints, AppColors.warning, 'ROI');
      if (calibration.roiPoints.length >= 3) {
        _drawPolygon(canvas, calibration.roiPoints, AppColors.warning.withOpacity(0.2));
      }
    }
  }

  void _drawPoints(Canvas canvas, List<CalibrationPoint> points, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Kółko
      canvas.drawCircle(Offset(point.x, point.y), 12, paint);
      canvas.drawCircle(Offset(point.x, point.y), 12, strokePaint);
      
      // Numer
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.x - textPainter.width / 2, point.y - textPainter.height / 2),
      );
    }
  }

  void _drawPolygon(Canvas canvas, List<CalibrationPoint> points, Color color) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(points[0].x, points[0].y);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x, points[i].y);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CalibrationPainter oldDelegate) {
    return true;
  }
}
