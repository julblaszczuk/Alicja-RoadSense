import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../main.dart';
import '../../ai/vision_engine.dart';
import '../../ai/models.dart';
import '../../ai/road_calibration.dart';
import '../../core/theme/design_system.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/speed_display.dart';
import '../widgets/alert_banner.dart';
import '../widgets/calibration_overlay.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late CameraController _cameraController;
  late VisionEngine _visionEngine;
  final RoadCalibration _calibration = RoadCalibration();
  
  List<Detection> _detections = [];
  bool _isProcessing = false;
  bool _showAlert = false;
  String _alertMessage = '';
  bool _isRecording = false;
  Offset? _tapPosition;
  Detection? _selectedDetection;
  
  // Tryb kalibracji
  bool _isCalibrating = false;
  
  // Panel powiadomień - rozwijany
  bool _showNotifications = false;
  
  // Notification settings
  bool _notifyCollision = true;
  bool _notifyVehicle = true;
  bool _notifyPedestrian = true;
  bool _notifyTrafficLight = true;
  bool _notifyAnimal = true;
  bool _notifySpeed = true;

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
    for (final detection in detections) {
      if (!_shouldNotify(detection)) continue;
      
      if (detection.riskLevel == RiskLevel.critical || detection.riskLevel == RiskLevel.high) {
        if (!_showAlert) {
          setState(() {
            _showAlert = true;
            _alertMessage = '${detection.label} wykryty!';
          });

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showAlert = false;
              });
            }
          });
        }
        break;
      }
    }
  }

  bool _shouldNotify(Detection detection) {
    final label = detection.label.toLowerCase();
    
    if (label == 'car' || label == 'truck' || label == 'bus' || label == 'motorcycle') {
      return _notifyVehicle;
    }
    if (label == 'person') return _notifyPedestrian;
    if (label == 'traffic light' || label == 'stop sign') return _notifyTrafficLight;
    if (label == 'cat' || label == 'dog' || label == 'horse' || label == 'bird') {
      return _notifyAnimal;
    }
    return _notifyCollision;
  }

  void _onTap(TapDownDetails details) {
    // Tryb kalibracji - dodaj punkt
    if (_isCalibrating) {
      // TODO: Dodaj punkt do kalibracji
      return;
    }
    
    setState(() {
      _tapPosition = details.localPosition;
      
      // Znajdź najbliższą detekcję do kliknięcia
      Detection? closest;
      double minDistance = double.infinity;
      
      for (final detection in _detections) {
        final center = Offset(
          detection.bbox.left + detection.bbox.width / 2,
          detection.bbox.top + detection.bbox.height / 2,
        );
        
        final distance = (center - _tapPosition!).distance;
        if (distance < minDistance && distance < 100) {
          minDistance = distance;
          closest = detection;
        }
      }
      
      _selectedDetection = closest;
    });
  }

  void _toggleRecording() async {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      await _cameraController.startVideoRecording();
    } else {
      final video = await _cameraController.stopVideoRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nagranie zapisane: ${video.path}'),
          duration: const Duration(seconds: 2),
        ),
      );
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
      body: GestureDetector(
        onTapDown: _onTap,
        child: Stack(
          children: [
            CameraPreview(_cameraController),
            DetectionOverlay(
              detections: _detections,
              selectedDetection: _selectedDetection,
            ),
            
            // Calibration overlay
            if (_isCalibrating)
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    // TODO: Dodaj punkt kalibracyjny
                  },
                  child: CalibrationOverlay(
                    calibration: _calibration,
                  ),
                ),
              ),
            
            // Top bar - Risk indicator + Speed
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
            
            // Alert banner
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
            
            // Selected detection info
            if (_selectedDetection != null)
              Positioned(
                top: 220,
                left: 20,
                right: 20,
                child: _buildSelectedDetectionCard(),
              ),
            
            // Right side - Notification button + Calibration button
            Positioned(
              right: 20,
              top: 300,
              child: Column(
                children: [
                  _buildCalibrationButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildNotificationButton(),
                ],
              ),
            ),
            
            // Expanded notification panel
            if (_showNotifications)
              Positioned(
                right: 80,
                top: 300,
                child: _buildNotificationPanel(),
              ),
            
            // Record button (right side)
            Positioned(
              right: 20,
              bottom: 180,
              child: _buildRecordButton(),
            ),
            
            // Bottom bar - Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
            
            // Detection count
            Positioned(
              left: 20,
              bottom: 180,
              child: _buildDetectionCount(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDetectionCard() {
    final detection = _selectedDetection!;
    final color = _getRiskColor(detection.riskLevel);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_getDetectionIcon(detection.label), color: color, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                detection.label.toUpperCase(),
                style: AppTypography.h3.copyWith(color: color),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _selectedDetection = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Pewność: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(width: AppSpacing.lg),
              if (detection.ttc != null)
                Text(
                  'TTC: ${detection.ttc!.toStringAsFixed(1)}s',
                  style: AppTypography.bodySmall.copyWith(color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCalibrating = !_isCalibrating;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isCalibrating ? AppColors.warning : AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isCalibrating ? AppColors.warning : AppColors.primary,
            width: 2,
          ),
        ),
        child: Icon(
          _isCalibrating ? Icons.edit : Icons.route,
          color: _isCalibrating ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showNotifications = !_showNotifications;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _showNotifications ? AppColors.primary : AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        child: Icon(
          _showNotifications ? Icons.expand_less : Icons.notifications_outlined,
          color: _showNotifications ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNotificationPanel() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powiadomienia',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildNotificationCheckbox(
            icon: Icons.directions_car,
            label: 'Pojazdy',
            value: _notifyVehicle,
            onChanged: (v) => setState(() => _notifyVehicle = v),
          ),
          _buildNotificationCheckbox(
            icon: Icons.person,
            label: 'Piesi',
            value: _notifyPedestrian,
            onChanged: (v) => setState(() => _notifyPedestrian = v),
          ),
          _buildNotificationCheckbox(
            icon: Icons.traffic,
            label: 'Sygnalizacja',
            value: _notifyTrafficLight,
            onChanged: (v) => setState(() => _notifyTrafficLight = v),
          ),
          _buildNotificationCheckbox(
            icon: Icons.pets,
            label: 'Zwierzęta',
            value: _notifyAnimal,
            onChanged: (v) => setState(() => _notifyAnimal = v),
          ),
          _buildNotificationCheckbox(
            icon: Icons.speed,
            label: 'Prędkość',
            value: _notifySpeed,
            onChanged: (v) => setState(() => _notifySpeed = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCheckbox({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            height: 20,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _isRecording ? AppColors.danger : AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isRecording ? AppColors.danger : AppColors.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? AppColors.danger : AppColors.primary).withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.fiber_manual_record,
          color: _isRecording ? Colors.white : AppColors.danger,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDetectionCount() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${_detections.length} obiektów',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
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
            icon: Icons.phone_outlined,
            label: 'Telefon',
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.send_outlined,
            label: 'Wyślij',
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.history_outlined,
            label: 'Historia',
            onTap: () {
              Navigator.pushNamed(context, '/history');
            },
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
            padding: const EdgeInsets.all(AppSpacing.sm),
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
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
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

  IconData _getDetectionIcon(String label) {
    switch (label.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      case 'bus':
        return Icons.directions_bus;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'person':
        return Icons.person;
      case 'traffic light':
        return Icons.traffic;
      case 'stop sign':
        return Icons.stop;
      case 'cat':
        return Icons.pets;
      case 'dog':
        return Icons.pets;
      default:
        return Icons.search;
    }
  }
}
