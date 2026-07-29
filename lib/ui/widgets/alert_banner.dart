import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';
import '../../ai/models.dart';

class AlertBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final RiskLevel level;
  final IconData icon;
  final VoidCallback? onDismiss;
  final Duration duration;

  const AlertBanner({
    super.key,
    required this.title,
    this.subtitle,
    required this.level,
    this.icon = Icons.warning_amber_rounded,
    this.onDismiss,
    this.duration = const Duration(seconds: 5),
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final gradient = _getGradient();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.alert.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor() {
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

  Gradient _getGradient() {
    final color = _getColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.7),
      ],
    );
  }
}
