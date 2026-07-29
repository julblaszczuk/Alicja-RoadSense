import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../main.dart';
import '../../ai/vision_engine.dart';
import '../../ai/models.dart';
import '../../core/theme/design_system.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/speed_display.dart';
import '../widgets/alert_banner.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late CameraController _cameraController;
  late VisionEngine _visionEngine;
  List<Detection> _detections = [];
  bool _isProcessing = false;
  bool _showAlert = false;
  String _alertMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _visionEngine = VisionEngine();
  }

  Future<void> _initializeCamera() async {
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();

    await _cameraController.startImageStream((image) {
      if (!_isProcessing) {
        _processFrame(image);
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _processFrame(CameraImage image) async {
    _isProcessing = true;

    try {
      final detections = await _visionEngine.detect(image);
      if (mounted) {
        setState(() {
          _detections = detections;
          _checkForAlerts(detections);
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _checkForAlerts(List<Detection> detections) {
    final criticalDetections = detections.where(
      (d) => d.riskLevel == RiskLevel.critical || d.riskLevel == RiskLevel.high,
    );

    if (criticalDetections.isNotEmpty && !_showAlert) {
      setState(() {
        _showAlert = true;
        _alertMessage = 'Zagrożenie wykryte!';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showAlert = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _visionEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          DetectionOverlay(detections: _detections),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RiskIndicator(detections: _detections),
                ),
                const SizedBox(width: AppSpacing.md),
                const SpeedDisplay(),
              ],
            ),
          ),
          if (_showAlert)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: AlertBanner(
                title: _alertMessage,
                subtitle: 'Zachowaj ostrożność',
                level: RiskLevel.critical,
                icon: Icons.warning_amber_rounded,
                onDismiss: () {
                  setState(() {
                    _showAlert = false;
                  });
                },
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background.withOpacity(0.95),
            AppColors.background.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.map_outlined,
            label: 'Nawigacja',
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.history_outlined,
            label: 'Historia',
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.analytics_outlined,
            label: 'Statystyki',
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.settings_outlined,
            label: 'Ustawienia',
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
