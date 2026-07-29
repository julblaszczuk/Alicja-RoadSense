import 'package:flutter/material.dart';
import '../../ai/models.dart';

class RiskIndicator extends StatelessWidget {
  final List<Detection> detections;

  const RiskIndicator({super.key, required this.detections});

  @override
  Widget build(BuildContext context) {
    final maxRisk = _calculateMaxRisk();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRiskColor(maxRisk), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield,
                color: _getRiskColor(maxRisk),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getRiskLabel(maxRisk),
                style: TextStyle(
                  color: _getRiskColor(maxRisk),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${detections.length} objects detected',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
        return Colors.red;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.medium:
        return Colors.yellow;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 'CRITICAL';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.low:
        return 'SAFE';
    }
  }
}
