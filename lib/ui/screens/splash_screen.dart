import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _status = 'Checking permissions...');
      await _checkPermissions();
    } catch (e) {
      debugPrint('Splash permission warning: $e');
    }

    setState(() => _status = 'Loading AI models...');
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _status = 'Starting camera...');
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _checkPermissions() async {
    debugPrint('Splash: checking permissions...');
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Splash: location services enabled = $serviceEnabled');
    
    if (!serviceEnabled) {
      debugPrint('Splash: location services disabled, skipping');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('Splash: location permission = $permission');
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('Splash: after request permission = $permission');
    }

    debugPrint('Splash: cameras count = ${cameras.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              width: 150,
              height: 150,
              colorFilter: _hasError 
                  ? const ColorFilter.mode(Colors.red, BlendMode.srcIn)
                  : const ColorFilter.mode(Color(0xFF1E88E5), BlendMode.srcIn),
            ),
            const SizedBox(height: 32),
            const Text(
              'Alicja RoadSense',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _hasError ? Colors.red : Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (!_hasError)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
              ),
          ],
        ),
      ),
    );
  }
}
