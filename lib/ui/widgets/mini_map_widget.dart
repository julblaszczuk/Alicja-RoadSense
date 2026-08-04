import 'package:flutter/material.dart';
import '../../core/theme/design_system.dart';

class MiniMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? heading;

  const MiniMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Mapa placeholder
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glass,
                  AppColors.glass.withOpacity(0.5),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.map,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
          ),
          
          // Wskaźnik pozycji
          if (latitude != null && longitude != null)
            Center(
              child: Transform.rotate(
                angle: (heading ?? 0) * 3.14159 / 180,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          
          // Etykieta
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                latitude != null && longitude != null
                    ? '${latitude!.toStringAsFixed(2)}, ${longitude!.toStringAsFixed(2)}'
                    : 'Brak GPS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
