import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import 'core/config.dart';
import 'core/event_bus.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/splash_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
