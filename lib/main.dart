import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/trip_history_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(
    const ProviderScope(
      child: AlicjaRoadSenseApp(),
    ),
  );
}

class AlicjaRoadSenseApp extends StatelessWidget {
  const AlicjaRoadSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alicja RoadSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/history': (context) => const TripHistoryScreen(),
      },
    );
  }
}
