import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import '../../ai/models.dart';

class RiskIndicator extends StatelessWidget {
  final List<Detection> detections;
  final RiskLevel? overrideRisk;

  const RiskIndicator({
    super.key,
    required this.detections,
    this.overrideRisk,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevel = overrideRisk ?? _calculateMaxRisk();
    final riskColor = _getRiskColor(riskLevel);
    final riskLabel = _getRiskLabel(riskLevel);
    final riskIcon = _getRiskIcon(riskLevel);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withOpacity(0.2),
            riskColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: riskColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  riskIcon,
                  color: riskColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    riskLabel,
                    style: AppTypography.h3.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${detections.length} obiektów',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  RiskLevel _calculateMaxRisk() {
    if (detections.isEmpty) return RiskLevel.low;

    return detections.fold(
      RiskLevel.low,
      (max, detection) {
        if (detection.riskLevel.index > max.index) {
          return detection.riskLevel;
        }
        return max;
      },
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

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 'KRYTYCZNE';
      case RiskLevel.high:
        return 'WYSOKIE';
      case RiskLevel.medium:
        return 'ŚREDNIE';
      case RiskLevel.low:
        return 'BEZPIECZNE';
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline;
      case RiskLevel.medium:
        return Icons.info_outline;
      case RiskLevel.low:
        return Icons.check_circle_outline;
    }
  }
}
