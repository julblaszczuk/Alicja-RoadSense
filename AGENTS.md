# AGENTS.md - Alicja RoadSense

## Project Overview

**Alicja RoadSense** is a Flutter-based AI driving assistant with real-time collision detection, vehicle proximity monitoring, and predictive safety alerts.

### Core Mission

Build a safety-critical mobile application that:
- Detects vehicles, pedestrians, and obstacles in real-time (<150ms latency)
- Predicts collisions using AI/ML models
- Provides visual/audio/haptic alerts to drivers
- Works offline-first (all processing on-device)
- Prioritizes accuracy and reliability over features

## Architecture

```
lib/
├── main.dart              # App entry point
├── core/                  # Core infrastructure
│   ├── settings_provider.dart  # App settings (Riverpod)
│   ├── alert_manager.dart      # Audio/haptic alerts
│   └── theme/                  # App theme and design system
├── ai/                    # AI/ML pipeline
│   ├── vision_engine_yolov8.dart  # YOLOv8n BDD100K inference
│   ├── vision_engine.dart         # Legacy MobileNet SSD
│   ├── models.dart                # Detection data models
│   ├── road_calibration.dart      # Road calibration
│   └── road_map_system.dart       # Road map system
├── ui/                    # User interface
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── navigation_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── trip_history_screen.dart
│   │   └── incident_details_screen.dart
│   └── widgets/
│       ├── detection_overlay.dart
│       ├── risk_indicator.dart
│       ├── speed_display.dart
│       ├── alert_banner.dart
│       ├── mini_map_widget.dart
│       ├── calibration_overlay.dart
│       └── glassmorphism_card.dart
└── sensors/               # Hardware sensors (TODO)
    ├── camera_manager.dart
    ├── gps_manager.dart
    └── imu_manager.dart
```

## Tech Stack

- **Framework**: Flutter 3.5+ (Dart)
- **State Management**: Riverpod
- **AI/ML**: TensorFlow Lite (on-device inference)
- **Camera**: camera package
- **Location**: geolocator
- **Maps**: mapbox_maps_flutter
- **Database**: sqflite
- **Testing**: flutter_test

## Coding Standards

### Language

- **Dart**: Follow official Dart style guide
- **Comments**: Write in English (code, commits, docs)
- **Naming**: Use descriptive names (camelCase for variables, PascalCase for classes)

### Code Quality

```dart
// ✅ GOOD
class VisionEngine {
  Future<List<Detection>> detect(CameraImage image) async {
    // Implementation
  }
}

// ❌ BAD
class VE {
  detect(img) async {}
}
```

### Rules

1. **No print() in production code** - Use `logger` package
2. **Always handle errors** - Wrap async calls in try-catch
3. **Type safety** - Avoid `dynamic`, use explicit types
4. **Immutable data** - Use `final` for fields, prefer const constructors
5. **Single responsibility** - One class/file = one purpose
6. **Test coverage** - Write tests for critical logic (AI, alerts, tracking)

## Performance Requirements

- **Frame processing**: <50ms per frame
- **Detection to alert**: <100ms
- **End-to-end latency**: <150ms
- **Battery usage**: <15% per hour
- **Memory usage**: <500MB

## Safety Guidelines

**CRITICAL**: This is a safety-critical application.

1. **Never block the main thread** - Use async/await for heavy operations
2. **Handle all edge cases** - Null checks, empty lists, permission denials
3. **Fail safely** - If AI model fails, show warning, don't crash
4. **Battery awareness** - Optimize for mobile (reduce frame rate when stationary)
5. **Privacy first** - Never upload video/images without explicit user consent

## Git Workflow

### Branch Strategy

- `main` - Production-ready code
- `feature/*` - New features (e.g., `feature/multi-object-tracking`)
- `fix/*` - Bug fixes
- `refactor/*` - Code refactoring
- `docs/*` - Documentation only

### Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(vision): add pedestrian detection model
fix(alerts): resolve haptic feedback not triggering on iOS
refactor(tracker): optimize SORT algorithm for mobile
docs(readme): update setup instructions
test(vision): add unit tests for TTC calculation
chore(deps): update tflite_flutter to 0.11.0
```

### Pull Request Process

1. Create feature branch from `main`
2. Make changes with small, focused commits
3. Write/update tests
4. Run `flutter test` and `flutter analyze`
5. Update documentation if needed
6. Create PR with description:
   - What changed
   - Why it changed
   - How to test
   - Screenshots (if UI changes)
7. Request review
8. Merge after approval

## Testing Strategy

### Unit Tests

- Test AI models (detection, tracking, prediction)
- Test alert logic (thresholds, priorities)
- Test data transformations

```dart
test('should calculate risk level based on TTC', () {
  final detection = Detection(
    label: 'car',
    confidence: 0.9,
    bbox: Rect(left: 0, top: 0, width: 100, height: 100),
    ttc: 1.5,
    trackId: 1,
  );
  
  expect(detection.riskLevel, RiskLevel.critical);
});
```

### Integration Tests

- Test camera → AI → alert flow
- Test GPS → navigation → UI flow
- Test database → repository → UI flow

### Widget Tests

- Test HUD overlay rendering
- Test risk indicator states
- Test settings panel

## Common Tasks

### Add New Detection Model

1. Place `.tflite` model in `models/`
2. Update `VisionEngine` to load model
3. Add post-processing logic
4. Write unit tests
5. Benchmark performance

### Add New Alert Type

1. Define alert in `alerts/alert_manager.dart`
2. Implement audio/haptic/visual feedback
3. Add configuration option in `config.dart`
4. Test on both Android and iOS

### Optimize Performance

1. Profile with Flutter DevTools
2. Identify bottlenecks (usually AI inference)
3. Consider:
   - Reducing frame rate
   - Using GPU acceleration
   - Downsampling input
   - Caching results

## Dependencies

### Adding New Package

1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. Check for platform-specific setup (Android/iOS)
4. Update README if needed

### Updating Packages

```bash
flutter pub upgrade
flutter pub outdated
```

## Platform-Specific Notes

### Android

- Min SDK: 21 (Android 5.0)
- Target SDK: 33+ (Android 13+)
- Permissions: Camera, Location, Microphone, Storage
- ProGuard rules for TFLite

### iOS

- Min iOS: 13.0
- Permissions: Camera, Location, Microphone
- Info.plist configuration required

## Known Issues & TODOs

See `ARCHITECTURE.md` for detailed roadmap.

### High Priority

- [ ] Multi-object tracking (SORT algorithm)
- [ ] TTC calculation based on object size/velocity
- [ ] IMU integration for sudden braking detection
- [ ] GPS integration for speed/position tracking
- [ ] Mapbox navigation integration

### Medium Priority

- [ ] SQLite database for incidents
- [ ] Trip recording and persistence
- [ ] Performance optimization (battery, FPS)
- [ ] Lane detection model

### Low Priority

- [ ] Cloud sync (optional)
- [ ] Emergency services integration
- [ ] Voice commands
- [ ] Microphone audio detection (sirens, horns)

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)
- [Riverpod Documentation](https://riverpod.dev/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)

## Contact

For questions about the codebase, architecture, or roadmap:
- GitHub Issues: https://github.com/julblaszczuk/Alicja-RoadSense/issues
- Email: support@alicja-roadsense.com

---

**Remember**: This is a safety-critical application. Always prioritize reliability and accuracy over features.
