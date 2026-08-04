import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/design_system.dart';
import '../../ai/models.dart';
import '../widgets/glassmorphism_card.dart';

class IncidentDetailsScreen extends ConsumerWidget {
  final Detection detection;

  const IncidentDetailsScreen({
    super.key,
    required this.detection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskColor = _getRiskColor(detection.riskLevel);
    final riskLabel = _getRiskLabel(detection.riskLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Szczegóły incydentu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertBanner(riskColor, riskLabel),
            const SizedBox(height: AppSpacing.xl),
            _buildDetectionInfo(riskColor),
            const SizedBox(height: AppSpacing.xl),
            _buildLocationInfo(),
            const SizedBox(height: AppSpacing.xl),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(Color color, String label) {
    return GlassmorphismCard(
      borderColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.h3.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wykryto zagrożenie',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionInfo(Color color) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wykryty obiekt',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildInfoRow(
            icon: Icons.label,
            label: 'Typ',
            value: detection.label.toUpperCase(),
            color: color,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.percent,
            label: 'Pewność',
            value: '${(detection.confidence * 100).toStringAsFixed(1)}%',
            color: AppColors.primary,
          ),
          if (detection.ttc != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow(
              icon: Icons.timer,
              label: 'Czas do kolizji (TTC)',
              value: '${detection.ttc!.toStringAsFixed(1)}s',
              color: detection.ttc! < 2.0 ? AppColors.danger : AppColors.warning,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.speed,
            label: 'Prędkość',
            value: '${detection.velocity?.toStringAsFixed(1) ?? '?'} m/s',
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.straighten,
            label: 'Odległość',
            value: '${detection.distance?.toStringAsFixed(1) ?? '?'} m',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokalizacja',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ul. Floriańska, Kraków',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '50.0619° N, 19.9369° E',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Mini-mapa',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akcje',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incydent zgłoszony'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.report),
              label: const Text('Zgłoś incydent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: const Text('Zamknij'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
        return 'NISKIE';
    }
  }
}
