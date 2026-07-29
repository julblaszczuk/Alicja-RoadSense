import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../main.dart';
import '../../ai/vision_engine.dart';
import '../../ai/models.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/speed_display.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late CameraController _cameraController;
  late VisionEngine _visionEngine;
  List<Detection> _detections = [];
  bool _isProcessing = false;

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
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isProcessing = false;
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
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          HudOverlay(detections: _detections),
          Positioned(
            top: 40,
            left: 20,
            child: RiskIndicator(detections: _detections),
          ),
          const Positioned(
            top: 40,
            right: 20,
            child: SpeedDisplay(),
          ),
          Positioned(
            bottom: 40,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIconButton(Icons.map, 'Navigation'),
          _buildIconButton(Icons.history, 'History'),
          _buildIconButton(Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 28),
          onPressed: () {},
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
