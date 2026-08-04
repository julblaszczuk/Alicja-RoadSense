import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../main.dart';
import '../../ai/vision_engine_yolov8.dart';
import '../../ai/models.dart';
import '../../ai/road_calibration.dart';
import '../../ai/road_map_system.dart';
import '../../ai/tracking/tracking_controller.dart';
import '../../ai/tracking/tracking_provider.dart';
import '../../core/theme/design_system.dart';
import '../../core/settings_provider.dart';
import '../../core/alert_manager.dart';
import '../../core/gps_provider.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/speed_display.dart';
import '../widgets/alert_banner.dart';
import '../widgets/calibration_overlay.dart';
import '../widgets/mini_map_widget.dart';
import '../widgets/tracking_overlay.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late VisionEngine _visionEngine;
  final AlertManager _alertManager = AlertManager();
  final RoadCalibration _calibration = RoadCalibration();
  final RoadMapSystem _roadMap = RoadMapSystem();
  
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
  
  // Panel mapy punktów
  bool _showMapPanel = false;
  
  // Kontrola kamery
  int _currentCameraIndex = 0;
  bool _showCameraSelector = false;
  
  // Notification settings
  bool _notifyCollision = true;
  bool _notifyVehicle = true;
  bool _notifyPedestrian = true;
  bool _notifyTrafficLight = true;
  bool _notifyAnimal = true;
  bool _notifySpeed = true;
  
  // Debug mode
  bool _debugMode = false;
  
  // Rozmiar obrazu źródłowego z kamery
  Size _sourceImageSize = const Size(640, 480);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _visionEngine = VisionEngine();
    _initializeGps();
    
    // Nasłuchuj zmian ustawień
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(appSettingsProvider);
      _visionEngine.setConfidenceThreshold(settings.detectionConfidence);
      _alertManager.setSettings(settings);
      
      ref.listen<AppSettings>(appSettingsProvider, (previous, next) {
        _visionEngine.setConfidenceThreshold(next.detectionConfidence);
        _alertManager.setSettings(next);
      });
    });
  }

  Future<void> _initializeGps() async {
    final gpsManager = ref.read(gpsManagerProvider);
    final hasPermission = await gpsManager.checkPermissions();
    if (hasPermission) {
      gpsManager.startLocationUpdates();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) {
      debugPrint('No cameras available');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController?.initialize();

      await _cameraController?.startImageStream((image) {
        if (!_isProcessing) {
          _processFrame(image);
        }
      });

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;

    // Reset trackera przy przełączeniu kamery
    final trackingController = ref.read(trackingControllerProvider.notifier);
    trackingController.reset();

    await _cameraController?.dispose();
    
    _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    final newCamera = cameras[_currentCameraIndex];

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.startImageStream((image) {
        if (!_isProcessing) {
          _processFrame(image);
        }
      });

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera switch error: $e');
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    _isProcessing = true;

    try {
      // Zapisz rozmiar obrazu źródłowego
      _sourceImageSize = Size(image.width.toDouble(), image.height.toDouble());

      final detections = await _visionEngine.detect(image);
      if (mounted) {
        // Aktualizuj prędkość własnego pojazdu z GPS
        final trackingController = ref.read(trackingControllerProvider.notifier);
        final gpsPosition = ref.read(gpsPositionProvider).valueOrNull;
        trackingController.updateEgoSpeed(gpsPosition);
        
        // Przekaż detekcje do trackera
        trackingController.processDetections(
          detections: detections,
          sourceImageSize: _sourceImageSize,
        );

        setState(() {
          _detections = detections; // Zastąp wyniki, nie dodawaj
          _checkForAlerts(detections);
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      if (mounted) {
        setState(() {
          _detections = []; // Wyczyść przy błędzie
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _checkForAlerts(List<Detection> detections) {
    // Sprawdź ryzyko z trackera
    final trackingState = ref.read(trackingControllerProvider);
    
    // Sprawdź czy jest krytyczne ryzyko
    if (trackingState.highestRiskLevel == RiskLevel.critical ||
        trackingState.highestRiskLevel == RiskLevel.high) {
      
      final highestRiskTrack = ref.read(trackingControllerProvider.notifier).highestRiskTrack;
      final riskAssessment = highestRiskTrack != null 
          ? trackingState.riskMap[highestRiskTrack.id] 
          : null;
      
      if (riskAssessment != null && !_showAlert) {
        setState(() {
          _showAlert = true;
          _alertMessage = riskAssessment.description;
        });

        // Odtwórz alert dźwiękowy i wibrację
        _alertManager.playAlert(
          soundAsset: 'sounds/alert_critical.wav',
          vibrate: riskAssessment.level == RiskLevel.critical,
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showAlert = false;
            });
          }
        });
      }
      return;
    }
    
    // Fallback - sprawdź detekcje bez trackingu
    for (final detection in detections) {
      if (!_shouldNotify(detection)) continue;
      
      // Automatyczne wykrywanie robotów drogowych i wypadków
      _checkForRoadHazards(detection);
      
      if (detection.riskLevel == RiskLevel.critical || detection.riskLevel == RiskLevel.high) {
        if (!_showAlert) {
          setState(() {
            _showAlert = true;
            _alertMessage = '${detection.label} wykryty!';
          });

          // Odtwórz alert dźwiękowy i wibrację
          _alertManager.playAlert(
            soundAsset: 'sounds/alert_critical.wav',
            vibrate: detection.riskLevel == RiskLevel.critical,
          );

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

  void _checkForRoadHazards(Detection detection) {
    // Wykrywanie robotów drogowych (stożki, znaki robót)
    if (detection.label == 'traffic cone' || detection.label == 'stop sign') {
      _showReportSuggestion('Roboty drogowe', MapPointGroupType.roadWork);
    }
    
    // Wykrywanie wypadków (uszkodzone pojazdy)
    if (detection.label == 'car' && detection.confidence < 0.5) {
      _showReportSuggestion('Możliwy wypadek', MapPointGroupType.accident);
    }
  }

  void _showReportSuggestion(String message, MapPointGroupType type) {
    // Pokaż sugestię zgłoszenia
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Zgłoś',
          onPressed: () => _createReport(message, type),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _createReport(String description, MapPointGroupType type) {
    // TODO: Pobierz aktualną lokalizację GPS
    final report = UserReport(
      id: 'report-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      description: description,
      location: MapPoint(
        id: 'point-${DateTime.now().millisecondsSinceEpoch}',
        latitude: 0.0, // TODO: Podmień na prawdziwą lokalizację
        longitude: 0.0,
      ),
    );
    
    _roadMap.addReport(report);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zgłoszenie wysłane!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _shouldNotify(Detection detection) {
    final label = detection.label.toLowerCase();
    
    if (label == 'car' || label == 'truck' || label == 'bus' || label == 'motorcycle' || label == 'rider' || label == 'train') {
      return _notifyVehicle;
    }
    if (label == 'person') return _notifyPedestrian;
    if (label == 'traffic light' || label == 'traffic sign') return _notifyTrafficLight;
    if (label == 'bicycle') return _notifyCollision;
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
    if (_cameraController == null) return;

    setState(() {
      _isRecording = !_isRecording;
    });

    try {
      if (_isRecording) {
        await _cameraController!.startVideoRecording();
      } else {
        final video = await _cameraController!.stopVideoRecording();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nagranie zapisane: ${video.path}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Recording error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _visionEngine.dispose();
    _alertManager.dispose();
    ref.read(gpsManagerProvider).stopLocationUpdates();
    ref.read(trackingControllerProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 64, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'Brak dostępu do kamery',
                style: AppTypography.h3,
              ),
              SizedBox(height: 8),
              Text(
                'Aplikacja wymaga kamery do działania',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraController!.value.isInitialized) {
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
      backgroundColor: Colors.black,
      extendBody: true,
      body: GestureDetector(
        onTapDown: _onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = Size(constraints.maxWidth, constraints.maxHeight);
            final trackingState = ref.watch(trackingControllerProvider);
            
            return Stack(
              children: [
                CameraPreview(_cameraController!),
                
                // Tracking overlay - wyświetla śledzone obiekty
                TrackingOverlay(
                  objects: trackingState.objects,
                  previewSize: previewSize,
                  sourceImageSize: _sourceImageSize,
                  debugMode: _debugMode,
                  showTentative: _debugMode,
                  showLost: _debugMode,
                  showTrajectory: _debugMode,
                  ttcMap: trackingState.ttcMap,
                  riskMap: trackingState.riskMap,
                ),
                
                DetectionOverlay(
                  detections: _detections,
                  selectedDetection: _selectedDetection,
                  imageSize: const Size(300, 300),
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
                  const SizedBox(width: AppSpacing.md),
                  _buildMiniMap(),
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
            
            // Right side - Camera switch + Calibration + Map + Notification buttons
            Positioned(
              right: 20,
              top: 300,
              child: Column(
                children: [
                  _buildCameraSwitchButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildCalibrationButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildMapButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildNotificationButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildDebugButton(),
                ],
              ),
            ),
            
            // Map panel
            if (_showMapPanel)
              Positioned(
                right: 80,
                top: 300,
                bottom: 200,
                child: _buildMapPanel(),
              ),
            
            // Expanded notification panel
            if (_showNotifications)
              Positioned(
                right: 80,
                top: 300,
                child: _buildNotificationPanel(),
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
        );
      },
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

  Widget _buildCameraSwitchButton() {
    return GestureDetector(
      onTap: _switchCamera,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Icon(
          Icons.switch_camera,
          color: AppColors.primary,
          size: 24,
        ),
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

  Widget _buildMapButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMapPanel = !_showMapPanel;
          _showNotifications = false;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _showMapPanel ? AppColors.primary : AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Icon(
          _showMapPanel ? Icons.expand_less : Icons.map_outlined,
          color: _showMapPanel ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMapPanel() {
    final groups = _roadMap.groups;
    final reports = _roadMap.reports;

    return Container(
      width: 280,
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
          Row(
            children: [
              Icon(Icons.map, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Mapa punktów',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Grupy punktów
          if (groups.isNotEmpty) ...[
            Text(
              'Grupy (${groups.length})',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupItem(group);
                },
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.md),
          
          // Zgłoszenia
          if (reports.isNotEmpty) ...[
            Text(
              'Zgłoszenia (${reports.length})',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportItem(report);
                },
              ),
            ),
          ],
          
          // Przycisk ręcznego zgłoszenia
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showManualReportDialog(),
              icon: const Icon(Icons.add_alert, size: 18),
              label: const Text('Zgłoś zdarzenie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem(MapPointGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getGroupColor(group.type), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _getGroupIcon(group.type),
            color: _getGroupColor(group.type),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${group.points.length} pkt',
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(UserReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: report.isVerified ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getGroupIcon(report.type),
            color: report.isVerified ? AppColors.success : AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  report.isVerified ? 'Potwierdzone' : '${report.confirmationCount}/3',
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          if (!report.isVerified)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 16),
              color: AppColors.success,
              onPressed: () {
                _roadMap.confirmReport(report.id);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  void _showManualReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zgłoś zdarzenie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.construction),
              title: const Text('Roboty drogowe'),
              onTap: () {
                Navigator.pop(context);
                _createReport('Roboty drogowe', MapPointGroupType.roadWork);
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_crash),
              title: const Text('Wypadek'),
              onTap: () {
                Navigator.pop(context);
                _createReport('Wypadek', MapPointGroupType.accident);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Zwierzę na drodze'),
              onTap: () {
                Navigator.pop(context);
                _createReport('Zwierzę na drodze', MapPointGroupType.temporary);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Inne zagrożenie'),
              onTap: () {
                Navigator.pop(context);
                _createReport('Inne zagrożenie', MapPointGroupType.custom);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getGroupColor(MapPointGroupType type) {
    switch (type) {
      case MapPointGroupType.curb:
        return AppColors.primary;
      case MapPointGroupType.lane:
        return AppColors.secondary;
      case MapPointGroupType.temporary:
        return AppColors.warning;
      case MapPointGroupType.roadWork:
        return Colors.orange;
      case MapPointGroupType.accident:
        return AppColors.danger;
      case MapPointGroupType.trafficSign:
        return AppColors.success;
      case MapPointGroupType.custom:
        return AppColors.textSecondary;
    }
  }

  IconData _getGroupIcon(MapPointGroupType type) {
    switch (type) {
      case MapPointGroupType.curb:
        return Icons.border_outer;
      case MapPointGroupType.lane:
        return Icons.alt_route;
      case MapPointGroupType.temporary:
        return Icons.hourglass_empty;
      case MapPointGroupType.roadWork:
        return Icons.construction;
      case MapPointGroupType.accident:
        return Icons.car_crash;
      case MapPointGroupType.trafficSign:
        return Icons.traffic;
      case MapPointGroupType.custom:
        return Icons.label;
    }
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

  Widget _buildDebugButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _debugMode = !_debugMode;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _debugMode ? AppColors.warning : AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: _debugMode ? AppColors.warning : AppColors.border,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.bug_report,
          color: _debugMode ? Colors.white : AppColors.textSecondary,
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

  Widget _buildMiniMap() {
    final gpsAsync = ref.watch(gpsPositionProvider);
    return gpsAsync.when(
      data: (position) => MiniMapWidget(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
      ),
      loading: () => const MiniMapWidget(),
      error: (_, __) => const MiniMapWidget(),
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
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildNavItem(
              icon: Icons.map_outlined,
              label: 'Nawigacja',
              onTap: () {
                Navigator.pushNamed(context, '/navigation');
              },
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.phone_outlined,
              label: 'Telefon',
              onTap: () {},
            ),
          ),
          Expanded(
            child: _buildRecordNavItem(),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.history_outlined,
              label: 'Historia',
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.settings_outlined,
              label: 'Ustawienia',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.navigation, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Nawigacja',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              decoration: InputDecoration(
                hintText: 'Dokąd chcesz jechać?',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.glass,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('MapBox nawigacja - w przygotowaniu'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.route),
                label: const Text('Wyznacz trasę'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordNavItem() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.danger.withOpacity(0.2) : AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _isRecording ? AppColors.danger : AppColors.borderLight,
                width: _isRecording ? 2 : 1,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.fiber_manual_record,
              color: _isRecording ? AppColors.danger : AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isRecording ? 'Stop' : 'Nagrywaj',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              color: _isRecording ? AppColors.danger : null,
            ),
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
      case 'rider':
        return Icons.sports_motorsports;
      case 'train':
        return Icons.train;
      case 'traffic light':
        return Icons.traffic;
      case 'traffic sign':
        return Icons.signpost;
      default:
        return Icons.search;
    }
  }
}
