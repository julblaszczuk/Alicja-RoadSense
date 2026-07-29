import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/design_system.dart';

class SpeedDisplay extends StatefulWidget {
  const SpeedDisplay({super.key});

  @override
  State<SpeedDisplay> createState() => _SpeedDisplayState();
}

class _SpeedDisplayState extends State<SpeedDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _speedAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _speedAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (mounted) {
        final newSpeed = position.speed * 3.6;
        setState(() {
          _speedAnimation = Tween<double>(
            begin: _speedAnimation.value,
            end: newSpeed,
          ).animate(_animationController);
          _animationController.forward(from: 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _speedAnimation,
      builder: (context, child) {
        final displaySpeed = _speedAnimation.value;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displaySpeed.toStringAsFixed(0),
                style: AppTypography.speed.copyWith(
                  color: AppColors.primary,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'km/h',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
